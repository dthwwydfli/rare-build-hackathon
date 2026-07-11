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
import '../../data/repositories/firestore_user_repository.dart';
import '../../data/repositories/mock_user_repository.dart';
import '../../data/repositories/firestore_access_block_repository.dart';
import '../../data/repositories/mock_access_block_repository.dart';
import '../../data/repositories/firestore_urge_repository.dart';
import '../../data/repositories/mock_urge_repository.dart';
import '../../data/repositories/firestore_screening_repository.dart';
import '../../data/repositories/mock_screening_repository.dart';
import '../../data/repositories/firestore_financial_recovery_repository.dart';
import '../../data/repositories/mock_financial_recovery_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/access_block_settings.dart';
import '../../domain/models/financial_recovery_profile.dart';
import '../../domain/models/friend_group.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/breach_repository.dart';
import '../../domain/repositories/commitment_repository.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../config/app_config.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/access_block_repository.dart';
import '../../domain/repositories/urge_repository.dart';
import '../../domain/repositories/screening_repository.dart';
import '../../domain/repositories/financial_recovery_repository.dart';

export '../config/app_config.dart' show useMockAuth;

final _mockUserRepository = MockUserRepository();

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
    return MockBreachRepository();
  }
  return FirestoreBreachRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (useMockAuth) return _mockUserRepository;
  return FirestoreUserRepository();
});

final accessBlockRepositoryProvider = Provider<AccessBlockRepository>((ref) {
  if (useMockAuth) return MockAccessBlockRepository();
  return FirestoreAccessBlockRepository();
});

final urgeRepositoryProvider = Provider<UrgeRepository>((ref) {
  if (useMockAuth) return MockUrgeRepository();
  return FirestoreUrgeRepository();
});

final screeningRepositoryProvider = Provider<ScreeningRepository>((ref) {
  if (useMockAuth) return MockScreeningRepository();
  return FirestoreScreeningRepository();
});

final financialRecoveryRepositoryProvider =
    Provider<FinancialRecoveryRepository>((ref) {
  if (useMockAuth) return MockFinancialRecoveryRepository();
  return FirestoreFinancialRecoveryRepository();
});

final blockSettingsProvider =
    StreamProvider.family<AccessBlockSettings, String>((ref, userId) {
  return ref.watch(accessBlockRepositoryProvider).watchSettings(userId);
});

final financialRecoveryProfileProvider =
    StreamProvider.family<FinancialRecoveryProfile, String>((ref, userId) {
  return ref
      .watch(financialRecoveryRepositoryProvider)
      .watchProfile(userId);
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authStream = ref.watch(authRepositoryProvider).watchCurrentUser();
  if (!useMockAuth) return authStream;

  return authStream.map((user) {
    if (user != null) {
      _mockUserRepository.registerUser(user);
    }
    return user;
  });
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

final userGroupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
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
