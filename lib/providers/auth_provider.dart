import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider สำหรับ Firebase Auth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Provider สำหรับ Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Provider สำหรับ User Stream
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// Provider สำหรับ User Data
final userDataProvider = StreamProvider.family<DocumentSnapshot?, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return Stream.value(null);

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(userId)
      .snapshots();
});

// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  }) : _auth = auth,
       _firestore = firestore;

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    return await _firestore.collection("users").doc(uid).get();
  }

  Future<void> logoutAndLoginNewAccount() async {
    await _auth.signOut();
    await Future.delayed(Duration(seconds: 1));
  }
}
