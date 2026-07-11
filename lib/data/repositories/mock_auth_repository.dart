import 'dart:async';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  MockAuthRepository() {
    _controller.add(null);
  }

  @override
  Stream<AppUser?> watchCurrentUser() => _controller.stream;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _currentUser = AppUser(
      id: 'mock-user-1',
      displayName: displayName,
      email: email,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    _currentUser = AppUser(
      id: 'mock-user-1',
      displayName: email.split('@').first,
      email: email,
      createdAt: DateTime.now(),
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signInWithGoogle() {
    return signIn(email: 'demo@gmail.com', password: '');
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<void> resetPassword(String email) async {}

  @override
  Future<void> updateFcmToken(String token) async {}
}
