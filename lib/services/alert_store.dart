import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// How important an alert is.
///
/// Used by the UI for styling/prioritization and by the notification
/// monitor to determine whether an alert should also trigger an
/// Android local notification.
enum AlertSeverity { info, warning, critical }

/// Stores Smart-Grow alerts locally using Hive.
///
/// Responsibilities:
/// - Persist alerts shown in the Notifications screen.
/// - Track unread count.
/// - Allow alerts to be marked as read/deleted.
/// - Provide the last timestamp for a particular condition so the
///   notification monitor can prevent notification spam.
///
/// Sensor threshold detection itself should remain outside this class.
class AlertStore {
  AlertStore._();

  static const String boxName = 'alertBox';
  static const int maxEntries = 500;

  static Box<dynamic>? _box;

  /// Unread notification count shown on the dashboard bell.
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Incremented whenever alert data changes.
  ///
  /// The Notifications screen can listen to this value and rebuild.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Opens the Hive alert box.
  static Future<void> init() async {
    _box = Hive.isBoxOpen(boxName)
        ? Hive.box<dynamic>(boxName)
        : await Hive.openBox<dynamic>(boxName);

    _recount();
  }

  /// Adds a new alert.
  ///
  /// [conditionKey] identifies the source condition, for example:
  /// - humidity_low
  /// - humidity_high
  /// - temperature_low
  /// - device_offline
  ///
  /// This allows SensorMonitorService to apply duplicate/cooldown
  /// protection without mixing sensor logic into AlertStore.
  static Future<void> add({
    required String title,
    required String subtitle,
    required String iconKey,
    required int colorValue,
    required String conditionKey,
    AlertSeverity severity = AlertSeverity.info,
  }) async {
    final box = _box;
    if (box == null) return;

    await box.add({
      'timestamp': DateTime.now().toIso8601String(),
      'title': title,
      'subtitle': subtitle,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'severity': severity.name,
      'conditionKey': conditionKey,
      'read': false,
    });

    // Prevent the alert box from growing indefinitely.
    if (box.length > maxEntries) {
      final overflow = box.length - maxEntries;

      final oldestKeys = box.keys.take(overflow).toList();

      await box.deleteAll(oldestKeys);
    }

    _notifyChanged();
  }

  /// Returns all alerts newest-first.
  ///
  /// `_key` contains the actual Hive key so the UI can safely
  /// edit/delete the exact record being displayed.
  static List<Map<String, dynamic>> all() {
    final box = _box;
    if (box == null) return [];

    final entries = box.toMap().entries.where((entry) {
      return entry.value is Map;
    }).toList();

    entries.sort((a, b) {
      final aMap = Map<String, dynamic>.from(a.value as Map);
      final bMap = Map<String, dynamic>.from(b.value as Map);

      final aTimestamp = aMap['timestamp']?.toString() ?? '';
      final bTimestamp = bMap['timestamp']?.toString() ?? '';

      return bTimestamp.compareTo(aTimestamp);
    });

    return entries.map((entry) {
      final map = Map<String, dynamic>.from(entry.value as Map);

      return {...map, '_key': entry.key};
    }).toList();
  }

  /// Returns the time the given condition most recently generated an alert.
  ///
  /// This will be useful for persistent cooldown protection in
  /// SensorMonitorService.
  static DateTime? lastTimestampFor(String conditionKey) {
    final box = _box;
    if (box == null) return null;

    DateTime? latest;

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = Map<String, dynamic>.from(raw);

      if (map['conditionKey'] != conditionKey) {
        continue;
      }

      final timestampRaw = map['timestamp'];

      if (timestampRaw == null) {
        continue;
      }

      final timestamp = DateTime.tryParse(timestampRaw.toString());

      if (timestamp == null) {
        continue;
      }

      if (latest == null || timestamp.isAfter(latest)) {
        latest = timestamp;
      }
    }

    return latest;
  }

  /// Marks a single alert as read.
  static Future<void> markRead(dynamic key) async {
    final box = _box;
    if (box == null) return;

    final raw = box.get(key);

    if (raw is! Map) return;

    final map = Map<String, dynamic>.from(raw);

    // Don't rewrite the same record unnecessarily.
    if (map['read'] == true) return;

    map['read'] = true;

    await box.put(key, map);

    _notifyChanged();
  }

  /// Marks every stored alert as read.
  static Future<void> markAllRead() async {
    final box = _box;
    if (box == null || box.isEmpty) return;

    for (final key in box.keys.toList()) {
      final raw = box.get(key);

      if (raw is! Map) continue;

      final map = Map<String, dynamic>.from(raw);

      if (map['read'] == true) continue;

      map['read'] = true;

      await box.put(key, map);
    }

    _notifyChanged();
  }

  /// Deletes one alert.
  static Future<void> remove(dynamic key) async {
    final box = _box;
    if (box == null) return;

    await box.delete(key);

    _notifyChanged();
  }

  /// Deletes every stored alert.
  static Future<void> clearAll() async {
    final box = _box;
    if (box == null || box.isEmpty) return;

    await box.clear();

    _notifyChanged();
  }

  /// Recalculates the dashboard unread badge.
  static void _recount() {
    final box = _box;

    if (box == null) {
      unreadCount.value = 0;
      return;
    }

    int count = 0;

    for (final raw in box.values) {
      if (raw is! Map) continue;

      if (raw['read'] != true) {
        count++;
      }
    }

    unreadCount.value = count;
  }

  /// Notify both the dashboard badge and Notifications screen.
  static void _notifyChanged() {
    _recount();
    revision.value++;
  }

  /// Groups alerts into:
  ///
  /// Today
  /// Yesterday
  /// Earlier
  static Map<String, List<Map<String, dynamic>>> groupByDay(
    List<Map<String, dynamic>> items,
  ) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in items) {
      final rawTimestamp = item['timestamp'];

      if (rawTimestamp == null) {
        grouped.putIfAbsent('Undated', () => []).add(item);
        continue;
      }

      final timestamp = DateTime.tryParse(rawTimestamp.toString());

      if (timestamp == null) {
        grouped.putIfAbsent('Undated', () => []).add(item);
        continue;
      }

      final day = DateTime(timestamp.year, timestamp.month, timestamp.day);

      if (day == today) {
        grouped.putIfAbsent('Today', () => []).add(item);
      } else if (day == yesterday) {
        grouped.putIfAbsent('Yesterday', () => []).add(item);
      } else {
        // Use an ISO date as the group key.
        // This makes the groups easy to sort chronologically.
        final dateKey =
            '${day.year.toString().padLeft(4, '0')}-'
            '${day.month.toString().padLeft(2, '0')}-'
            '${day.day.toString().padLeft(2, '0')}';

        grouped.putIfAbsent(dateKey, () => []).add(item);
      }
    }

    return grouped;
  }
}
