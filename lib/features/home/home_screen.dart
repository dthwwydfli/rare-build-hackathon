import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/friend_group.dart';
import '../../domain/models/support_message.dart';
import '../../services/detection/detection_coordinator.dart';
import '../../services/reminders/positive_reminder_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const LoadingView();

    final commitmentsAsync = ref.watch(_userCommitmentsProvider(user.id));
    final groupsAsync = ref.watch(_userGroupsProvider(user.id));
    final supportAsync = ref.watch(_userSupportProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/permissions'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_userCommitmentsProvider(user.id));
          ref.invalidate(_userGroupsProvider(user.id));
          ref.invalidate(_userSupportProvider(user.id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _PositiveReminderCard(),
            const SizedBox(height: 16),
            _FlagForSupportCard(),
            const SizedBox(height: 16),
            _QuickActions(),
            const SizedBox(height: 16),
            commitmentsAsync.when(
              data: (commitments) {
                final groups = groupsAsync.valueOrNull ?? [];
                if (commitments.isNotEmpty && groups.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppTheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add friends so they can support you when commitments are at risk.',
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/groups/new'),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Text('Active commitments',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            commitmentsAsync.when(
              data: (commitments) =>
                  _CommitmentsSummary(commitments: commitments),
              loading: () => const LoadingView(),
              error: (e, _) =>
                  ErrorBanner(message: 'Could not load commitments'),
            ),
            const SizedBox(height: 24),
            Text('Your groups', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            groupsAsync.when(
              data: (groups) => _GroupsSummary(groups: groups),
              loading: () => const LoadingView(),
              error: (e, _) => ErrorBanner(message: 'Could not load groups'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent support',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () => context.push('/my-breaches'),
                  child: const Text('My breaches'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            supportAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Text(
                    'No support messages yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  );
                }
                return Column(
                  children: messages.take(3).map((m) {
                    return AppCard(
                      child: ListTile(
                        leading:
                            const Icon(Icons.favorite, color: AppTheme.danger),
                        title: Text(m.message),
                        subtitle: Text(m.fromUserName ?? 'A friend'),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const LoadingView(),
              error: (e, _) =>
                  ErrorBanner(message: 'Could not load support messages'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dev/simulator'),
        icon: const Icon(Icons.science_outlined),
        label: const Text('Demo breach'),
      ),
    );
  }
}

final _userCommitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
  return ref.watch(commitmentRepositoryProvider).watchUserCommitments(userId);
});

final _userGroupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
});

final _userSupportProvider =
    StreamProvider.family<List<SupportMessage>, String>((ref, userId) {
  return ref.watch(breachRepositoryProvider).watchSupportForUser(userId);
});

class _PositiveReminderCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(currentPositiveReminderProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.9),
            AppTheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Positive reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlagForSupportCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FlagForSupportCard> createState() =>
      _FlagForSupportCardState();
}

class _FlagForSupportCardState extends ConsumerState<_FlagForSupportCard> {
  bool _loading = false;

  Future<void> _flagForSupport() async {
    setState(() => _loading = true);
    try {
      await ref.read(detectionCoordinatorProvider).emitManualBreach(
        signalType: BreachSignalType.manual,
        metadata: {
          'note': 'Flagged for support — reaching out to my circle',
          'selfFlagged': true,
        },
      );
      if (mounted) {
        showAppSnackBar(
          context,
          'Support circle flagged — friends will be alerted',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, '$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.danger.withValues(alpha: 0.12),
          child: const Icon(Icons.flag, color: AppTheme.danger),
        ),
        title: const Text('Flag for support'),
        subtitle: const Text(
          'Struggling right now? Alert your friends without waiting for detection.',
        ),
        trailing: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : FilledButton(
                onPressed: _flagForSupport,
                style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('Flag'),
              ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.flag_outlined,
                label: 'Commitments',
                onTap: () => context.push('/commitments'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.group_outlined,
                label: 'Groups',
                onTap: () => context.push('/groups'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.inbox_outlined,
                label: 'Alerts',
                onTap: () => context.push('/support'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.psychology_alt_outlined,
                label: 'Log urge',
                onTap: () => context.push('/urges'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.person_search_outlined,
                label: 'Find people',
                onTap: () => context.push('/people/find'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _CommitmentsSummary extends StatelessWidget {
  const _CommitmentsSummary({required this.commitments});

  final List<Commitment> commitments;

  @override
  Widget build(BuildContext context) {
    final active = commitments.where((c) => c.active).toList();
    if (active.isEmpty) {
      return EmptyState(
        title: 'No commitments yet',
        subtitle: 'Create your first commitment to get started',
        action: ElevatedButton(
          onPressed: () => context.push('/commitments/new'),
          child: const Text('Create commitment'),
        ),
      );
    }
    return Column(
      children: active.take(3).map((c) {
        return AppCard(
          child: ListTile(
            leading: Icon(_iconForType(c.type)),
            title: Text(c.title),
            subtitle: Text(c.type.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/commitments/${c.id}/edit'),
          ),
        );
      }).toList(),
    );
  }

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
}

class _GroupsSummary extends StatelessWidget {
  const _GroupsSummary({required this.groups});

  final List<FriendGroup> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return EmptyState(
        title: 'No friend groups',
        subtitle: 'Invite trusted friends to support you',
        action: ElevatedButton(
          onPressed: () => context.push('/groups/new'),
          child: const Text('Create group'),
        ),
      );
    }
    return Column(
      children: groups.map((g) {
        return AppCard(
          child: ListTile(
            leading: const Icon(Icons.group),
            title: Text(g.name),
            subtitle:
                Text('${g.memberIds.length} members · Code: ${g.inviteCode}'),
            onTap: () => context.push('/groups'),
          ),
        );
      }).toList(),
    );
  }
}
