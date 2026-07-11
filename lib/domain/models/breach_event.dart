import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class BreachEvent {
  const BreachEvent({
    required this.id,
    required this.userId,
    required this.commitmentId,
    required this.groupId,
    required this.signalType,
    required this.metadata,
    required this.severity,
    required this.createdAt,
    this.flagged = true,
    this.acknowledged = false,
    this.userName,
  });

  final String id;
  final String userId;
  final String commitmentId;
  final String groupId;
  final BreachSignalType signalType;
  final Map<String, dynamic> metadata;
  final String severity;
  final DateTime createdAt;
  final bool flagged;
  final bool acknowledged;
  final String? userName;

  bool get needsSupport => flagged && !acknowledged;

  String get summary {
    switch (signalType) {
      case BreachSignalType.location:
        return metadata['placeName'] as String? ?? 'Near a gambling location';
      case BreachSignalType.app:
        return 'Opened ${metadata['appName'] ?? 'gambling app'}';
      case BreachSignalType.url:
        return 'Visited ${metadata['url'] ?? 'gambling website'}';
      case BreachSignalType.payment:
        return 'Possible gambling spend detected';
      case BreachSignalType.manual:
        return metadata['note'] as String? ?? 'Manual breach reported';
    }
  }

  factory BreachEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return BreachEvent(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      commitmentId: data['commitmentId'] as String? ?? '',
      groupId: data['groupId'] as String? ?? '',
      signalType: BreachSignalTypeX.fromString(data['signalType'] as String? ?? 'manual'),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      severity: data['severity'] as String? ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      flagged: data['flagged'] as bool? ?? true,
      acknowledged: data['acknowledged'] as bool? ?? false,
      userName: data['userName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'commitmentId': commitmentId,
      'groupId': groupId,
      'signalType': signalType.name,
      'metadata': metadata,
      'severity': severity,
      'createdAt': Timestamp.fromDate(createdAt),
      'flagged': flagged,
      'acknowledged': acknowledged,
      if (userName != null) 'userName': userName,
    };
  }

  BreachEvent copyWith({
    bool? flagged,
    bool? acknowledged,
  }) {
    return BreachEvent(
      id: id,
      userId: userId,
      commitmentId: commitmentId,
      groupId: groupId,
      signalType: signalType,
      metadata: metadata,
      severity: severity,
      createdAt: createdAt,
      flagged: flagged ?? this.flagged,
      acknowledged: acknowledged ?? this.acknowledged,
      userName: userName,
    );
  }
}
