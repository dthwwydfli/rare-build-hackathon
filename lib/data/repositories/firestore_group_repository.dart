import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/friend_group.dart';
import '../../domain/repositories/group_repository.dart';

class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _random = Random();

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Stream<List<FriendGroup>> watchUserGroups(String userId) {
    return _groups
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(FriendGroup.fromFirestore).toList());
  }

  @override
  Future<FriendGroup> createGroup({
    required String name,
    required String ownerId,
  }) async {
    final doc = _groups.doc();
    final group = FriendGroup(
      id: doc.id,
      name: name,
      ownerId: ownerId,
      memberIds: [ownerId],
      inviteCode: _generateInviteCode(),
      createdAt: DateTime.now(),
    );
    await doc.set(group.toFirestore());
    return group;
  }

  @override
  Future<FriendGroup?> findGroupByInviteCode(String inviteCode) async {
    final snapshot = await _groups
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return FriendGroup.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<FriendGroup> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final group = await findGroupByInviteCode(inviteCode);
    if (group == null) {
      throw Exception('Invalid invite code');
    }
    if (group.memberIds.contains(userId)) {
      return group;
    }
    final updatedMemberIds = [...group.memberIds, userId];
    await _groups.doc(group.id).update({'memberIds': updatedMemberIds});
    return FriendGroup(
      id: group.id,
      name: group.name,
      ownerId: group.ownerId,
      memberIds: updatedMemberIds,
      inviteCode: group.inviteCode,
      createdAt: group.createdAt,
    );
  }
}
