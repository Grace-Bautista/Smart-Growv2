import 'package:cloud_firestore/cloud_firestore.dart';

class HarvestRecord {
  final String id;
  final String name;
  final DateTime date;
  final double grams;
  final double price;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HarvestRecord({
    required this.id,
    required this.name,
    required this.date,
    required this.grams,
    required this.price,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory HarvestRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};

    return HarvestRecord(
      id: doc.id,
      name: data['name'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grams: (data['grams'] as num?)?.toDouble() ?? 0,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}