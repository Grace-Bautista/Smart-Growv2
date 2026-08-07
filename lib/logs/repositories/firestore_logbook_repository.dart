import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/sensor_history_record.dart';
import '../models/system_event_log.dart';
import 'logbook_repository.dart';

class HistoryDataException implements Exception {
  const HistoryDataException(this.message, {this.cause, this.stackTrace});
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
  @override
  String toString() => message;
}

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
        .where('timestamp', isLessThan: Timestamp.fromDate(exclusiveHistoryEnd(end)));
    if (category != null) query = query.where('category', isEqualTo: category);
    return query.orderBy('timestamp', descending: true);
  }

  Future<List<T>> _get<T>(
    Query<Map<String, dynamic>> query,
    String collection,
    T Function(Map<String, dynamic> data, String id) parse,
  ) async {
    try {
      final snapshot = await query.get();
      return parseHistoryDocuments<T>(
        collection: collection,
        documents: snapshot.docs
            .map((doc) => (id: doc.id, data: doc.data()))
            .toList(growable: false),
        parse: parse,
      );
    } on HistoryDataException {
      rethrow;
    } on FirebaseException catch (error, stackTrace) {
      throw HistoryDataException(
        'Firestore query failed for $collection (${error.code}).',
        cause: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw HistoryDataException(
        'Firestore query failed for $collection.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<List<SensorHistoryRecord>> watchSensorHistory({
    required String deviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) => _query(deviceId, 'sensorHistory', startDate, endDate).snapshots().map(
        (snapshot) => parseHistoryDocuments<SensorHistoryRecord>(
          collection: 'sensorHistory',
          documents: snapshot.docs
              .map((doc) => (id: doc.id, data: doc.data()))
              .toList(growable: false),
          parse: (data, id) => SensorHistoryRecord.fromMap(data, id: id),
        ),
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
        (snapshot) => parseHistoryDocuments<SystemEventLog>(
          collection: 'systemEvents',
          documents: snapshot.docs
              .map((doc) => (id: doc.id, data: doc.data()))
              .toList(growable: false),
          parse: (data, id) => SystemEventLog.fromMap(data, id: id),
        ),
      );

  @override
  Future<List<SensorHistoryRecord>> getSensorHistory({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
  }) => _get(
        _query(deviceId, 'sensorHistory', start, end),
        'sensorHistory',
        (data, id) => SensorHistoryRecord.fromMap(data, id: id),
      );

  @override
  Future<List<SystemEventLog>> getSystemEvents({
    String deviceId = 'smartGrow01',
    required DateTime start,
    required DateTime end,
    String? category,
  }) => _get(
        _query(deviceId, 'systemEvents', start, end, category: category),
        'systemEvents',
        (data, id) => SystemEventLog.fromMap(data, id: id),
      );
}

/// Parses each Firestore document independently so a legacy bad record does
/// not hide valid history. This is public to enable focused non-Firebase tests.
List<T> parseHistoryDocuments<T>({
  required String collection,
  required Iterable<({String id, Map<String, dynamic> data})> documents,
  required T Function(Map<String, dynamic> data, String id) parse,
}) {
  final records = <T>[];
  var failed = 0;
  for (final document in documents) {
    try {
      records.add(parse(document.data, document.id));
    } catch (error, stackTrace) {
      failed++;
      if (kDebugMode) {
        debugPrint('Malformed $collection document ${document.id}: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }
  if (failed > 0 && records.isEmpty) {
    throw HistoryDataException(
      'Malformed $collection records: $failed document(s) could not be read.',
    );
  }
  return records;
}
