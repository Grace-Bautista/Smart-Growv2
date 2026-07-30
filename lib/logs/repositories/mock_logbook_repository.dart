import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';
import 'logbook_repository.dart';

/// Temporary data source. Replace this class with FirebaseLogBookRepository
/// later; the UI only depends on [LogBookRepository].
class MockLogBookRepository implements LogBookRepository {
  MockLogBookRepository() : _sensorRecords = _buildSensorRecords();

  final List<SensorHistoryRecord> _sensorRecords;

  @override
  Future<List<SensorHistoryRecord>> getSensorHistory({
    required DateTime start,
    required DateTime end,
  }) async => _sensorRecords
      .where((record) => !record.timestamp.isBefore(start) && !record.timestamp.isAfter(end))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  @override
  Future<List<SystemEventLog>> getSystemEvents({
    required DateTime start,
    required DateTime end,
  }) async => _events
      .where((event) => !event.timestamp.isBefore(start) && !event.timestamp.isAfter(end))
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  static List<SensorHistoryRecord> _buildSensorRecords() {
    final records = <SensorHistoryRecord>[];
    for (var day = 26; day <= 28; day++) {
      final base = DateTime(2026, 7, day, 7);
      // 7:00 AM through 10:50 AM: a realistic 5-minute history window.
      for (var index = 0; index < 47; index++) {
        final time = base.add(Duration(minutes: index * 5));
        final wave = (index % 12) - 6;
        records.add(SensorHistoryRecord(
          id: 'sensor-$day-$index', timestamp: time,
          temperature: 27.2 + (wave * .12) + ((day - 27) * .18),
          humidity: 78 + (wave * .7) - ((day - 27) * .4),
          co2: 420 + (wave * 4) + ((day - 27) * 6),
        ));
      }
    }
    return records;
  }

  static final List<SystemEventLog> _events = [
    SystemEventLog(id: 'e1', timestamp: DateTime(2026, 7, 28, 10, 45), eventType: SystemEventType.humidifierOn, description: 'Humidifier turned ON', trigger: 'Humidity below setpoint', expectedState: 'ON', actualState: 'ON', latencySeconds: 2),
    SystemEventLog(id: 'e2', timestamp: DateTime(2026, 7, 28, 9, 30), eventType: SystemEventType.fanOn, description: 'Fan turned ON', trigger: 'Temperature above comfort range', expectedState: 'ON', actualState: 'ON', latencySeconds: 1),
    SystemEventLog(id: 'e3', timestamp: DateTime(2026, 7, 28, 8, 15), eventType: SystemEventType.communicationError, description: 'Sensor packet received late', trigger: 'Communication timeout', expectedState: 'Packet within 2 sec', actualState: 'Packet after 8 sec', packetCommunicationError: true, delaySeconds: 6, errorCode: 'COM-408'),
    SystemEventLog(id: 'e4', timestamp: DateTime(2026, 7, 27, 11, 20), eventType: SystemEventType.humidifierOff, description: 'Humidifier turned OFF', trigger: 'RH reached setpoint', expectedState: 'OFF', actualState: 'OFF', latencySeconds: 2, recoveryTimeMinutes: 5),
    SystemEventLog(id: 'e5', timestamp: DateTime(2026, 7, 27, 9, 0), eventType: SystemEventType.refillEvent, description: 'Water reservoir refilled', trigger: 'Manual refill confirmation', expectedState: 'Water level restored', actualState: 'Water level restored'),
    SystemEventLog(id: 'e6', timestamp: DateTime(2026, 7, 26, 10, 10), eventType: SystemEventType.rhTriggerDetected, description: 'RH trigger detected', trigger: 'RH at 69%', expectedState: 'Humidifier activation', actualState: 'Activation queued', latencySeconds: 3),
    SystemEventLog(id: 'e7', timestamp: DateTime(2026, 7, 26, 7, 45), eventType: SystemEventType.fanOff, description: 'Fan turned OFF', trigger: 'Temperature normalized', expectedState: 'OFF', actualState: 'OFF', latencySeconds: 1),
  ];
}
