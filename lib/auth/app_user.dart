import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String status;
  final String createdBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff';
  bool get isActive => status == 'active';

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppUser(
      uid: (data['uid'] ?? doc.id).toString(),
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      role: (data['role'] ?? 'staff').toString(),
      status: (data['status'] ?? 'inactive').toString(),
      createdBy: (data['createdBy'] ?? '').toString(),
      createdAt: data['createdAt'] is Timestamp ? data['createdAt'] : null,
      updatedAt: data['updatedAt'] is Timestamp ? data['updatedAt'] : null,
    );
  }
}
