import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';

abstract class LogBookRepository {
  Future<List<SensorHistoryRecord>> getSensorHistory({
    required DateTime start,
    required DateTime end,
  });

  Future<List<SystemEventLog>> getSystemEvents({
    required DateTime start,
    required DateTime end,
  });
}
