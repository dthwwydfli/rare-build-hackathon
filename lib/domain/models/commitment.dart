import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

class CommitmentRules {
  const CommitmentRules({
    this.blockedApps = const [],
    this.blockedDomains = const [],
    this.maxSpend,
    this.geofenceRadiusM = 200,
  });

  final List<String> blockedApps;
  final List<String> blockedDomains;
  final double? maxSpend;
  final int geofenceRadiusM;

  factory CommitmentRules.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const CommitmentRules();
    return CommitmentRules(
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      blockedDomains: List<String>.from(map['blockedDomains'] ?? []),
      maxSpend: (map['maxSpend'] as num?)?.toDouble(),
      geofenceRadiusM: map['geofenceRadiusM'] as int? ?? 200,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockedApps': blockedApps,
      'blockedDomains': blockedDomains,
      if (maxSpend != null) 'maxSpend': maxSpend,
      'geofenceRadiusM': geofenceRadiusM,
    };
  }
}

class Commitment {
  const Commitment({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.rules,
    required this.active,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final CommitmentType type;
  final CommitmentRules rules;
  final bool active;
  final DateTime createdAt;

  factory Commitment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Commitment(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      type: CommitmentTypeX.fromString(data['type'] as String? ?? 'online'),
      rules: CommitmentRules.fromMap(data['rules'] as Map<String, dynamic>?),
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'type': type.name,
      'rules': rules.toMap(),
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
