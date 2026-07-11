import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text.dart';
import '../../core/widgets/tactile_widgets.dart';
import 'widgets/groups_content.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: const PaperBackground(child: GroupsContent()),
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
