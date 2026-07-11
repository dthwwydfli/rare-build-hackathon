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
        displayName: 'Sam Patel',
        email: 'sam@test.com',
        avatarColor: 0xFF6A994E,
        bio: 'Checks in after work and is always up for a quick walk.',
        createdAt: now.subtract(const Duration(days: 320)),
      ),
      AppUser(
        id: 'mock-user-3',
        displayName: 'Jordan Lee',
        email: 'jordan@test.com',
        avatarColor: 0xFF577590,
        bio: 'Football fan, no-bet watch parties, calm voice notes.',
        createdAt: now.subtract(const Duration(days: 260)),
      ),
      AppUser(
        id: 'mock-user-4',
        displayName: 'Maya Green',
        email: 'maya@test.com',
        avatarColor: 0xFFB56576,
        bio: 'Celebrates small wins and helps plan payday guardrails.',
        createdAt: now.subtract(const Duration(days: 210)),
      ),
      AppUser(
        id: 'mock-user-5',
        displayName: 'Riley Chen',
        email: 'riley@test.com',
        avatarColor: 0xFFF4A261,
        bio: 'Morning check-ins, gym buddy, practical distraction ideas.',
        createdAt: now.subtract(const Duration(days: 190)),
      ),
      AppUser(
        id: 'mock-user-6',
        displayName: 'Priya Shah',
        email: 'priya@test.com',
        avatarColor: 0xFF8E7DBE,
        bio: 'Knows blocking tools and loves a spreadsheet plan.',
        createdAt: now.subtract(const Duration(days: 160)),
      ),
      AppUser(
        id: 'mock-user-7',
        displayName: 'Noah Brooks',
        email: 'noah@test.com',
        avatarColor: 0xFF2A9D8F,
        bio: 'Late-night accountability and coffee-before-work streaks.',
        createdAt: now.subtract(const Duration(days: 130)),
      ),
      AppUser(
        id: 'mock-user-8',
        displayName: 'Aisha Morgan',
        email: 'aisha@test.com',
        avatarColor: 0xFFE76F51,
        bio: 'Recovery coach energy: direct, warm, and very dependable.',
        createdAt: now.subtract(const Duration(days: 95)),
      ),
      AppUser(
        id: 'mock-user-9',
        displayName: 'Taylor Reed',
        email: 'taylor@test.com',
        avatarColor: 0xFF4361EE,
        bio: 'Shares urge-surfing prompts and weekend replacement plans.',
        createdAt: now.subtract(const Duration(days: 74)),
      ),
    ]);
  }

  void registerUser(AppUser user) {
    final index = _users.indexWhere((u) => u.id == user.id);
    final enriched = user.copyWith(
      avatarColor: user.avatarColor ?? 0xFF2D6A4F,
      bio: user.bio ?? 'Building a calmer routine with support from friends.',
    );
    if (index >= 0) {
      _users[index] = enriched;
    } else {
      _users.add(enriched);
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
            u.email.toLowerCase().contains(normalized) ||
            (u.bio?.toLowerCase().contains(normalized) ?? false))
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

  @override
  Future<List<AppUser>> suggestedUsers({
    required String excludeUserId,
    int limit = 8,
  }) async {
    return _users
        .where((u) => u.id != excludeUserId && u.discoverable)
        .take(limit)
        .toList();
  }
}
