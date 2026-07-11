import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text.dart';
import '../../core/widgets/tactile_widgets.dart';
import 'widgets/leaderboard_content.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const LowercaseText('your circle')),
      body: const PaperBackground(child: LeaderboardContent()),
    );
  }
}
