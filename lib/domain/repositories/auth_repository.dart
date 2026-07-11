import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> watchCurrentUser();
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AppUser> signIn({
    required String email,
    required String password,
  });
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInWithApple();
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<void> updateFcmToken(String token);
}
