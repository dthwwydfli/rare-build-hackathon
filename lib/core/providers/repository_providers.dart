import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_breach_repository.dart';
import '../../data/repositories/firestore_commitment_repository.dart';
import '../../data/repositories/firestore_gamification_repository.dart';
import '../../data/repositories/firestore_group_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/mock_breach_repository.dart';
import '../../data/repositories/mock_commitment_repository.dart';
import '../../data/repositories/mock_gamification_repository.dart';
import '../../data/repositories/mock_group_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/breach_repository.dart';
import '../../domain/repositories/commitment_repository.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../config/app_config.dart';

export '../config/app_config.dart' show useMockAuth;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockAuth) return MockAuthRepository();
  return FirebaseAuthRepository();
});

final commitmentRepositoryProvider = Provider<CommitmentRepository>((ref) {
  if (useMockAuth) return MockCommitmentRepository();
  return FirestoreCommitmentRepository();
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  if (useMockAuth) return MockGroupRepository();
  return FirestoreGroupRepository();
});

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  if (useMockAuth) return MockGamificationRepository();
  return FirestoreGamificationRepository();
});

final breachRepositoryProvider = Provider<BreachRepository>((ref) {
  if (useMockAuth) {
    return MockBreachRepository(
      onBreachCreated: (userId, {severity = 1}) {
        ref.read(gamificationRepositoryProvider).applyBreachPenalty(
              userId,
              severity: severity,
            );
      },
    );
  }
  return FirestoreBreachRepository();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});

final userStatsProvider = StreamProvider.family<AppUser, String>((ref, userId) {
  return ref.watch(gamificationRepositoryProvider).watchUserStats(userId);
});

final groupLeaderboardProvider =
    StreamProvider.family<List<LeaderboardEntry>, String>((ref, groupId) {
  return ref
      .watch(gamificationRepositoryProvider)
      .watchGroupLeaderboard(groupId);
});

final globalLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(gamificationRepositoryProvider).watchGlobalLeaderboard();
});

/// Keeps mock gamification stats in sync with the signed-in user.
final gamificationSyncProvider = Provider<void>((ref) {
  if (!useMockAuth) return;
  final user = ref.watch(currentUserProvider).valueOrNull;
  final gamification = ref.watch(gamificationRepositoryProvider);
  if (user != null && gamification is MockGamificationRepository) {
    gamification.registerUser(user);
  }
});
