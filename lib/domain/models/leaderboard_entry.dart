class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.points,
    required this.currentStreak,
    required this.rank,
  });

  final String userId;
  final String displayName;
  final int points;
  final int currentStreak;
  final int rank;
}
