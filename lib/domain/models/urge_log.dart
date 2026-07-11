import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// CBT-style urge log — when, where, mood, money, trigger.
class UrgeLog {
  const UrgeLog({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.intensity,
    required this.mood,
    required this.trigger,
    this.location,
    this.moneyOnHand,
    required this.resisted,
    this.notes,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final int intensity;
  final UrgeMood mood;
  final UrgeTrigger trigger;
  final String? location;
  final double? moneyOnHand;
  final bool resisted;
  final String? notes;

  factory UrgeLog.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UrgeLog(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      intensity: data['intensity'] as int? ?? 5,
      mood: UrgeMoodX.fromString(data['mood'] as String? ?? 'neutral'),
      trigger: UrgeTriggerX.fromString(data['trigger'] as String? ?? 'other'),
      location: data['location'] as String?,
      moneyOnHand: (data['moneyOnHand'] as num?)?.toDouble(),
      resisted: data['resisted'] as bool? ?? true,
      notes: data['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'intensity': intensity,
      'mood': mood.name,
      'trigger': trigger.name,
      if (location != null) 'location': location,
      if (moneyOnHand != null) 'moneyOnHand': moneyOnHand,
      'resisted': resisted,
      if (notes != null) 'notes': notes,
    };
  }
}

class UrgePatternInsight {
  const UrgePatternInsight({
    required this.title,
    required this.detail,
    required this.riskLevel,
  });

  final String title;
  final String detail;
  final String riskLevel;
}

class CopingPrompt {
  const CopingPrompt({
    required this.title,
    required this.message,
    required this.technique,
  });

  final String title;
  final String message;
  final String technique;
}
