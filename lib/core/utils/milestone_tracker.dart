import 'package:shared_preferences/shared_preferences.dart';

class MilestoneTracker {
  static const _prefix = 'milestone_seen_';

  static Future<bool> shouldShow(String milestoneId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_prefix$milestoneId') ?? false);
  }

  static Future<void> markSeen(String milestoneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$milestoneId', true);
  }

  static Future<void> checkAndNotify({
    required int points,
    required int currentStreak,
    required void Function(String message) onMilestone,
  }) async {
    if (currentStreak >= 7 && await shouldShow('streak_7')) {
      await markSeen('streak_7');
      onMilestone('7 day streak and you\'re on fire');
    }
    if (currentStreak >= 30 && await shouldShow('streak_30')) {
      await markSeen('streak_30');
      onMilestone('30 days and incredible discipline');
    }
    if (points >= 1100 && await shouldShow('points_1100')) {
      await markSeen('points_1100');
      onMilestone('you\'ve reached 1100 points');
    }
    if (points >= 1200 && await shouldShow('points_1200')) {
      await markSeen('points_1200');
      onMilestone('master tier and 1200 points');
    }
  }
}
