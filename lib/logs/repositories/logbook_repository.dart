import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';

abstract class LogBookRepository {
  Stream<List<SensorHistoryRecord>> watchSensorHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  });
  Stream<List<SystemEventLog>> watchSystemEvents({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  });
  Future<List<SensorHistoryRecord>> getSensorHistory({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
  });
  Future<List<SystemEventLog>> getSystemEvents({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
    String? category,
  });
}

DateTime exclusiveHistoryEnd(DateTime selectedEnd) => DateTime(
  selectedEnd.year,
  selectedEnd.month,
  selectedEnd.day,
).add(const Duration(days: 1));
