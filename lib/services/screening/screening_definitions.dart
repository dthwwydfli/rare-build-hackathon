/// Validated screening instruments — single source of truth for question text.
class ScreeningInstrumentId {
  static const pgsi = 'pgsi';
  static const phq2 = 'phq2';
  static const gad2 = 'gad2';
  static const auditC = 'audit_c';
  static const suicide = 'suicide';
}

class ScreeningOption {
  const ScreeningOption({required this.label, required this.value});

  final String label;
  final int value;
}

class ScreeningQuestion {
  const ScreeningQuestion({
    required this.id,
    required this.text,
    required this.options,
    this.timeframe,
  });

  final String id;
  final String text;
  final List<ScreeningOption> options;
  final String? timeframe;
}

class ScreeningInstrument {
  const ScreeningInstrument({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  final String id;
  final String title;
  final String description;
  final List<ScreeningQuestion> questions;
}

/// Standard 4-point Likert used by PGSI, PHQ-2, GAD-2, and PHQ-9 item 9.
const kLikertPastMonth = [
  ScreeningOption(label: 'not at all', value: 0),
  ScreeningOption(label: 'sometimes', value: 1),
  ScreeningOption(label: 'most of the time', value: 2),
  ScreeningOption(label: 'almost always', value: 3),
];

const kLikertPastTwoWeeks = [
  ScreeningOption(label: 'not at all', value: 0),
  ScreeningOption(label: 'several days', value: 1),
  ScreeningOption(label: 'more than half the days', value: 2),
  ScreeningOption(label: 'nearly every day', value: 3),
];

const kPgsiInstrument = ScreeningInstrument(
  id: ScreeningInstrumentId.pgsi,
  title: 'gambling severity (PGSI)',
  description:
      'Think about the past 12 months. How often have you experienced the following?',
  questions: [
    ScreeningQuestion(
      id: 'pgsi_1',
      text: 'bet more than you could really afford to lose',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_2',
      text: 'needed to gamble with larger amounts to get the same excitement',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_3',
      text: 'gone back another day to try to win back money you lost',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_4',
      text: 'borrowed money or sold anything to get money to gamble',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_5',
      text: 'felt that you might have a problem with gambling',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_6',
      text: 'gambling caused health problems, including stress or anxiety',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_7',
      text:
          'people criticized your betting or said you had a gambling problem',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_8',
      text: 'gambling caused financial problems for you or your household',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
    ScreeningQuestion(
      id: 'pgsi_9',
      text: 'felt guilty about the way you gamble or what happens when you do',
      options: kLikertPastMonth,
      timeframe: 'past 12 months',
    ),
  ],
);

const kPhq2Instrument = ScreeningInstrument(
  id: ScreeningInstrumentId.phq2,
  title: 'low mood check (PHQ-2)',
  description: 'Over the last 2 weeks, how often have you been bothered by:',
  questions: [
    ScreeningQuestion(
      id: 'phq2_1',
      text: 'little interest or pleasure in doing things',
      options: kLikertPastTwoWeeks,
      timeframe: 'past 2 weeks',
    ),
    ScreeningQuestion(
      id: 'phq2_2',
      text: 'feeling down, depressed, or hopeless',
      options: kLikertPastTwoWeeks,
      timeframe: 'past 2 weeks',
    ),
  ],
);

const kGad2Instrument = ScreeningInstrument(
  id: ScreeningInstrumentId.gad2,
  title: 'anxiety check (GAD-2)',
  description: 'Over the last 2 weeks, how often have you been bothered by:',
  questions: [
    ScreeningQuestion(
      id: 'gad2_1',
      text: 'feeling nervous, anxious, or on edge',
      options: kLikertPastTwoWeeks,
      timeframe: 'past 2 weeks',
    ),
    ScreeningQuestion(
      id: 'gad2_2',
      text: 'not being able to stop or control worrying',
      options: kLikertPastTwoWeeks,
      timeframe: 'past 2 weeks',
    ),
  ],
);

const kAuditCInstrument = ScreeningInstrument(
  id: ScreeningInstrumentId.auditC,
  title: 'alcohol check (AUDIT-C)',
  description: 'About your drinking in the past year:',
  questions: [
    ScreeningQuestion(
      id: 'audit_c_1',
      text: 'how often do you have a drink containing alcohol?',
      options: [
        ScreeningOption(label: 'never', value: 0),
        ScreeningOption(label: 'monthly or less', value: 1),
        ScreeningOption(label: '2–4 times a month', value: 2),
        ScreeningOption(label: '2–3 times a week', value: 3),
        ScreeningOption(label: '4+ times a week', value: 4),
      ],
    ),
    ScreeningQuestion(
      id: 'audit_c_2',
      text:
          'how many drinks do you have on a typical day when you are drinking?',
      options: [
        ScreeningOption(label: '1–2', value: 0),
        ScreeningOption(label: '3–4', value: 1),
        ScreeningOption(label: '5–6', value: 2),
        ScreeningOption(label: '7–9', value: 3),
        ScreeningOption(label: '10 or more', value: 4),
      ],
    ),
    ScreeningQuestion(
      id: 'audit_c_3',
      text: 'how often do you have six or more drinks on one occasion?',
      options: [
        ScreeningOption(label: 'never', value: 0),
        ScreeningOption(label: 'less than monthly', value: 1),
        ScreeningOption(label: 'monthly', value: 2),
        ScreeningOption(label: 'weekly', value: 3),
        ScreeningOption(label: 'daily or almost daily', value: 4),
      ],
    ),
  ],
);

const kSuicideInstrument = ScreeningInstrument(
  id: ScreeningInstrumentId.suicide,
  title: 'safety check',
  description: 'Over the last 2 weeks:',
  questions: [
    ScreeningQuestion(
      id: 'suicide_1',
      text:
          'thoughts that you would be better off dead, or of hurting yourself',
      options: kLikertPastTwoWeeks,
      timeframe: 'past 2 weeks',
    ),
  ],
);

const kScreeningInstruments = [
  kPgsiInstrument,
  kPhq2Instrument,
  kGad2Instrument,
  kAuditCInstrument,
  kSuicideInstrument,
];

const kScreeningIntroTitle = 'wellbeing check-in';
const kScreeningIntroBody =
    'these short questionnaires are not a diagnosis. they help us point you to the right support if gambling, mood, anxiety, or drinking are affecting you.';
const kScreeningPrivacyNote =
    'your answers stay private — they are never shared with your friend circle.';
