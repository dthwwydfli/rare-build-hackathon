import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/commitment.dart';
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
      body: commitmentsAsync.when(
        data: (commitments) {
          if (commitments.isEmpty) {
            return EmptyState(
              title: 'no goals yet',
              subtitle: 'set goals to avoid gambling triggers',
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
              return AppCard(
                child: ListTile(
                  leading: Icon(_iconForType(c.type)),
                  title: Text(c.title),
                  subtitle: Row(
                    children: [
                      LowercaseText('${c.type.label} · ${c.active ? "active" : "paused"}'),
                      if (c.active && streak > 0) ...[
                        const SizedBox(width: 8),
                        StreakFlame(streak: streak),
                      ],
                    ],
                  ),
                  onTap: () => context.push('/commitments/${c.id}/edit'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                              showAppSnackBar(context, 'could not update goal');
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'delete goal',
                            message: 'delete "${c.title}"? this cannot be undone.',
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
                              showAppSnackBar(context, 'could not delete goal');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => const Center(child: ErrorBanner(message: 'could not load goals')),
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

IconData _iconForType(CommitmentType type) {
  switch (type) {
    case CommitmentType.location:
      return Icons.location_on_outlined;
    case CommitmentType.spending:
      return Icons.payments_outlined;
    case CommitmentType.online:
      return Icons.phone_android_outlined;
  }
}
