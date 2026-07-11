import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/screening_result.dart';

const _screeningCompletedKey = 'screening_completed';
const _lastScreeningAtKey = 'last_screening_at';
const _nextScreeningDueAtKey = 'next_screening_due_at';
const _activeReferralFlagsKey = 'active_referral_flags';
const _lastRescreenPromptAtKey = 'last_rescreen_prompt_at';

String _userKey(String userId, String suffix) => '${userId}_$suffix';

Future<ScreeningStatus> getLocalScreeningStatus(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final completed = prefs.getBool(_userKey(userId, _screeningCompletedKey)) ??
      false;
  final lastMs = prefs.getInt(_userKey(userId, _lastScreeningAtKey));
  final dueMs = prefs.getInt(_userKey(userId, _nextScreeningDueAtKey));
  final flags =
      prefs.getStringList(_userKey(userId, _activeReferralFlagsKey)) ?? [];

  return ScreeningStatus(
    screeningCompleted: completed,
    lastScreeningAt:
        lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null,
    nextScreeningDueAt:
        dueMs != null ? DateTime.fromMillisecondsSinceEpoch(dueMs) : null,
    activeReferralFlags: flags,
  );
}

Future<void> saveLocalScreeningStatus({
  required String userId,
  required ScreeningStatus status,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(
    _userKey(userId, _screeningCompletedKey),
    status.screeningCompleted,
  );
  if (status.lastScreeningAt != null) {
    await prefs.setInt(
      _userKey(userId, _lastScreeningAtKey),
      status.lastScreeningAt!.millisecondsSinceEpoch,
    );
  }
  if (status.nextScreeningDueAt != null) {
    await prefs.setInt(
      _userKey(userId, _nextScreeningDueAtKey),
      status.nextScreeningDueAt!.millisecondsSinceEpoch,
    );
  }
  await prefs.setStringList(
    _userKey(userId, _activeReferralFlagsKey),
    status.activeReferralFlags,
  );
}

Future<void> clearLocalScreeningStatus(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_userKey(userId, _screeningCompletedKey));
  await prefs.remove(_userKey(userId, _lastScreeningAtKey));
  await prefs.remove(_userKey(userId, _nextScreeningDueAtKey));
  await prefs.remove(_userKey(userId, _activeReferralFlagsKey));
  await prefs.remove(_userKey(userId, _lastRescreenPromptAtKey));
}

Future<DateTime?> getLastRescreenPromptAt(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final ms = prefs.getInt(_userKey(userId, _lastRescreenPromptAtKey));
  return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
}

Future<void> markRescreenPromptShown(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    _userKey(userId, _lastRescreenPromptAtKey),
    DateTime.now().millisecondsSinceEpoch,
  );
}

/// Returns true if overdue and we have not prompted in the last 24 hours.
Future<bool> shouldShowRescreenPrompt({
  required String userId,
  required ScreeningStatus status,
}) async {
  if (!status.screeningCompleted || !status.isOverdue) return false;
  final lastPrompt = await getLastRescreenPromptAt(userId);
  if (lastPrompt == null) return true;
  return DateTime.now().difference(lastPrompt) > const Duration(hours: 24);
}
