import 'dart:async';

import '../../domain/models/app_user.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/gamification_repository.dart';

class MockGamificationRepository implements GamificationRepository {
  MockGamificationRepository() {
    _seedUsers();
  }

  final _controller = StreamController<void>.broadcast();
  final Map<String, AppUser> _users = {};

  void _seedUsers() {
    final now = DateTime.now();
    final seeds = [
      ('mock-user-1', 'Alex', 1047, 12, 18),
      ('mock-user-2', 'Sam', 1120, 21, 30),
      ('mock-user-3', 'Jordan', 980, 5, 14),
      ('mock-user-4', 'Riley', 1085, 9, 9),
      ('mock-user-5', 'Casey', 1150, 30, 30),
      ('mock-user-6', 'Morgan', 1020, 3, 10),
      ('mock-user-7', 'Taylor', 890, 0, 7),
      ('mock-user-8', 'Quinn', 1230, 45, 45),
    ];
    for (final (id, name, points, streak, best) in seeds) {
      _users[id] = AppUser(
        id: id,
        displayName: name,
        email: '$name@test.com',
        createdAt: now.subtract(const Duration(days: 30)),
        points: points,
        currentStreak: streak,
        bestStreak: best,
        lastCleanDate: now.subtract(const Duration(days: 1)),
      );
    }
  }

  void registerUser(AppUser user) {
    _users[user.id] = user.copyWith(
      points: user.points == 1000 && user.currentStreak == 0
          ? 1000
          : user.points,
    );
    _notify();
  }

  void _notify() => _controller.add(null);

  List<LeaderboardEntry> _ranked(Iterable<AppUser> users) {
    final sorted = users.toList()
      ..sort((a, b) {
        final pointsCmp = b.points.compareTo(a.points);
        if (pointsCmp != 0) return pointsCmp;
        return b.currentStreak.compareTo(a.currentStreak);
      });
    return sorted.asMap().entries.map((e) {
      final u = e.value;
      return LeaderboardEntry(
        userId: u.id,
        displayName: u.displayName,
        points: u.points,
        currentStreak: u.currentStreak,
        rank: e.key + 1,
      );
    }).toList();
  }

  @override
  Stream<AppUser> watchUserStats(String userId) async* {
    yield _users[userId] ??
        AppUser(
          id: userId,
          displayName: 'player',
          email: '',
          createdAt: DateTime.now(),
        );
    await for (final _ in _controller.stream) {
      yield _users[userId] ??
          AppUser(
            id: userId,
            displayName: 'player',
            email: '',
            createdAt: DateTime.now(),
          );
    }
  }

  @override
  Stream<List<LeaderboardEntry>> watchGroupLeaderboard(String groupId) async* {
    // Mock: return all seeded users except filter by group membership pattern
    final memberIds = _groupMemberIds(groupId);
    List<LeaderboardEntry> build() {
      final members = memberIds
          .map((id) => _users[id])
          .whereType<AppUser>()
          .toList();
      if (members.isEmpty) {
        return _ranked(_users.values.take(3));
      }
      return _ranked(members);
    }

    yield build();
    await for (final _ in _controller.stream) {
      yield build();
    }
  }

  List<String> _groupMemberIds(String groupId) {
    if (_groupMembers.containsKey(groupId)) {
      return _groupMembers[groupId]!;
    }
    switch (groupId) {
      case 'group-1':
        return ['mock-user-1', 'mock-user-2', 'mock-user-3'];
      default:
        return ['mock-user-1', 'mock-user-2', 'mock-user-4', 'mock-user-5'];
    }
  }

  void setGroupMembers(String groupId, List<String> memberIds) {
    _groupMembers[groupId] = memberIds;
    _notify();
  }

  final Map<String, List<String>> _groupMembers = {};

  @override
  Stream<List<LeaderboardEntry>> watchGlobalLeaderboard({int limit = 50}) async* {
    List<LeaderboardEntry> build() => _ranked(_users.values).take(limit).toList();
    yield build();
    await for (final _ in _controller.stream) {
      yield build();
    }
  }

  @override
  Future<void> applySupportBonus(String userId) async {
    final user = _users[userId];
    if (user == null) return;
    _users[userId] = user.copyWith(points: user.points + 5);
    _notify();
  }

  @override
  Future<void> applyBreachPenalty(String userId, {int severity = 1}) async {
    final user = _users[userId];
    if (user == null) return;
    final penalty = severity >= 2 ? 60 : 30;
    _users[userId] = user.copyWith(
      points: (user.points - penalty).clamp(0, 9999),
      currentStreak: 0,
      lastBreachDate: DateTime.now(),
    );
    _notify();
  }

  AppUser? getUser(String userId) => _users[userId];

  void updateUser(AppUser user) {
    _users[user.id] = user;
    _notify();
  }
}
