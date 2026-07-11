import '../../domain/models/screening_result.dart';

/// Pure scoring and triage logic with validated cut-offs.
class ScreeningScorer {
  const ScreeningScorer._();

  static int sumResponses(List<int> responses) =>
      responses.fold(0, (sum, v) => sum + v);

  static PgsiSeverityBand pgsiBand(int score) {
    if (score >= 8) return PgsiSeverityBand.problemGambling;
    if (score >= 3) return PgsiSeverityBand.moderateRisk;
    if (score >= 1) return PgsiSeverityBand.lowRisk;
    return PgsiSeverityBand.nonProblem;
  }

  static bool phq2Positive(int score) => score >= 3;
  static bool gad2Positive(int score) => score >= 3;
  static bool auditCPositive(int score, {required bool female}) =>
      score >= (female ? 3 : 4);
  static bool crisisTriggered(int suicideScore) => suicideScore >= 1;

  static List<ScreeningReferral> buildReferrals({
    required ScreeningAnswers answers,
    required int pgsiScore,
    required int phq2Score,
    required int gad2Score,
    required int auditCScore,
    required int suicideScore,
  }) {
    final referrals = <ScreeningReferral>[];

    if (crisisTriggered(suicideScore)) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.crisis,
          summary:
              'you indicated thoughts of self-harm — please reach out for immediate support',
          resourceIds: ['samaritans', 'gamcare', 'nhs-111'],
          priority: 100,
        ),
      );
    }

    final band = pgsiBand(pgsiScore);
    if (band == PgsiSeverityBand.problemGambling) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.gamblingProblem,
          summary:
              'your gambling severity suggests problem gambling — specialist support is recommended',
          resourceIds: [
            'gamcare',
            'gamblers-anonymous',
            'gordon-moody',
            'block-access',
          ],
          priority: 80,
        ),
      );
    } else if (band == PgsiSeverityBand.moderateRisk) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.gamblingModerate,
          summary:
              'your gambling severity is in the moderate range — talking to a specialist could help',
          resourceIds: ['gamcare', 'gamblers-anonymous', 'gordon-moody'],
          priority: 60,
        ),
      );
    } else if (band == PgsiSeverityBand.lowRisk) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.gamblingModerate,
          summary: 'some gambling risk signs — GamCare offers free confidential advice',
          resourceIds: ['gamcare', 'be-gamble-aware'],
          priority: 20,
        ),
      );
    }

    if (phq2Positive(phq2Score)) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.depression,
          summary:
              'your mood screen suggests depression symptoms — NHS talking therapies can help',
          resourceIds: ['nhs-talking-therapies', 'nhs-111', 'samaritans'],
          priority: 70,
        ),
      );
    }

    if (gad2Positive(gad2Score)) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.anxiety,
          summary:
              'your anxiety screen is elevated — consider NHS talking therapies or your GP',
          resourceIds: ['nhs-talking-therapies', 'nhs-111', 'samaritans'],
          priority: 65,
        ),
      );
    }

    if (auditCPositive(
      auditCScore,
      female: answers.auditCGenderFemale,
    )) {
      referrals.add(
        const ScreeningReferral(
          type: ScreeningReferralType.alcohol,
          summary:
              'your drinking screen suggests hazardous use — support is available',
          resourceIds: ['nhs-talking-therapies', 'nhs-111'],
          priority: 55,
        ),
      );
    }

    referrals.sort((a, b) => b.priority.compareTo(a.priority));
    return referrals;
  }

  static ScreeningResult score({
    required String userId,
    required ScreeningAnswers answers,
    String? id,
    bool isRescreen = false,
  }) {
    final pgsiScore = sumResponses(answers.pgsiResponses);
    final phq2Score = sumResponses(answers.phq2Responses);
    final gad2Score = sumResponses(answers.gad2Responses);
    final auditCScore = sumResponses(answers.auditCResponses);
    final suicideScore = answers.suicideResponse;
    final crisis = crisisTriggered(suicideScore);

    return ScreeningResult(
      id: id ?? '',
      userId: userId,
      completedAt: DateTime.now(),
      pgsiScore: pgsiScore,
      phq2Score: phq2Score,
      gad2Score: gad2Score,
      auditCScore: auditCScore,
      suicideItemScore: suicideScore,
      pgsiBand: pgsiBand(pgsiScore),
      referrals: buildReferrals(
        answers: answers,
        pgsiScore: pgsiScore,
        phq2Score: phq2Score,
        gad2Score: gad2Score,
        auditCScore: auditCScore,
        suicideScore: suicideScore,
      ),
      crisisTriggered: crisis,
      isRescreen: isRescreen,
    );
  }
}
