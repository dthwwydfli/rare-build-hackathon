import 'package:flutter/foundation.dart';

import '../../core/utils/screening_prefs.dart';
import '../../domain/models/screening_result.dart';

/// Tracks periodic re-screening due dates and in-app reminder eligibility.
class ScreeningReminderService {
  const ScreeningReminderService();

  static const reminderTitle = 'wellbeing check-in due';
  static const reminderBody =
      'your periodic wellbeing screen is due — tap to complete your check-in.';

  Future<bool> isRescreenDue(String userId, ScreeningStatus status) async {
    if (!status.screeningCompleted) return false;
    return status.isOverdue;
  }

  Future<bool> shouldPromptInApp({
    required String userId,
    required ScreeningStatus status,
  }) {
    return shouldShowRescreenPrompt(userId: userId, status: status);
  }

  /// Hook for future FCM/local notification integration.
  Future<void> scheduleDueReminderIfNeeded({
    required String userId,
    required ScreeningStatus status,
  }) async {
    if (!status.isOverdue) return;
    debugPrint(
      '$reminderTitle — $reminderBody (user: $userId, due: ${status.nextScreeningDueAt})',
    );
  }
}
