import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/screening_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/screening_result.dart';
import '../../services/screening/screening_definitions.dart';
import '../../services/screening/screening_scorer.dart';
import 'widgets/question_step.dart';

class ScreeningWizardScreen extends ConsumerStatefulWidget {
  const ScreeningWizardScreen({super.key, this.isRescreen = false});

  final bool isRescreen;

  @override
  ConsumerState<ScreeningWizardScreen> createState() =>
      _ScreeningWizardScreenState();
}

class _ScreeningWizardScreenState extends ConsumerState<ScreeningWizardScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _submitting = false;

  late final List<int?> _pgsi;
  late final List<int?> _phq2;
  late final List<int?> _gad2;
  late final List<int?> _auditC;
  int? _suicide;
  bool _genderFemale = false;

  int get _stepCount => widget.isRescreen ? 5 : 6;
  int get _introOffset => widget.isRescreen ? 0 : 1;

  @override
  void initState() {
    super.initState();
    _pgsi = List.filled(kPgsiInstrument.questions.length, null);
    _phq2 = List.filled(kPhq2Instrument.questions.length, null);
    _gad2 = List.filled(kGad2Instrument.questions.length, null);
    _auditC = List.filled(kAuditCInstrument.questions.length, null);
    if (widget.isRescreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(screeningSessionProvider.notifier).setRescreen(true);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _stepComplete(int page) {
    if (!widget.isRescreen && page == 0) return true;
    final instrumentIndex = page - _introOffset;
    return switch (instrumentIndex) {
      0 => _pgsi.every((r) => r != null),
      1 => _phq2.every((r) => r != null) && _gad2.every((r) => r != null),
      2 => _auditC.every((r) => r != null),
      3 => _suicide != null,
      _ => false,
    };
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null || _suicide == null) return;

    setState(() => _submitting = true);
    try {
      final answers = ScreeningAnswers(
        pgsiResponses: _pgsi.cast<int>(),
        phq2Responses: _phq2.cast<int>(),
        gad2Responses: _gad2.cast<int>(),
        auditCResponses: _auditC.cast<int>(),
        suicideResponse: _suicide!,
        auditCGenderFemale: _genderFemale,
      );

      final result = ScreeningScorer.score(
        userId: user.id,
        answers: answers,
        isRescreen: widget.isRescreen,
      );

      ref.read(screeningSessionProvider.notifier)
        ..setAnswers(answers)
        ..setResult(result);

      if (!mounted) return;

      if (result.crisisTriggered) {
        context.go('/screening/crisis');
      } else {
        final saved =
            await ref.read(screeningRepositoryProvider).saveResult(result);
        ref.read(screeningSessionProvider.notifier).setResult(saved);
        if (mounted) context.go('/screening/results');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _next() {
    if (_currentPage < _stepCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _stepCount - 1;
    final canProceed = _stepComplete(_currentPage) && !_submitting;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.health_and_safety_outlined,
                          color: AppTheme.lavenderDeep),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LowercaseText(
                          widget.isRescreen
                              ? 'wellbeing check-in'
                              : 'required wellbeing check-in',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      if (!widget.isRescreen) _IntroStep(),
                      InstrumentQuestionStep(
                        instrument: kPgsiInstrument,
                        responses: _pgsi,
                        onResponseChanged: (i, v) =>
                            setState(() => _pgsi[i] = v),
                      ),
                      _MoodAnxietyStep(
                        phq2: _phq2,
                        gad2: _gad2,
                        onPhq2: (i, v) => setState(() => _phq2[i] = v),
                        onGad2: (i, v) => setState(() => _gad2[i] = v),
                      ),
                      InstrumentQuestionStep(
                        instrument: kAuditCInstrument,
                        responses: _auditC,
                        onResponseChanged: (i, v) =>
                            setState(() => _auditC[i] = v),
                        showGenderToggle: true,
                        genderFemale: _genderFemale,
                        onGenderChanged: (v) =>
                            setState(() => _genderFemale = v),
                      ),
                      InstrumentQuestionStep(
                        instrument: kSuicideInstrument,
                        responses: [_suicide],
                        onResponseChanged: (_, v) =>
                            setState(() => _suicide = v),
                      ),
                    ],
                  ),
                ),
                StitchProgress.dots(count: _stepCount, index: _currentPage),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: canProceed ? _next : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : LowercaseText(isLast ? 'finish' : 'next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: TactileCard(
        useStitch: true,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const StampBadge(
              label: 'check-in',
              icon: Icons.favorite_outline,
              size: 96,
              seed: 'check-in',
            ),
            const SizedBox(height: 16),
            const OrnamentalDivider(),
            const SizedBox(height: 16),
            LowercaseText(
              kScreeningIntroTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const LowercaseText(
              kScreeningIntroBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.inkPlumSoft, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lavenderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: AppTheme.lavenderDeep),
                  SizedBox(width: 8),
                  Expanded(
                    child: LowercaseText(
                      kScreeningPrivacyNote,
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const LowercaseText(
              'this takes about 3 minutes. you cannot skip it — it keeps you and others safer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.inkPlumSoft,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodAnxietyStep extends StatelessWidget {
  const _MoodAnxietyStep({
    required this.phq2,
    required this.gad2,
    required this.onPhq2,
    required this.onGad2,
  });

  final List<int?> phq2;
  final List<int?> gad2;
  final void Function(int, int) onPhq2;
  final void Function(int, int) onGad2;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          InstrumentQuestionStep(
            instrument: kPhq2Instrument,
            responses: phq2,
            onResponseChanged: onPhq2,
          ),
          const SizedBox(height: 16),
          InstrumentQuestionStep(
            instrument: kGad2Instrument,
            responses: gad2,
            onResponseChanged: onGad2,
          ),
        ],
      ),
    );
  }
}
