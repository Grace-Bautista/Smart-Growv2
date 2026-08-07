import 'dart:math';
import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';
import 'logbook_repository.dart';

class MockLogBookRepository implements LogBookRepository {
  MockLogBookRepository({DateTime? now}) : _now = now ?? DateTime.now() {
    _sensors = _buildSensors(_now);
    _events = _buildEvents(_now);
  }
  final DateTime _now;
  late final List<SensorHistoryRecord> _sensors;
  late final List<SystemEventLog> _events;
  static String sensorId(DateTime time) =>
      'mock_sensor_${time.toUtc().millisecondsSinceEpoch ~/ 300000}';
  Iterable<T> _range<T>(
    Iterable<T> source,
    DateTime Function(T) time,
    DateTime start,
    DateTime end,
  ) => source.where(
    (x) =>
        !time(x).isBefore(start) && time(x).isBefore(exclusiveHistoryEnd(end)),
  );
  @override
  Future<List<SensorHistoryRecord>> getSensorHistory({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
  }) async =>
      _range(_sensors, (x) => x.timestamp, start, end).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  @override
  Future<List<SystemEventLog>> getSystemEvents({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
    String? category,
  }) async =>
      (_range(
          _events,
          (x) => x.timestamp,
          start,
          end,
        ).where((x) => category == null || x.category == category).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  @override
  Stream<List<SensorHistoryRecord>> watchSensorHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async* {
    yield await getSensorHistory(
      deviceId: deviceId,
      start: startDate,
      end: endDate,
    );
  }

  @override
  Stream<List<SystemEventLog>> watchSystemEvents({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  }) async* {
    yield await getSystemEvents(
      deviceId: deviceId,
      start: startDate,
      end: endDate,
      category: category,
    );
  }

  static List<SensorHistoryRecord> _buildSensors(DateTime now) {
    final start = now.subtract(const Duration(days: 31));
    return List.generate(32 * 24 * 2, (i) {
      final t = start.add(Duration(minutes: i * 30));
      final wave = sin(i / 12);
      return SensorHistoryRecord(
        id: sensorId(t),
        deviceId: 'smartGrow01',
        timestamp: t,
        environmentTemp: 25.5 + wave * 1.8,
        humidity: 79 - wave * 5,
        co2: 510 + wave * 55,
        waterLevel: max(20, 95 - (i % 180) * .4),
        humidifierTemp: 23.5 + wave,
        validity: const {
          'environmentTemp': true,
          'humidity': true,
          'co2': true,
          'waterLevel': true,
          'humidifierTemp': true,
        },
        bootId: 'mock-boot',
        isMock: true,
        seedBatchId: 'history-demo-v1',
      );
    });
  }

  static List<SystemEventLog> _buildEvents(DateTime now) => [
    SystemEventLog(
      id: 'mock_mode',
      deviceId: 'smartGrow01',
      timestamp: now.subtract(const Duration(days: 2)),
      eventType: SystemEventType.modeChanged,
      category: 'component',
      component: 'refillPump.mode',
      previousValue: 'off',
      newValue: 'auto',
      source: 'manual_command',
      message: 'Refill pump mode changed to auto',
      isMock: true,
    ),
    SystemEventLog(
      id: 'mock_refill_on',
      deviceId: 'smartGrow01',
      timestamp: now.subtract(const Duration(hours: 8)),
      eventType: SystemEventType.refillStarted,
      category: 'component',
      component: 'refillPump.running',
      previousValue: false,
      newValue: true,
      source: 'automatic_refill',
      message: 'Automatic refill started',
      isMock: true,
    ),
    SystemEventLog(
      id: 'mock_refill_off',
      deviceId: 'smartGrow01',
      timestamp: now.subtract(const Duration(hours: 7, minutes: 55)),
      eventType: SystemEventType.refillStopped,
      category: 'component',
      component: 'refillPump.running',
      previousValue: true,
      newValue: false,
      source: 'automatic_refill',
      message: 'Automatic refill stopped',
      isMock: true,
    ),
  ];
}
