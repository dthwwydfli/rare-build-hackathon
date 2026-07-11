import 'package:flutter_test/flutter_test.dart';

import 'package:accountability_app/domain/models/screening_result.dart';
import 'package:accountability_app/services/screening/screening_scorer.dart';

void main() {
  group('ScreeningScorer', () {
    test('PGSI bands use Ferris & Wynne cut-offs', () {
      expect(ScreeningScorer.pgsiBand(0), PgsiSeverityBand.nonProblem);
      expect(ScreeningScorer.pgsiBand(2), PgsiSeverityBand.lowRisk);
      expect(ScreeningScorer.pgsiBand(5), PgsiSeverityBand.moderateRisk);
      expect(ScreeningScorer.pgsiBand(8), PgsiSeverityBand.problemGambling);
    });

    test('suicide score >= 1 triggers crisis', () {
      expect(ScreeningScorer.crisisTriggered(0), isFalse);
      expect(ScreeningScorer.crisisTriggered(1), isTrue);
    });

    test('PHQ-2 and GAD-2 positive at >= 3', () {
      expect(ScreeningScorer.phq2Positive(2), isFalse);
      expect(ScreeningScorer.phq2Positive(3), isTrue);
      expect(ScreeningScorer.gad2Positive(3), isTrue);
    });

    test('AUDIT-C uses gender-specific cut-offs', () {
      expect(ScreeningScorer.auditCPositive(3, female: false), isFalse);
      expect(ScreeningScorer.auditCPositive(4, female: false), isTrue);
      expect(ScreeningScorer.auditCPositive(3, female: true), isTrue);
    });

    test('crisis referral has highest priority', () {
      final result = ScreeningScorer.score(
        userId: 'u1',
        answers: const ScreeningAnswers(
          pgsiResponses: [3, 3, 3, 0, 0, 0, 0, 0, 0],
          phq2Responses: [3, 3],
          gad2Responses: [0, 0],
          auditCResponses: [0, 0, 0],
          suicideResponse: 2,
        ),
      );
      expect(result.crisisTriggered, isTrue);
      expect(result.referrals.first.type, ScreeningReferralType.crisis);
    });
  });
}
