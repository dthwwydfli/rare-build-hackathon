import '../models/friend_group.dart';

abstract class GroupRepository {
  Stream<List<FriendGroup>> watchUserGroups(String userId);
  Future<FriendGroup> createGroup({
    required String name,
    required String ownerId,
  });
  Future<FriendGroup> joinGroupByInviteCode({
    required String inviteCode,
    required String userId,
  });
  Future<FriendGroup?> findGroupByInviteCode(String inviteCode);
  Future<FriendGroup> addMemberToGroup({
    required String groupId,
    required String userId,
  });
}
