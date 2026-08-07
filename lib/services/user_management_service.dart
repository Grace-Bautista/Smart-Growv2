import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_grow_code/auth/app_user.dart';

class UserManagementService {
  UserManagementService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Stream<List<AppUser>> watchUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  static Future<void> createStaff({
    required String name,
    required String email,
    required String password,
  }) {
    return _call('createStaffUser', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  static Future<void> updateStaff({
    required String uid,
    required String name,
    required String email,
  }) {
    return _call('updateStaffUser', {
      'uid': uid,
      'name': name.trim(),
      'email': email.trim(),
    });
  }

  static Future<void> deactivateUser(String uid) {
    return _call('deactivateUser', {'uid': uid});
  }

  static Future<void> reactivateUser(String uid) {
    return _call('reactivateUser', {'uid': uid});
  }

  static Future<void> deleteUser(String uid) {
    return _call('deleteUser', {'uid': uid});
  }

  static Future<void> resetStaffPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> resetCurrentUserPassword() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('You need to log in first.');
    }

    if (user.email == null) {
      throw Exception('This account does not have an email.');
    }

    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
  }

  static Future<void> _call(String name, Map<String, dynamic> data) async {
    await _functions.httpsCallable(name).call(data);
  }
}
