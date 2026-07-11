import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../core/utils/commitment_ui.dart';
import '../../domain/models/enums.dart';

class CommitmentsScreen extends ConsumerWidget {
  const CommitmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final commitmentsAsync = ref.watch(_commitmentsProvider(user.id));
    final statsAsync = ref.watch(userStatsProvider(user.id));
    final streak = statsAsync.valueOrNull?.currentStreak ?? 0;

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('goals')),
      body: PaperBackground(
        child: commitmentsAsync.when(
          data: (commitments) {
            if (commitments.isEmpty) {
              return EmptyState(
                title: 'write your first commitment',
                subtitle:
                    'a signed promise to yourself — we\'ll help you keep it',
                action: ElevatedButton(
                  onPressed: () => context.push('/commitments/new'),
                  child: const LowercaseText('create goal'),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: commitments.length,
              itemBuilder: (context, index) {
                final c = commitments[index];
                final card = Padding(
                  padding: const EdgeInsets.only(bottom: 16, top: 8),
                  child: ContractCard(
                    title: c.title,
                    signedBy: user.displayName,
                    faded: !c.active,
                    stamp: c.active
                        ? const StampBadge.active(size: 52)
                        : null,
                    onTap: () => context.push('/commitments/${c.id}/edit'),
                    child: Row(
                      children: [
                        PatchChip(
                          label: c.active
                              ? c.type.label
                              : '${c.type.label} · paused',
                          icon: commitmentIcon(c.type),
                        ),
                        if (c.active && streak > 0) ...[
                          const SizedBox(width: 8),
                          StreakFlame(streak: streak),
                        ],
                        const Spacer(),
                        Switch(
                          value: c.active,
                          onChanged: (active) async {
                            try {
                              await ref
                                  .read(commitmentRepositoryProvider)
                                  .updateCommitment(
                                    Commitment(
                                      id: c.id,
                                      userId: c.userId,
                                      title: c.title,
                                      type: c.type,
                                      rules: c.rules,
                                      active: active,
                                      createdAt: c.createdAt,
                                    ),
                                  );
                            } catch (e) {
                              if (context.mounted) {
                                showAppSnackBar(
                                    context, 'could not update goal');
                              }
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.inkPlumSoft),
                          constraints: const BoxConstraints(
                              minWidth: 44, minHeight: 44),
                          onPressed: () async {
                            final confirmed = await showConfirmDialog(
                              context,
                              title: 'delete goal',
                              message:
                                  'delete "${c.title}"? this cannot be undone.',
                              confirmLabel: 'delete',
                            );
                            if (!confirmed || !context.mounted) return;
                            try {
                              await ref
                                  .read(commitmentRepositoryProvider)
                                  .deleteCommitment(c.id);
                              if (context.mounted) {
                                showAppSnackBar(context, 'goal deleted');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showAppSnackBar(
                                    context, 'could not delete goal');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
                return index < 8 ? [card].staggered(context).first : card;
              },
            );
          },
          loading: () => const LoadingView(),
          error: (e, _) =>
              const Center(child: ErrorBanner(message: 'could not load goals')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/commitments/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

final _commitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
  return ref.watch(commitmentRepositoryProvider).watchUserCommitments(userId);
});

