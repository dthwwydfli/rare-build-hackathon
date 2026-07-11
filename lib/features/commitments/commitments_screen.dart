import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Commitments')),
      body: commitmentsAsync.when(
        data: (commitments) {
          if (commitments.isEmpty) {
            return EmptyState(
              title: 'No commitments',
              subtitle: 'Set goals to avoid gambling triggers',
              action: ElevatedButton(
                onPressed: () => context.push('/commitments/new'),
                child: const Text('Create commitment'),
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
                  subtitle: Text('${c.type.label} · ${c.active ? "Active" : "Paused"}'),
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
                              showAppSnackBar(
                                context,
                                'Could not update commitment',
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Delete commitment',
                            message: 'Delete "${c.title}"? This cannot be undone.',
                            confirmLabel: 'Delete',
                          );
                          if (!confirmed || !context.mounted) return;
                          try {
                            await ref
                                .read(commitmentRepositoryProvider)
                                .deleteCommitment(c.id);
                            if (context.mounted) {
                              showAppSnackBar(context, 'Commitment deleted');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              showAppSnackBar(
                                context,
                                'Could not delete commitment',
                              );
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
        error: (e, _) => Center(child: ErrorBanner(message: 'Could not load commitments')),
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
