import '../../domain/models/enums.dart';
import '../../domain/models/urge_log.dart';

class UrgePatternAnalyzer {
  List<UrgePatternInsight> analyze(List<UrgeLog> urges) {
    if (urges.isEmpty) return [];

    final insights = <UrgePatternInsight>[];

    final triggerCounts = <UrgeTrigger, int>{};
    final moodCounts = <UrgeMood, int>{};
    final hourCounts = <int, int>{};
    var highMoneyUrges = 0;
    var resistedCount = 0;

    for (final urge in urges) {
      triggerCounts[urge.trigger] = (triggerCounts[urge.trigger] ?? 0) + 1;
      moodCounts[urge.mood] = (moodCounts[urge.mood] ?? 0) + 1;
      final hour = urge.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      if ((urge.moneyOnHand ?? 0) >= 50) highMoneyUrges++;
      if (urge.resisted) resistedCount++;
    }

    final topTrigger = _topEntry(triggerCounts);
    if (topTrigger != null) {
      insights.add(UrgePatternInsight(
        title: 'Top trigger: ${topTrigger.key.label}',
        detail:
            '${topTrigger.value} of ${urges.length} urges linked to this trigger.',
        riskLevel: topTrigger.value >= urges.length ~/ 2 ? 'high' : 'medium',
      ));
    }

    final topMood = _topEntry(moodCounts);
    if (topMood != null && topMood.key != UrgeMood.calm) {
      insights.add(UrgePatternInsight(
        title: 'Mood pattern: ${topMood.key.label}',
        detail: 'Urges often appear when you feel ${topMood.key.label.toLowerCase()}.',
        riskLevel: 'medium',
      ));
    }

    final topHour = _topEntry(hourCounts);
    if (topHour != null) {
      final label = _hourLabel(topHour.key);
      insights.add(UrgePatternInsight(
        title: 'Risky time: $label',
        detail: 'Most urges logged around this time of day.',
        riskLevel: 'medium',
      ));
    }

    if (highMoneyUrges >= 2) {
      insights.add(UrgePatternInsight(
        title: 'Money on hand',
        detail:
            '$highMoneyUrges urges happened with £50+ available so consider bank blocks.',
        riskLevel: 'high',
      ));
    }

    final resistRate = (resistedCount / urges.length * 100).round();
    insights.add(UrgePatternInsight(
      title: 'Urge control: $resistRate% resisted',
      detail: resistRate >= 70
          ? 'You are building confidence and CBT shows this matters most.'
          : 'Logging urges builds control even when you slip. Keep tracking.',
      riskLevel: resistRate >= 70 ? 'low' : 'medium',
    ));

    return insights;
  }

  MapEntry<T, int>? _topEntry<T>(Map<T, int> counts) {
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  String _hourLabel(int hour) {
    if (hour >= 17 && hour < 22) return 'Evening ($hour:00–${hour + 1}:00)';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 6 && hour < 12) return 'Morning';
    return 'Late night';
  }

  bool isRiskyMoment(List<UrgeLog> urges, [DateTime? now]) {
    final time = now ?? DateTime.now();
    if (urges.isEmpty) {
      return time.weekday == DateTime.friday && time.hour >= 17;
    }
    final recent = urges.take(20).toList();
    final hourCounts = <int, int>{};
    for (final u in recent) {
      hourCounts[u.createdAt.hour] = (hourCounts[u.createdAt.hour] ?? 0) + 1;
    }
    final topHour = _topEntry(hourCounts)?.key;
    if (topHour != null && (time.hour - topHour).abs() <= 1) return true;
    if (time.weekday == DateTime.friday && time.hour >= 17) return true;
    return false;
  }
}
