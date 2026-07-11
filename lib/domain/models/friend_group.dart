import 'package:cloud_firestore/cloud_firestore.dart';

class FriendGroup {
  const FriendGroup({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    required this.inviteCode,
    this.coverAsset,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final String inviteCode;
  final String? coverAsset;
  final DateTime createdAt;

  factory FriendGroup.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FriendGroup(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      inviteCode: data['inviteCode'] as String? ?? '',
      coverAsset: data['coverAsset'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      if (coverAsset != null) 'coverAsset': coverAsset,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
