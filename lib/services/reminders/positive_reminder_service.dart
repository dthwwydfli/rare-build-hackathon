import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rotating positive encouragement shown on the home screen.
class PositiveReminderService {
  static const _messages = [
    'One day at a time — you are stronger than the urge.',
    'Your support circle believes in you. Reach out if you need them.',
    'Every hour without gambling is a win. Keep going.',
    'Cravings pass. You do not have to act on them.',
    'You chose accountability for a reason. That choice still matters.',
    'Small steps add up. Today is another step forward.',
    'You are not alone — your friends are here for you.',
    'Progress is not perfect. Showing up still counts.',
  ];

  String reminderForNow([DateTime? now]) {
    final time = now ?? DateTime.now();
    final index = (time.day * 24 + time.hour) % _messages.length;
    return _messages[index];
  }
}

final positiveReminderProvider = Provider<PositiveReminderService>((ref) {
  return PositiveReminderService();
});

final currentPositiveReminderProvider = Provider<String>((ref) {
  return ref.watch(positiveReminderProvider).reminderForNow();
});
