import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_breach_repository.dart';
import '../../data/repositories/firestore_commitment_repository.dart';
import '../../data/repositories/firestore_group_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/breach_repository.dart';
import '../../domain/repositories/commitment_repository.dart';
import '../../domain/repositories/group_repository.dart';

/// Set to true to run without Firebase credentials (UI-only demo).
const bool useMockAuth = false;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockAuth) return MockAuthRepository();
  return FirebaseAuthRepository();
});

final commitmentRepositoryProvider = Provider<CommitmentRepository>((ref) {
  return FirestoreCommitmentRepository();
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return FirestoreGroupRepository();
});

final breachRepositoryProvider = Provider<BreachRepository>((ref) {
  return FirestoreBreachRepository();
});

final currentUserProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});
