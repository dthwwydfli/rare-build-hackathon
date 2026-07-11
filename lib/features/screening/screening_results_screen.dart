import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/screening_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../data/help_resources_repository.dart';
import '../../domain/models/professional_resource.dart';
import '../../domain/models/screening_result.dart';
import 'widgets/crisis_resource_panel.dart';

class ScreeningResultsScreen extends ConsumerWidget {
  const ScreeningResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(screeningSessionProvider).result;
    final isRescreen = ref.watch(screeningSessionProvider).isRescreen;

    if (result == null) {
      return const Scaffold(body: ErrorBanner(message: 'no screening results'));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const StampBadge(
                        label: 'results',
                        icon: Icons.assignment_outlined,
                        size: 72,
                        seed: 'results',
                      ),
                      const SizedBox(height: 16),
                      LowercaseText(
                        'your check-in summary',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const LowercaseText(
                        'this is not a diagnosis — it helps us suggest support that may help.',
                        style: TextStyle(color: AppTheme.inkPlumSoft, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      _DomainSummary(
                        title: 'gambling',
                        value: result.pgsiBand.label,
                        detail: 'PGSI score: ${result.pgsiScore}',
                      ),
                      _DomainSummary(
                        title: 'mood',
                        value: result.phq2Score >= 3
                            ? 'elevated — consider support'
                            : 'no significant concern',
                        detail: 'PHQ-2 score: ${result.phq2Score}',
                      ),
                      _DomainSummary(
                        title: 'anxiety',
                        value: result.gad2Score >= 3
                            ? 'elevated — consider support'
                            : 'no significant concern',
                        detail: 'GAD-2 score: ${result.gad2Score}',
                      ),
                      _DomainSummary(
                        title: 'alcohol',
                        value: result.auditCScore >= 3
                            ? 'worth discussing with support'
                            : 'no significant concern',
                        detail: 'AUDIT-C score: ${result.auditCScore}',
                      ),
                      if (result.crisisTriggered) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.granola.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const LowercaseText(
                            'you indicated thoughts of self-harm — please use the helplines below if you need support.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const LowercaseText(
                        'recommended next steps',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _ReferralList(referrals: result.referrals),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(screeningSessionProvider.notifier).clear();
                      if (isRescreen) {
                        context.go('/home');
                      } else {
                        context.go('/permissions');
                      }
                    },
                    child: LowercaseText(
                      isRescreen ? 'back to home' : 'continue to app',
                    ),
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

class _DomainSummary extends StatelessWidget {
  const _DomainSummary({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LowercaseText(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.lavenderDeep,
              ),
            ),
            const SizedBox(height: 4),
            LowercaseText(value),
            const SizedBox(height: 2),
            LowercaseText(
              detail,
              style: const TextStyle(fontSize: 12, color: AppTheme.inkPlumSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralList extends ConsumerWidget {
  const _ReferralList({required this.referrals});

  final List<ScreeningReferral> referrals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (referrals.isEmpty) {
      return const AppCard(
        child: LowercaseText(
          'no urgent referrals flagged — keep using the app and reach out if things change.',
          style: TextStyle(height: 1.4),
        ),
      );
    }

    final resourcesAsync = ref.watch(helpResourcesProvider);

    return resourcesAsync.when(
      data: (all) {
        final seen = <String>{};
        return Column(
          children: [
            for (final referral in referrals) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LowercaseText(
                      referral.summary,
                      style: const TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    for (final id in referral.resourceIds) ...[
                      if (seen.add(id))
                        _ResourceAction(
                          resource: all.where((r) => r.id == id).firstOrNull,
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) =>
          const CrisisResourcePanel(resourceIds: CrisisResourcePanel.defaultCrisisIds),
    );
  }
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction({required this.resource});

  final ProfessionalResource? resource;

  @override
  Widget build(BuildContext context) {
    if (resource == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              resource!.name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          if (resource!.phone != null)
            TextButton(
              onPressed: () =>
                  launchHelplinePhone(context, resource!.phone!),
              child: const LowercaseText('call'),
            ),
          if (resource!.url != null)
            TextButton(
              onPressed: () => launchHelplineUrl(context, resource!.url!),
              child: const LowercaseText('website'),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
