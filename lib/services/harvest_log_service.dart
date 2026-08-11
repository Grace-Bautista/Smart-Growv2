import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HarvestLogService {
  HarvestLogService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _deviceId = 'smartGrow01';

  CollectionReference<Map<String, dynamic>> get _harvestRef {
    return _firestore
        .collection('devices')
        .doc(_deviceId)
        .collection('harvestLogs');
  }

  // ------------------------------------------------------------
  // READ - REAL TIME
  // ------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> watchHarvestLogs() {
    return _harvestRef.orderBy('date', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        final rawDate = data['date'];

        String date = '';

        if (rawDate is Timestamp) {
          date = _dateOnly(rawDate.toDate());
        } else if (rawDate != null) {
          date = rawDate.toString();
        }

        return {...data, '_id': doc.id, 'date': date};
      }).toList();
    });
  }

  // ------------------------------------------------------------
  // ADD
  // ------------------------------------------------------------

  Future<void> addHarvest(Map<String, dynamic> record) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final date = DateTime.tryParse(record['date']?.toString() ?? '');

    if (date == null) {
      throw Exception('Invalid harvest date.');
    }

    await _harvestRef.add({
      'name': record['name']?.toString().trim() ?? '',
      'date': Timestamp.fromDate(date),
      'grams': _number(record['grams']),
      'price': _number(record['price']),
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------

  Future<void> updateHarvest({
    required String id,
    required Map<String, dynamic> record,
  }) async {
    final date = DateTime.tryParse(record['date']?.toString() ?? '');

    if (date == null) {
      throw Exception('Invalid harvest date.');
    }

    await _harvestRef.doc(id).update({
      'name': record['name']?.toString().trim() ?? '',
      'date': Timestamp.fromDate(date),
      'grams': _number(record['grams']),
      'price': _number(record['price']),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<void> deleteHarvest(String id) async {
    await _harvestRef.doc(id).delete();
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  static double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _dateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
