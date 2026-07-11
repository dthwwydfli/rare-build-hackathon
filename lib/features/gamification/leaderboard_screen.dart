import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/friend_group.dart';
import '../../domain/models/leaderboard_entry.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  bool _global = false;
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final groupsAsync = ref.watch(_groupsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const LowercaseText('rank')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: LowercaseText('my groups')),
                ButtonSegment(value: true, label: LowercaseText('global')),
              ],
              selected: {_global},
              onSelectionChanged: (s) => setState(() => _global = s.first),
            ),
          ),
          Expanded(
            child: _global
                ? _GlobalLeaderboard(currentUserId: user.id)
                : groupsAsync.when(
                    data: (groups) => _GroupLeaderboard(
                      groups: groups,
                      currentUserId: user.id,
                      selectedGroupId: _selectedGroupId,
                      onGroupSelected: (id) =>
                          setState(() => _selectedGroupId = id),
                    ),
                    loading: () => const LoadingView(),
                    error: (_, __) => const ErrorBanner(
                      message: 'could not load groups',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GlobalLeaderboard extends ConsumerWidget {
  const _GlobalLeaderboard({required this.currentUserId});

  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);

    return leaderboardAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            title: 'no rankings yet',
            subtitle: 'be among the first ranked',
          );
        }
        final myEntry = entries.where((e) => e.userId == currentUserId).firstOrNull;
        return Column(
          children: [
            Expanded(child: _LeaderboardList(entries: entries, highlightUserId: currentUserId)),
            if (myEntry != null)
              _YourRankFooter(
                rank: myEntry.rank,
                total: entries.length,
              ),
          ],
        );
      },
      loading: () => const LoadingView(),
      error: (_, __) => const ErrorBanner(message: 'could not load global leaderboard'),
    );
  }
}

class _GroupLeaderboard extends ConsumerWidget {
  const _GroupLeaderboard({
    required this.groups,
    required this.currentUserId,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  final List<FriendGroup> groups;
  final String currentUserId;
  final String? selectedGroupId;
  final ValueChanged<String> onGroupSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groups.isEmpty) {
      return const EmptyState(
        title: 'no groups yet',
        subtitle: 'join a group to compete with friends',
      );
    }

    final groupId = selectedGroupId ?? groups.first.id;
    final leaderboardAsync = ref.watch(groupLeaderboardProvider(groupId));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            value: groupId,
            decoration: const InputDecoration(labelText: 'group'),
            items: groups
                .map((g) => DropdownMenuItem(value: g.id, child: Text(g.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) onGroupSelected(v);
            },
          ),
        ),
        Expanded(
          child: leaderboardAsync.when(
            data: (entries) {
              if (entries.length <= 1) {
                return const EmptyState(
                  title: 'invite friends to compete',
                  subtitle: 'leaderboards need at least two members',
                );
              }
              final myEntry =
                  entries.where((e) => e.userId == currentUserId).firstOrNull;
              return Column(
                children: [
                  PodiumRow(
                    entries: entries
                        .take(3)
                        .map((e) => (name: e.displayName, points: e.points, rank: e.rank))
                        .toList(),
                  ),
                  Expanded(
                    child: _LeaderboardList(
                      entries: entries,
                      highlightUserId: currentUserId,
                    ),
                  ),
                  if (myEntry != null && myEntry.rank > 3)
                    _YourRankFooter(rank: myEntry.rank, total: entries.length),
                ],
              );
            },
            loading: () => const LoadingView(),
            error: (_, __) =>
                const ErrorBanner(message: 'could not load group leaderboard'),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.entries,
    required this.highlightUserId,
  });

  final List<LeaderboardEntry> entries;
  final String highlightUserId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final isMe = entry.userId == highlightUserId;
        return AppCard(
          color: isMe ? AppTheme.lavenderLight : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              RankBadge(rank: entry.rank),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.displayName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    LowercaseText(
                      '${pointsTierLabel(entry.points)} · ${entry.currentStreak} day streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.granolaDark.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.points}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.granola,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _YourRankFooter extends StatelessWidget {
  const _YourRankFooter({required this.rank, required this.total});

  final int rank;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.granola,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: LowercaseText(
        'you\'re #$rank of $total',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

final _groupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
});

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
