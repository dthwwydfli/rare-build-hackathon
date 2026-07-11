import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../gamification/widgets/leaderboard_content.dart';
import '../groups/widgets/groups_content.dart';
import '../help/professionals_screen.dart';

enum SupportHubSegment { people, rankings, help }

SupportHubSegment supportHubSegmentFromQuery(String? value) {
  return switch (value) {
    'rankings' => SupportHubSegment.rankings,
    'help' => SupportHubSegment.help,
    _ => SupportHubSegment.people,
  };
}

String supportHubSegmentQuery(SupportHubSegment segment) {
  return switch (segment) {
    SupportHubSegment.people => 'people',
    SupportHubSegment.rankings => 'rankings',
    SupportHubSegment.help => 'help',
  };
}

class SupportHubScreen extends ConsumerStatefulWidget {
  const SupportHubScreen({super.key, this.initialSegment = SupportHubSegment.people});

  final SupportHubSegment initialSegment;

  @override
  ConsumerState<SupportHubScreen> createState() => _SupportHubScreenState();
}

class _SupportHubScreenState extends ConsumerState<SupportHubScreen> {
  late SupportHubSegment _segment;

  @override
  void initState() {
    super.initState();
    _segment = widget.initialSegment;
  }

  @override
  void didUpdateWidget(SupportHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSegment != widget.initialSegment) {
      _segment = widget.initialSegment;
    }
  }

  void _selectSegment(SupportHubSegment segment) {
    setState(() => _segment = segment);
    context.go('/support-hub?segment=${supportHubSegmentQuery(segment)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LowercaseText('support'),
        actions: [
          if (_segment == SupportHubSegment.people)
            IconButton(
              icon: const Icon(Icons.person_search_outlined),
              onPressed: () => context.push('/people/find'),
              tooltip: 'Find people',
            ),
        ],
      ),
      body: PaperBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SegmentedButton<SupportHubSegment>(
                segments: const [
                  ButtonSegment(
                    value: SupportHubSegment.people,
                    label: LowercaseText('people'),
                    icon: Icon(Icons.group_outlined),
                  ),
                  ButtonSegment(
                    value: SupportHubSegment.rankings,
                    label: LowercaseText('rankings'),
                    icon: Icon(Icons.leaderboard_outlined),
                  ),
                  ButtonSegment(
                    value: SupportHubSegment.help,
                    label: LowercaseText('get help'),
                    icon: Icon(Icons.medical_services_outlined),
                  ),
                ],
                selected: {_segment},
                onSelectionChanged: (selection) =>
                    _selectSegment(selection.first),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _segment.index,
                children: const [
                  GroupsContent(),
                  LeaderboardContent(),
                  GetHelpContent(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _segment == SupportHubSegment.people
          ? Column(
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
            )
          : null,
    );
  }
}
