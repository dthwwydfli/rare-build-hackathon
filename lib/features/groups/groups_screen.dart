import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/friend_group.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final groupsAsync = ref.watch(_groupsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const LowercaseText('groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            onPressed: () => context.push('/people/find'),
            tooltip: 'Find people',
          ),
        ],
      ),
      body: PaperBackground(
        child: groupsAsync.when(
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
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
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
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.group_outlined,
                            color: AppTheme.lavenderDeep),
                        title: Text(group.name),
                        subtitle: LowercaseText(
                          '${group.memberIds.length} walking together${rank != null ? ' · you\'re #$rank' : ''}',
                          style:
                              const TextStyle(color: AppTheme.inkPlumSoft),
                        ),
                      ),
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
                            'invite message copied — paste in messages or whatsapp',
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
        error: (e, _) => const Center(
          child: ErrorBanner(message: 'could not load groups'),
        ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join',
            onPressed: () => context.push('/groups/join'),
            child: const Icon(Icons.login),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.push('/groups/new'),
            child: const Icon(Icons.add),
          ),
        ],
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
