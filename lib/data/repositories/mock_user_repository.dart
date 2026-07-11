import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository() {
    _seedUsers();
  }

  final List<AppUser> _users = [];

  void _seedUsers() {
    final now = DateTime.now();
    _users.addAll([
      AppUser(
        id: 'mock-user-2',
        displayName: 'Sam',
        email: 'sam@test.com',
        createdAt: now,
      ),
      AppUser(
        id: 'mock-user-3',
        displayName: 'Jordan',
        email: 'jordan@test.com',
        createdAt: now,
      ),
      AppUser(
        id: 'mock-user-4',
        displayName: 'Taylor',
        email: 'taylor@test.com',
        createdAt: now,
      ),
      AppUser(
        id: 'mock-user-5',
        displayName: 'Riley',
        email: 'riley@test.com',
        createdAt: now,
      ),
    ]);
  }

  void registerUser(AppUser user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
  }

  @override
  Future<List<AppUser>> searchUsers({
    required String query,
    required String excludeUserId,
    int limit = 20,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return [];

    return _users
        .where((u) => u.id != excludeUserId && u.discoverable)
        .where((u) =>
            u.displayNameLower.contains(normalized) ||
            u.email.toLowerCase().contains(normalized))
        .take(limit)
        .toList();
  }

  @override
  Future<AppUser?> getUser(String userId) async {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }
}
