import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';
import 'logbook_repository.dart';

class FirestoreLogBookRepository implements LogBookRepository {
  FirestoreLogBookRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _firestore;

  Query<Map<String, dynamic>> _query(
    String deviceId,
    String collection,
    DateTime start,
    DateTime end, {
    String? category,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('devices')
        .doc(deviceId)
        .collection(collection)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where(
          'timestamp',
          isLessThan: Timestamp.fromDate(exclusiveHistoryEnd(end)),
        );
    if (category != null) query = query.where('category', isEqualTo: category);
    return query.orderBy('timestamp', descending: true);
  }

  @override
  Stream<List<SensorHistoryRecord>> watchSensorHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) => _query(deviceId, 'sensorHistory', startDate, endDate).snapshots().map(
    (snapshot) => snapshot.docs
        .map(SensorHistoryRecord.fromFirestore)
        .toList(growable: false),
  );
  @override
  Stream<List<SystemEventLog>> watchSystemEvents({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
  }) => _query(deviceId, 'systemEvents', startDate, endDate, category: category)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(SystemEventLog.fromFirestore)
            .toList(growable: false),
      );
  @override
  Future<List<SensorHistoryRecord>> getSensorHistory({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
  }) async => (await _query(
    deviceId,
    'sensorHistory',
    start,
    end,
  ).get()).docs.map(SensorHistoryRecord.fromFirestore).toList(growable: false);
  @override
  Future<List<SystemEventLog>> getSystemEvents({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
    String? category,
  }) async => (await _query(
    deviceId,
    'systemEvents',
    start,
    end,
    category: category,
  ).get()).docs.map(SystemEventLog.fromFirestore).toList(growable: false);
}
