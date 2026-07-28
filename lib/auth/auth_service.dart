import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_grow_code/auth/app_user.dart';

class AuthStatusException implements Exception {
  const AuthStatusException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _loadAndValidateProfile(user.uid, signOutOnInvalid: true);
    });
  }

  static Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw const AuthStatusException('Unable to complete login.');
    }

    return _loadAndValidateProfile(user.uid, signOutOnInvalid: true);
  }

  static Future<AppUser> currentAppUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthStatusException('You need to log in first.');
    }
    return _loadAndValidateProfile(user.uid, signOutOnInvalid: false);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPublicPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  static Future<AppUser> _loadAndValidateProfile(
    String uid, {
    required bool signOutOnInvalid,
  }) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      if (signOutOnInvalid) await _auth.signOut();
      throw const AuthStatusException(
        'No user profile was found for this account.',
      );
    }

    final appUser = AppUser.fromFirestore(doc);
    if (!appUser.isActive) {
      if (signOutOnInvalid) await _auth.signOut();
      throw const AuthStatusException(
        'This account has been deactivated. Please contact an administrator.',
      );
    }

    return appUser;
  }
}
