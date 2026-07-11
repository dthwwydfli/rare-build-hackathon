import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/friend_group.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final groupsAsync = ref.watch(_groupsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Friend groups')),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              title: 'No groups yet',
              subtitle: 'Create a group and invite friends with a code',
              action: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => context.push('/groups/new'),
                    child: const Text('Create group'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => context.push('/groups/join'),
                    child: const Text('Join with code'),
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
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(group.name),
                      subtitle: Text('${group.memberIds.length} members'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Invite code: ${group.inviteCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: group.inviteCode),
                              );
                              showAppSnackBar(context, 'Code copied');
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              final shareText =
                                  'Join my accountability group "${group.name}" with code: ${group.inviteCode}';
                              Clipboard.setData(ClipboardData(text: shareText));
                              showAppSnackBar(
                                context,
                                'Invite message copied — paste in Messages or WhatsApp',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => Center(
          child: ErrorBanner(message: 'Could not load groups'),
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
