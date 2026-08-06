import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_grow_code/logs/models/sensor_history_record.dart';
import 'package:smart_grow_code/logs/models/system_event_log.dart';
import 'package:smart_grow_code/logs/repositories/logbook_repository.dart';
import 'package:smart_grow_code/logs/repositories/mock_logbook_repository.dart';

void main() {
  final time = DateTime.utc(2026, 8, 5, 12);
  test('sensor history parses Timestamp and validity', () {
    final r = SensorHistoryRecord.fromMap({
      'deviceId': 'smartGrow01',
      'timestamp': Timestamp.fromDate(time),
      'environmentTemp': 25,
      'humidity': 80,
      'co2': 500,
      'waterLevel': 90,
      'humidifierTemp': 23,
      'validity': {'co2': true},
    });
    expect(r.timestamp, time);
    expect(r.temperature, 25);
    expect(r.validity['co2'], isTrue);
  });
  test(
    'missing required timestamp is rejected',
    () => expect(
      () => SensorHistoryRecord.fromMap({'deviceId': 'smartGrow01'}),
      throwsFormatException,
    ),
  );
  test('event preserves boolean and string transition values', () {
    final mode = SystemEventLog.fromMap({
      'deviceId': 'smartGrow01',
      'timestamp': time.millisecondsSinceEpoch,
      'category': 'component',
      'eventType': 'mode_changed',
      'message': 'mode',
      'previousValue': 'off',
      'newValue': 'auto',
    });
    final running = SystemEventLog.fromMap({
      'deviceId': 'smartGrow01',
      'timestamp': time,
      'category': 'component',
      'eventType': 'refill_started',
      'message': 'run',
      'previousValue': false,
      'newValue': true,
      'unexpected': {},
    });
    expect(mode.eventType, SystemEventType.modeChanged);
    expect(mode.newValue, 'auto');
    expect(running.eventType, SystemEventType.refillStarted);
    expect(running.newValue, true);
  });
  test('malformed optional values are ignored', () {
    final e = SystemEventLog.fromMap({
      'deviceId': 'smartGrow01',
      'timestamp': time,
      'category': 'device',
      'eventType': 'device_online',
      'message': 'online',
      'previousValue': {},
    });
    expect(e.previousValue, isNull);
  });
  test(
    'selected end becomes exclusive next midnight',
    () => expect(
      exclusiveHistoryEnd(DateTime(2026, 8, 5, 3)),
      DateTime(2026, 8, 6),
    ),
  );
  test(
    'mock ids are deterministic',
    () => expect(
      MockLogBookRepository.sensorId(time),
      MockLogBookRepository.sensorId(time.add(const Duration(minutes: 4))),
    ),
  );
  test('empty history range remains empty', () async {
    final repo = MockLogBookRepository(now: time);
    expect(
      await repo.getSensorHistory(start: DateTime(2000), end: DateTime(2000)),
      isEmpty,
    );
  });
}
