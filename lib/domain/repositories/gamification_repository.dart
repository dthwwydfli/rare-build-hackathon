import '../models/app_user.dart';
import '../models/leaderboard_entry.dart';

abstract class GamificationRepository {
  Stream<AppUser> watchUserStats(String userId);
  Stream<List<LeaderboardEntry>> watchGroupLeaderboard(String groupId);
  Stream<List<LeaderboardEntry>> watchGlobalLeaderboard({int limit = 50});
  Future<void> applySupportBonus(String userId);
  Future<void> applyBreachPenalty(String userId, {int severity = 1});
}
