import 'dart:async';
import 'dart:math';

import '../../domain/models/friend_group.dart';
import '../../domain/repositories/group_repository.dart';

class MockGroupRepository implements GroupRepository {
  final _controller = StreamController<List<FriendGroup>>.broadcast();
  final List<FriendGroup> _groups = [];
  final _random = Random();

  MockGroupRepository() {
    _seedGroups();
    _controller.add(List.from(_groups));
  }

  void _seedGroups() {
    final now = DateTime.now();
    _groups.addAll([
      FriendGroup(
        id: 'group-weekend-reset',
        name: 'Weekend reset circle',
        ownerId: 'mock-user-2',
        memberIds: const [
          'mock-user-1',
          'mock-user-2',
          'mock-user-3',
          'mock-user-5',
        ],
        inviteCode: 'RESET7',
        createdAt: now.subtract(const Duration(days: 42)),
      ),
      FriendGroup(
        id: 'group-payday-plan',
        name: 'Payday plan crew',
        ownerId: 'mock-user-4',
        memberIds: const [
          'mock-user-1',
          'mock-user-4',
          'mock-user-6',
          'mock-user-8',
        ],
        inviteCode: 'PAYDAY',
        createdAt: now.subtract(const Duration(days: 28)),
      ),
      FriendGroup(
        id: 'group-matchday',
        name: 'Matchday no-bet group',
        ownerId: 'mock-user-3',
        memberIds: const [
          'mock-user-1',
          'mock-user-3',
          'mock-user-7',
          'mock-user-9',
        ],
        inviteCode: 'NOBETS',
        createdAt: now.subtract(const Duration(days: 18)),
      ),
    ]);
  }

  String _inviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  @override
  Stream<List<FriendGroup>> watchUserGroups(String userId) async* {
    await for (final list in _groupStream()) {
      yield list.where((g) => g.memberIds.contains(userId)).toList();
    }
  }

  Stream<List<FriendGroup>> _groupStream() async* {
    yield List.from(_groups);
    yield* _controller.stream;
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

  @override
  Future<FriendGroup> addMemberToGroup({
    required String groupId,
    required String userId,
  }) async {
    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index < 0) throw Exception('Group not found');
    final group = _groups[index];
    if (group.memberIds.contains(userId)) return group;

    final updated = FriendGroup(
      id: group.id,
      name: group.name,
      ownerId: group.ownerId,
      memberIds: [...group.memberIds, userId],
      inviteCode: group.inviteCode,
      createdAt: group.createdAt,
    );
    _groups[index] = updated;
    _controller.add(List.from(_groups));
    return updated;
  }
}
