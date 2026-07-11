import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/app_user.dart';
import '../../domain/models/friend_group.dart';

class FindPeopleScreen extends ConsumerStatefulWidget {
  const FindPeopleScreen({super.key});

  @override
  ConsumerState<FindPeopleScreen> createState() => _FindPeopleScreenState();
}

class _FindPeopleScreenState extends ConsumerState<FindPeopleScreen> {
  final _searchController = TextEditingController();
  List<AppUser> _results = [];
  List<AppUser> _suggested = [];
  bool _searching = false;
  bool _loadingSuggested = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSuggested());
  }

  Future<void> _loadSuggested() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    final suggested = await ref
        .read(userRepositoryProvider)
        .suggestedUsers(excludeUserId: user.id, limit: 8);
    if (!mounted) return;
    setState(() {
      _suggested = suggested;
      _loadingSuggested = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = [];
        _error = 'Type at least 2 characters';
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final results = await ref
          .read(userRepositoryProvider)
          .searchUsers(query: query, excludeUserId: user.id);
      setState(() => _results = results);
    } catch (e) {
      setState(() => _error = 'Search failed');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _inviteToGroup(AppUser person) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final groups = await ref
        .read(groupRepositoryProvider)
        .watchUserGroups(user.id)
        .first;
    if (!mounted) return;

    if (groups.isEmpty) {
      showAppSnackBar(context, 'Create a group first');
      context.push('/groups/new');
      return;
    }

    final group = groups.length == 1
        ? groups.first
        : await showModalBottomSheet<FriendGroup>(
            context: context,
            builder: (context) => _GroupPickerSheet(groups: groups),
          );
    if (group == null || !mounted) return;

    try {
      await ref
          .read(groupRepositoryProvider)
          .addMemberToGroup(groupId: group.id, userId: person.id);
      if (mounted) {
        showAppSnackBar(
          context,
          'Added ${person.displayName} to ${group.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Could not add to group');
      }
    }
  }

  Widget _personCard(AppUser person) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: ListTile(
          leading: CommunityAvatar(user: person, radius: 24),
          title: Text(person.displayName),
          subtitle: Text(person.bio ?? person.email),
          trailing: OutlinedButton(
            onPressed: () => _inviteToGroup(person),
            child: const Text('Add'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find people')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Search for friends on the app and add them to your support circle.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by name or email',
              hintText: 'Sam, jordan@test.com...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _searching ? null : _search,
              ),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 24),
          if (_searching)
            const Center(child: CircularProgressIndicator())
          else if (_results.isEmpty && _searchController.text.length >= 2)
            Text(
              'No people found',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else if (_results.isNotEmpty) ...[
            Text(
              'Search results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._results.map(_personCard),
          ] else ...[
            Text(
              'Suggested friends',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'A few supportive people are already around in demo mode.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            if (_loadingSuggested)
              const Center(child: CircularProgressIndicator())
            else
              ..._suggested.map(_personCard),
          ],
        ],
      ),
    );
  }
}

class _GroupPickerSheet extends StatelessWidget {
  const _GroupPickerSheet({required this.groups});

  final List<FriendGroup> groups;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Choose a group',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...groups.map((g) {
            return ListTile(
              title: Text(g.name),
              subtitle: Text('${g.memberIds.length} members'),
              onTap: () => Navigator.pop(context, g),
            );
          }),
        ],
      ),
    );
  }
}
