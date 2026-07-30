import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'esp32_service.dart';

/// Persists every sensor reading the app pulls from the ESP32, so the
/// Logbook screens (Today's Log / Summary) show real history instead of
/// hardcoded sample data.
///
/// Uses the same lightweight "raw Hive box of maps" pattern already used
/// for the harvest log (see harvestlogs_screen.dart) — no type adapters
/// needed.
class GrowLogStore {
  GrowLogStore._();

  static const String boxName = 'growLogBox';

  /// Caps how much history is kept on-device so the box doesn't grow
  /// forever on a phone that's left running for months.
  static const int maxEntries = 8000;

  /// How often SensorMonitorService polls the ESP32. Used only to
  /// *estimate* on-time totals for the summary card (readings-with-flag
  /// true x interval) — it's an approximation from sampling, not a
  /// precise timer, and is called out as such in the UI.
  static const Duration pollInterval = Duration(seconds: 10);

  static Box? _box;

  /// Bumped every time a new reading is stored, so screens can listen and
  /// rebuild without wiring up a full stream.
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<void> init() async {
    _box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName);
  }

  static Future<void> addReading(Esp32Snapshot snapshot) async {
    final box = _box;
    if (box == null) return;

    await box.add({
      'timestamp': DateTime.now().toIso8601String(),
      'connected': snapshot.connected,
      'sensorOnline': snapshot.sensorOnline,
      'temperature': snapshot.temperature,
      'humidity': snapshot.humidity,
      'co2': snapshot.co2,
      'fanOn': snapshot.fanOn,
      'pumpOn': snapshot.pumpOn,
      'uvOn': snapshot.uvOn,
      'waterPresent': snapshot.waterPresent,
    });

    if (box.length > maxEntries) {
      final overflow = box.length - maxEntries;
      await box.deleteAll(box.keys.take(overflow).toList());
    }

    revision.value++;
  }

  static List<Map<String, dynamic>> _all() {
    final box = _box;
    if (box == null) return [];
    final list = box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    list.sort(
      (a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String),
    );
    return list;
  }

  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<Map<String, dynamic>> readingsForDate(DateTime date) {
    return _all()
        .where((r) => _isSameDate(DateTime.parse(r['timestamp'] as String), date))
        .toList();
  }

  static Map<String, dynamic>? latestReading() {
    final all = _all();
    return all.isEmpty ? null : all.last;
  }

  /// Real, computed replacement for the old hardcoded "System Summary"
  /// card on Today's Log.
  static Map<String, dynamic> summaryForDate(DateTime date) {
    final readings = readingsForDate(date);
    final intervalMinutes = pollInterval.inSeconds / 60;

    int countWhere(bool Function(Map<String, dynamic>) test) =>
        readings.where(test).length;

    return {
      'totalReadings': readings.length,
      'humidifierOnMinutes':
          (countWhere((r) => r['pumpOn'] == true) * intervalMinutes).round(),
      'fanOnMinutes':
          (countWhere((r) => r['fanOn'] == true) * intervalMinutes).round(),
      'sensorOfflineCount': countWhere((r) => r['sensorOnline'] == false),
      'deviceOfflineCount': countWhere((r) => r['connected'] == false),
    };
  }

  /// Per-day average temp/humidity/co2 for the last [days] days (today
  /// inclusive, oldest first). A day with no readings yet comes back with
  /// null averages rather than being dropped, so a chart can show a gap
  /// instead of silently lying with a flat line.
  static List<Map<String, dynamic>> dailyAverages(int days) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    double? avg(Iterable<num?> values) {
      final nums = values.whereType<num>().toList();
      if (nums.isEmpty) return null;
      return nums.reduce((a, b) => a + b) / nums.length;
    }

    for (var i = days - 1; i >= 0; i--) {
      final day =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final readings = readingsForDate(day);

      result.add({
        'date': day,
        'temperature': avg(readings.map((r) => r['temperature'] as num?)),
        'humidity': avg(readings.map((r) => r['humidity'] as num?)),
        'co2': avg(readings.map((r) => r['co2'] as num?)),
      });
    }

    return result;
  }
}
