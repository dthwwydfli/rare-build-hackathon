import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text.dart';
import 'widgets/crisis_resource_panel.dart';

void showRescreenDueDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const LowercaseText('time for a check-in'),
      content: const LowercaseText(
        'it has been a while since your last wellbeing screen. '
        'a quick check-in helps us keep you pointed at the right support.',
        style: TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const LowercaseText('later'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/screening?mode=rescreen');
          },
          child: const LowercaseText('start check-in'),
        ),
      ],
    ),
  );
}

void showHelplineSupportSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LowercaseText(
            'friends alerted — or talk to someone now',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          LowercaseText(
            'your circle has been notified. you can also reach trained helplines 24/7.',
            style: TextStyle(height: 1.4),
          ),
          SizedBox(height: 16),
          CrisisResourcePanel(compact: true),
        ],
      ),
    ),
  );
}
