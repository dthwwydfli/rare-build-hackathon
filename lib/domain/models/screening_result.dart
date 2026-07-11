import 'package:cloud_firestore/cloud_firestore.dart';

enum PgsiSeverityBand {
  nonProblem,
  lowRisk,
  moderateRisk,
  problemGambling;

  String get label => switch (this) {
        PgsiSeverityBand.nonProblem => 'no problem gambling signs',
        PgsiSeverityBand.lowRisk => 'low risk',
        PgsiSeverityBand.moderateRisk => 'moderate risk',
        PgsiSeverityBand.problemGambling => 'problem gambling',
      };
}

enum ScreeningReferralType {
  crisis,
  gamblingModerate,
  gamblingProblem,
  depression,
  anxiety,
  alcohol,
}

class ScreeningReferral {
  const ScreeningReferral({
    required this.type,
    required this.summary,
    required this.resourceIds,
    this.priority = 0,
  });

  final ScreeningReferralType type;
  final String summary;
  final List<String> resourceIds;
  final int priority;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'summary': summary,
        'resourceIds': resourceIds,
        'priority': priority,
      };

  factory ScreeningReferral.fromJson(Map<String, dynamic> json) {
    return ScreeningReferral(
      type: ScreeningReferralType.values.byName(json['type'] as String),
      summary: json['summary'] as String,
      resourceIds: (json['resourceIds'] as List<dynamic>).cast<String>(),
      priority: json['priority'] as int? ?? 0,
    );
  }
}

class ScreeningAnswers {
  const ScreeningAnswers({
    required this.pgsiResponses,
    required this.phq2Responses,
    required this.gad2Responses,
    required this.auditCResponses,
    required this.suicideResponse,
    this.auditCGenderFemale = false,
  });

  final List<int> pgsiResponses;
  final List<int> phq2Responses;
  final List<int> gad2Responses;
  final List<int> auditCResponses;
  final int suicideResponse;
  final bool auditCGenderFemale;
}

class ScreeningResult {
  const ScreeningResult({
    required this.id,
    required this.userId,
    required this.completedAt,
    required this.pgsiScore,
    required this.phq2Score,
    required this.gad2Score,
    required this.auditCScore,
    required this.suicideItemScore,
    required this.pgsiBand,
    required this.referrals,
    required this.crisisTriggered,
    this.screeningVersion = screeningVersionCurrent,
    this.isRescreen = false,
  });

  static const screeningVersionCurrent = '1.0';

  final String id;
  final String userId;
  final DateTime completedAt;
  final int pgsiScore;
  final int phq2Score;
  final int gad2Score;
  final int auditCScore;
  final int suicideItemScore;
  final PgsiSeverityBand pgsiBand;
  final List<ScreeningReferral> referrals;
  final bool crisisTriggered;
  final String screeningVersion;
  final bool isRescreen;

  List<String> get activeReferralFlags => referrals
      .map((r) => r.type.name)
      .toSet()
      .toList();

  factory ScreeningResult.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return ScreeningResult(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pgsiScore: data['pgsiScore'] as int? ?? 0,
      phq2Score: data['phq2Score'] as int? ?? 0,
      gad2Score: data['gad2Score'] as int? ?? 0,
      auditCScore: data['auditCScore'] as int? ?? 0,
      suicideItemScore: data['suicideItemScore'] as int? ?? 0,
      pgsiBand: PgsiSeverityBand.values.byName(
        data['pgsiBand'] as String? ?? PgsiSeverityBand.nonProblem.name,
      ),
      referrals: (data['referrals'] as List<dynamic>? ?? [])
          .map((e) => ScreeningReferral.fromJson(e as Map<String, dynamic>))
          .toList(),
      crisisTriggered: data['crisisTriggered'] as bool? ?? false,
      screeningVersion:
          data['screeningVersion'] as String? ?? screeningVersionCurrent,
      isRescreen: data['isRescreen'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'completedAt': Timestamp.fromDate(completedAt),
      'pgsiScore': pgsiScore,
      'phq2Score': phq2Score,
      'gad2Score': gad2Score,
      'auditCScore': auditCScore,
      'suicideItemScore': suicideItemScore,
      'pgsiBand': pgsiBand.name,
      'referrals': referrals.map((r) => r.toJson()).toList(),
      'crisisTriggered': crisisTriggered,
      'screeningVersion': screeningVersion,
      'isRescreen': isRescreen,
    };
  }
}

class ScreeningStatus {
  const ScreeningStatus({
    required this.screeningCompleted,
    this.lastScreeningAt,
    this.nextScreeningDueAt,
    this.activeReferralFlags = const [],
  });

  final bool screeningCompleted;
  final DateTime? lastScreeningAt;
  final DateTime? nextScreeningDueAt;
  final List<String> activeReferralFlags;

  bool get isOverdue {
    if (nextScreeningDueAt == null) return false;
    return DateTime.now().isAfter(nextScreeningDueAt!);
  }

  static const rescreenInterval = Duration(days: 56); // 8 weeks
}
