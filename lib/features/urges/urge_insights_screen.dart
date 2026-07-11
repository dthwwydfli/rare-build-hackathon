import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/access_block_settings.dart';
import '../../domain/models/urge_log.dart';
import '../../services/urges/coping_prompt_service.dart';
import '../../services/urges/urge_pattern_analyzer.dart';

class UrgeInsightsScreen extends ConsumerWidget {
  const UrgeInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final urgesAsync = ref.watch(_urgesProvider(user.id));
    final blocksAsync = ref.watch(_blockSettingsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Urge patterns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/urges/log'),
            tooltip: 'Log urge',
          ),
        ],
      ),
      body: urgesAsync.when(
        data: (urges) {
          final analyzer = UrgePatternAnalyzer();
          final insights = analyzer.analyze(urges);
          final riskyNow = analyzer.isRiskyMoment(urges);
          final coping = CopingPromptService().promptForUrge(riskyMoment: riskyNow);

          final blocks = blocksAsync.valueOrNull;
          final blockPrompt = blocks != null
              ? CopingPromptService().promptForBlocksIncomplete(
                  blocks.activeBlockCount,
                  5,
                )
              : null;

          if (urges.isEmpty) {
            return EmptyState(
              title: 'No urges logged yet',
              subtitle:
                  'Log your first urge to spot triggers and get coping prompts at risky moments.',
              action: ElevatedButton(
                onPressed: () => context.push('/urges/log'),
                child: const Text('Log an urge'),
              ),
            );
          }

          final resisted = urges.where((u) => u.resisted).length;
          final resistRate = (resisted / urges.length * 100).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (riskyNow) ...[
                _CopingCard(prompt: coping, highlight: true),
                const SizedBox(height: 16),
              ],
              if (blockPrompt != null && blocks!.activeBlockCount < 3) ...[
                _CopingCard(prompt: blockPrompt),
                const SizedBox(height: 16),
              ],
              Card(
                color: AppTheme.accent,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$resistRate% urges resisted',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${urges.length} logged and confidence builds with each one',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Patterns spotted', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...insights.map((i) => _InsightCard(insight: i)),
              const SizedBox(height: 24),
              Text('Recent logs', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...urges.take(10).map((u) => AppCard(
                    child: ListTile(
                      leading: Icon(
                        u.resisted ? Icons.check_circle : Icons.warning_amber,
                        color: u.resisted ? Colors.green : AppTheme.danger,
                      ),
                      title: Text(
                        '${u.trigger.label} · intensity ${u.intensity}/10',
                      ),
                      subtitle: Text(
                        '${u.mood.label}'
                        '${u.location != null ? ' · ${u.location}' : ''}'
                        '${u.moneyOnHand != null ? ' · £${u.moneyOnHand!.toStringAsFixed(0)}' : ''}'
                        ' · ${DateFormat.MMMd().add_jm().format(u.createdAt)}',
                      ),
                    ),
                  )),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorBanner(message: 'Could not load urge history'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/urges/log'),
        icon: const Icon(Icons.edit_note),
        label: const Text('Log urge'),
      ),
    );
  }
}

class _CopingCard extends StatelessWidget {
  const _CopingCard({required this.prompt, this.highlight = false});

  final CopingPrompt prompt;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.danger.withValues(alpha: 0.08)
            : AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight
              ? AppTheme.danger.withValues(alpha: 0.3)
              : AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                highlight ? Icons.warning_amber : Icons.psychology_outlined,
                color: highlight ? AppTheme.danger : AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                prompt.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(prompt.message),
          const SizedBox(height: 8),
          Chip(
            label: Text(prompt.technique),
            backgroundColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final UrgePatternInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = switch (insight.riskLevel) {
      'high' => AppTheme.danger,
      'medium' => AppTheme.granolaDark,
      _ => AppTheme.primary,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: ListTile(
          leading: Icon(Icons.insights, color: color),
          title: Text(insight.title),
          subtitle: Text(insight.detail),
        ),
      ),
    );
  }
}

final _urgesProvider =
    StreamProvider.family<List<UrgeLog>, String>((ref, userId) {
  return ref.watch(urgeRepositoryProvider).watchUserUrges(userId);
});

final _blockSettingsProvider =
    StreamProvider.family<AccessBlockSettings, String>((ref, userId) {
  return ref.watch(accessBlockRepositoryProvider).watchSettings(userId);
});
