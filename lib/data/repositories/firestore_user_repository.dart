import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/app_user.dart';
import '../../domain/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<List<AppUser>> searchUsers({
    required String query,
    required String excludeUserId,
    int limit = 20,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.length < 2) return [];

    final end = '$normalized\uf8ff';
    final snapshot = await _users
        .where('discoverable', isEqualTo: true)
        .where('displayNameLower', isGreaterThanOrEqualTo: normalized)
        .where('displayNameLower', isLessThanOrEqualTo: end)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(AppUser.fromFirestore)
        .where((u) => u.id != excludeUserId)
        .toList();
  }

  @override
  Future<AppUser?> getUser(String userId) async {
    final doc = await _users.doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }
}
