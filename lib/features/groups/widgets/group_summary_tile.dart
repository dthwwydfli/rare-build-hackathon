import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/friend_group.dart';

String groupSummarySubtitle(FriendGroup group, {int? rank}) {
  return '${group.memberIds.length} walking together${rank != null ? ' · you\'re #$rank' : ''}';
}

class GroupSummaryTile extends StatelessWidget {
  const GroupSummaryTile({
    super.key,
    required this.group,
    this.rank,
    this.onTap,
  });

  final FriendGroup group;
  final int? rank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.group_outlined, color: AppTheme.lavenderDeep),
      title: Text(group.name),
      subtitle: LowercaseText(
        groupSummarySubtitle(group, rank: rank),
        style: const TextStyle(color: AppTheme.inkPlumSoft),
      ),
      onTap: onTap,
    );
  }
}
