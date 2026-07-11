import 'package:flutter_test/flutter_test.dart';

import 'package:accountability_app/data/repositories/mock_gamification_repository.dart';
import 'package:accountability_app/domain/models/app_user.dart';

void main() {
  test('support bonus increases points by 5', () async {
    final repo = MockGamificationRepository();
    const userId = 'mock-user-1';
    final before = repo.getUser(userId)!.points;

    await repo.applySupportBonus(userId);

    expect(repo.getUser(userId)!.points, before + 5);
  });

  test('breach penalty decreases points and resets streak', () async {
    final repo = MockGamificationRepository();
    repo.registerUser(
      AppUser(
        id: 'test-user',
        displayName: 'test',
        email: 'test@test.com',
        createdAt: DateTime(2026),
        points: 1050,
        currentStreak: 10,
      ),
    );

    await repo.applyBreachPenalty('test-user', severity: 1);

    final user = repo.getUser('test-user')!;
    expect(user.points, 1020);
    expect(user.currentStreak, 0);
  });

  test('global leaderboard returns ranked entries', () async {
    final repo = MockGamificationRepository();
    final entries = await repo.watchGlobalLeaderboard().first;

    expect(entries, isNotEmpty);
    expect(entries.first.rank, 1);
    expect(entries.first.points, greaterThanOrEqualTo(entries.last.points));
  });
}
