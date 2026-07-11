import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_widgets.dart';
import '../../../services/screening/screening_definitions.dart';

class InstrumentQuestionStep extends StatelessWidget {
  const InstrumentQuestionStep({
    super.key,
    required this.instrument,
    required this.responses,
    required this.onResponseChanged,
    this.showGenderToggle = false,
    this.genderFemale = false,
    this.onGenderChanged,
  });

  final ScreeningInstrument instrument;
  final List<int?> responses;
  final void Function(int questionIndex, int value) onResponseChanged;
  final bool showGenderToggle;
  final bool genderFemale;
  final ValueChanged<bool>? onGenderChanged;

  bool get isComplete => responses.every((r) => r != null);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: TactileCard(
        useStitch: true,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LowercaseText(
              instrument.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            LowercaseText(
              instrument.description,
              style: const TextStyle(color: AppTheme.inkPlumSoft, height: 1.4),
            ),
            if (showGenderToggle) ...[
              const SizedBox(height: 16),
              const LowercaseText(
                'for alcohol scoring, which applies to you?',
                style: TextStyle(color: AppTheme.inkPlumSoft, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: LowercaseText('man')),
                  ButtonSegment(value: true, label: LowercaseText('woman')),
                ],
                selected: {genderFemale},
                onSelectionChanged: (s) => onGenderChanged?.call(s.first),
              ),
            ],
            const SizedBox(height: 20),
            for (var i = 0; i < instrument.questions.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              _QuestionBlock(
                index: i,
                question: instrument.questions[i],
                selected: responses[i],
                onSelected: (value) => onResponseChanged(i, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelected,
  });

  final int index;
  final ScreeningQuestion question;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LowercaseText(
          '${index + 1}. ${question.text}',
          style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
        ),
        if (question.timeframe != null) ...[
          const SizedBox(height: 4),
          LowercaseText(
            question.timeframe!,
            style: const TextStyle(fontSize: 12, color: AppTheme.inkPlumSoft),
          ),
        ],
        const SizedBox(height: 10),
        ...question.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RadioListTile<int>(
              value: option.value,
              groupValue: selected,
              onChanged: (v) {
                if (v != null) onSelected(v);
              },
              title: LowercaseText(option.label),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ),
      ],
    );
  }
}
