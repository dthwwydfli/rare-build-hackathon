import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/repository_providers.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/craft_widgets.dart';
import '../../../domain/models/app_user.dart';
import '../../../domain/models/friend_group.dart';
import 'group_summary_tile.dart';

class GroupsContent extends ConsumerWidget {
  const GroupsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const LoadingView();

    final groupsAsync = ref.watch(userGroupsProvider(user.id));

    return groupsAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return EmptyState(
            title: 'no groups yet',
            subtitle: 'create a group and invite friends with a code',
            action: Column(
              children: [
                ElevatedButton(
                  onPressed: () => context.push('/groups/new'),
                  child: const LowercaseText('create group'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/groups/join'),
                  child: const LowercaseText('join with code'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push('/people/find'),
                  child: const Text('Find people'),
                ),
              ],
            ),
          );
        }
        final memberCount = groups.fold<int>(
          0,
          (total, group) => total + group.memberIds.length,
        );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppTheme.lavenderLight,
                        child: Icon(
                          Icons.diversity_3,
                          color: AppTheme.lavenderDeep,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LowercaseText(
                              '${groups.length} support circles nearby',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            LowercaseText(
                              '$memberCount friend seats filled in demo mode',
                              style: const TextStyle(
                                color: AppTheme.inkPlumSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final group = groups[index - 1];
            final coverAsset = _coverAssetFor(group);
            final rankAsync = ref.watch(groupLeaderboardProvider(group.id));
            final rank = rankAsync.valueOrNull
                ?.where((e) => e.userId == user.id)
                .map((e) => e.rank)
                .firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        coverAsset,
                        height: 104,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GroupSummaryTile(group: group, rank: rank),
                    _GroupMemberPreview(group: group),
                    const SizedBox(height: 12),
                    TicketStub(
                      code: group.inviteCode,
                      onCopy: () {
                        Clipboard.setData(
                          ClipboardData(text: group.inviteCode),
                        );
                        showAppSnackBar(context, 'code copied');
                      },
                      onShare: () {
                        final shareText =
                            'Join my lavender group "${group.name}" with code: ${group.inviteCode}';
                        Clipboard.setData(ClipboardData(text: shareText));
                        showAppSnackBar(
                          context,
                          'invite message copied so paste in messages or whatsapp',
                        );
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
      error: (e, _) =>
          const Center(child: ErrorBanner(message: 'could not load groups')),
    );
  }
}

String _coverAssetFor(FriendGroup group) {
  final coverAsset = group.coverAsset;
  if (coverAsset != null && coverAsset.isNotEmpty) return coverAsset;

  final key = '${group.id} ${group.name}'.toLowerCase();
  if (key.contains('payday')) {
    return 'assets/images/community/payday-plan.png';
  }
  if (key.contains('match') || key.contains('bet')) {
    return 'assets/images/community/matchday.png';
  }
  return 'assets/images/community/weekend-reset.png';
}

class _GroupMemberPreview extends ConsumerWidget {
  const _GroupMemberPreview({required this.group});

  final FriendGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<AppUser>>(
      future: Future.wait(
        group.memberIds.map((id) async {
          final user = await ref.read(userRepositoryProvider).getUser(id);
          return user ??
              AppUser(
                id: id,
                displayName: 'Friend',
                email: '',
                createdAt: DateTime.now(),
              );
        }),
      ),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: LowercaseText(
              'loading members...',
              style: TextStyle(color: AppTheme.inkPlumSoft),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              CommunityAvatarStack(users: users),
              const SizedBox(width: 12),
              Expanded(
                child: LowercaseText(
                  users.map((u) => u.displayName.split(' ').first).join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.inkPlumSoft),
                ),
              ),
            ],
          ),
        );
      },
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
