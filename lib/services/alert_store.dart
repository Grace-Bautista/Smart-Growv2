import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// How important an alert is. Used by the UI to color/prioritize entries
/// and by SensorMonitorService to decide whether it also deserves an OS
/// notification.
enum AlertSeverity { info, warning, critical }

/// Persists in-app alerts (the dashboard bell / Notifications screen) so
/// they survive an app restart. SensorMonitorService writes to this
/// whenever it detects something worth telling the user about; the
/// Notifications screen just reads from it.
class AlertStore {
  AlertStore._();

  static const String boxName = 'alertBox';
  static const int maxEntries = 500;

  static Box? _box;

  /// Unread count for the dashboard bell badge.
  static final ValueNotifier<int> unreadCount = ValueNotifier(0);

  /// Bumped on every add/markRead/remove so the Notifications screen can
  /// rebuild its list.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<void> init() async {
    _box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName);
    _recount();
  }

  static Future<void> add({
    required String title,
    required String subtitle,
    required String iconKey,
    required int colorValue,
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
      'read': false,
    });

    if (box.length > maxEntries) {
      final overflow = box.length - maxEntries;
      await box.deleteAll(box.keys.take(overflow).toList());
    }

    _recount();
    revision.value++;
  }

  /// Alerts newest-first, each tagged with its Hive key under `_key` so
  /// the UI can mark-read/delete the exact record it's showing.
  static List<Map<String, dynamic>> all() {
    final box = _box;
    if (box == null) return [];

    final entries = box.toMap().entries.toList()
      ..sort(
        (a, b) => (b.value['timestamp'] as String).compareTo(
          a.value['timestamp'] as String,
        ),
      );

    return entries
        .map(
          (e) => {...Map<String, dynamic>.from(e.value as Map), '_key': e.key},
        )
        .toList();
  }

  static Future<void> markRead(dynamic key) async {
    final box = _box;
    if (box == null) return;
    final raw = box.get(key);
    if (raw == null) return;

    final map = Map<String, dynamic>.from(raw as Map);
    map['read'] = true;
    await box.put(key, map);

    _recount();
    revision.value++;
  }

  static Future<void> remove(dynamic key) async {
    final box = _box;
    if (box == null) return;
    await box.delete(key);

    _recount();
    revision.value++;
  }

  static void _recount() {
    final box = _box;
    if (box == null) {
      unreadCount.value = 0;
      return;
    }
    unreadCount.value = box.values
        .where((v) => (v as Map)['read'] != true)
        .length;
  }

  /// Buckets already-sorted (newest first) alerts into Today / Yesterday /
  /// Earlier for the Notifications screen's section headers.
  static Map<String, List<Map<String, dynamic>>> groupByDay(
    List<Map<String, dynamic>> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<Map<String, dynamic>>>{
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final item in items) {
      final ts = DateTime.parse(item['timestamp'] as String);
      final day = DateTime(ts.year, ts.month, ts.day);

      if (day == today) {
        grouped['Today']!.add(item);
      } else if (day == yesterday) {
        grouped['Yesterday']!.add(item);
      } else {
        grouped['Earlier']!.add(item);
      }
    }

    return grouped;
  }
}
