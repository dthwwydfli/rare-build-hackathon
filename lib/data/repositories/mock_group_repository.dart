import 'dart:async';
import 'dart:math';

import '../../domain/models/friend_group.dart';
import '../../domain/repositories/group_repository.dart';

class MockGroupRepository implements GroupRepository {
  final _controller = StreamController<List<FriendGroup>>.broadcast();
  final List<FriendGroup> _groups = [];
  final _random = Random();

  MockGroupRepository() {
    _controller.add([]);
  }

  String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Stream<List<FriendGroup>> watchUserGroups(String userId) {
    return _controller.stream.map(
      (list) => list.where((g) => g.memberIds.contains(userId)).toList(),
    );
  }

  @override
  Future<FriendGroup> createGroup({
    required String name,
    required String ownerId,
  }) async {
    final group = FriendGroup(
      id: 'group-${_groups.length + 1}',
      name: name,
      ownerId: ownerId,
      memberIds: [ownerId],
      inviteCode: _inviteCode(),
      createdAt: DateTime.now(),
    );
    _groups.add(group);
    _controller.add(List.from(_groups));
    return group;
  }

  @override
  Future<FriendGroup?> findGroupByInviteCode(String inviteCode) async {
    try {
      return _groups.firstWhere(
        (g) => g.inviteCode == inviteCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<FriendGroup> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final group = await findGroupByInviteCode(inviteCode);
    if (group == null) throw Exception('Invalid invite code');
    if (group.memberIds.contains(userId)) return group;
    final updated = FriendGroup(
      id: group.id,
      name: group.name,
      ownerId: group.ownerId,
      memberIds: [...group.memberIds, userId],
      inviteCode: group.inviteCode,
      createdAt: group.createdAt,
    );
    final index = _groups.indexWhere((g) => g.id == group.id);
    _groups[index] = updated;
    _controller.add(List.from(_groups));
    return updated;
  }
}
