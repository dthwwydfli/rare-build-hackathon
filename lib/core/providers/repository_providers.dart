import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_breach_repository.dart';
import '../../data/repositories/firestore_commitment_repository.dart';
import '../../data/repositories/firestore_group_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../data/repositories/mock_breach_repository.dart';
import '../../data/repositories/mock_commitment_repository.dart';
import '../../data/repositories/mock_group_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../data/repositories/mock_user_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/breach_repository.dart';
import '../../domain/repositories/commitment_repository.dart';
import '../../domain/repositories/group_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// Set to true to run without Firebase credentials (UI-only demo).
const bool useMockAuth = true;

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

final breachRepositoryProvider = Provider<BreachRepository>((ref) {
  if (useMockAuth) return MockBreachRepository();
  return FirestoreBreachRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  if (useMockAuth) return _mockUserRepository;
  return FirestoreUserRepository();
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
