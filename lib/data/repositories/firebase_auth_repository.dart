import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final doc = await _users.doc(user.uid).get();
      if (!doc.exists) {
        final appUser = AppUser(
          id: user.uid,
          displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
        await _users.doc(user.uid).set(appUser.toFirestore());
        return appUser;
      }
      return AppUser.fromFirestore(doc);
    });
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    final appUser = AppUser(
      id: user.uid,
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );
    await _users.doc(user.uid).set(appUser.toFirestore());
    return appUser;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final doc = await _users.doc(credential.user!.uid).get();
    if (!doc.exists) {
      final appUser = AppUser(
        id: credential.user!.uid,
        displayName: credential.user!.displayName ?? 'User',
        email: email,
        createdAt: DateTime.now(),
      );
      await _users.doc(appUser.id).set(appUser.toFirestore());
      return appUser;
    }
    return AppUser.fromFirestore(doc);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;
    final doc = await _users.doc(user.uid).get();
    if (!doc.exists) {
      final appUser = AppUser(
        id: user.uid,
        displayName: user.displayName ?? 'User',
        email: user.email ?? '',
        createdAt: DateTime.now(),
      );
      await _users.doc(user.uid).set(appUser.toFirestore());
      return appUser;
    }
    return AppUser.fromFirestore(doc);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  @override
  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> updateFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _users.doc(user.uid).update({'fcmToken': token});
  }
}
