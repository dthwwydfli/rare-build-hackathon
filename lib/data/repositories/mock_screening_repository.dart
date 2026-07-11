import 'dart:async';

import '../../core/utils/screening_prefs.dart';
import '../../domain/models/screening_result.dart';
import '../../domain/repositories/screening_repository.dart';

class MockScreeningRepository implements ScreeningRepository {
  final _statusControllers = <String, StreamController<ScreeningStatus>>{};
  final _statuses = <String, ScreeningStatus>{};
  final _results = <String, List<ScreeningResult>>{};

  StreamController<ScreeningStatus> _controllerFor(String userId) {
    return _statusControllers.putIfAbsent(
      userId,
      () => StreamController<ScreeningStatus>.broadcast(),
    );
  }

  void _emit(String userId) {
    final status = _statuses[userId] ??
        const ScreeningStatus(screeningCompleted: false);
    _controllerFor(userId).add(status);
  }

  @override
  Future<ScreeningStatus> getStatus(String userId) async {
    final local = await getLocalScreeningStatus(userId);
    if (local.screeningCompleted) {
      _statuses[userId] = local;
      return local;
    }
    return _statuses[userId] ??
        const ScreeningStatus(screeningCompleted: false);
  }

  @override
  Stream<ScreeningStatus> watchStatus(String userId) async* {
    final initial = await getStatus(userId);
    yield initial;
    yield* _controllerFor(userId).stream;
  }

  @override
  Future<ScreeningResult> saveResult(ScreeningResult result) async {
    final id = result.id.isEmpty ? 'mock_${result.completedAt.millisecondsSinceEpoch}' : result.id;
    final saved = ScreeningResult(
      id: id,
      userId: result.userId,
      completedAt: result.completedAt,
      pgsiScore: result.pgsiScore,
      phq2Score: result.phq2Score,
      gad2Score: result.gad2Score,
      auditCScore: result.auditCScore,
      suicideItemScore: result.suicideItemScore,
      pgsiBand: result.pgsiBand,
      referrals: result.referrals,
      crisisTriggered: result.crisisTriggered,
      screeningVersion: result.screeningVersion,
      isRescreen: result.isRescreen,
    );

    _results.putIfAbsent(result.userId, () => []).add(saved);

    final nextDue = saved.completedAt.add(ScreeningStatus.rescreenInterval);
    final status = ScreeningStatus(
      screeningCompleted: true,
      lastScreeningAt: saved.completedAt,
      nextScreeningDueAt: nextDue,
      activeReferralFlags: saved.activeReferralFlags,
    );
    _statuses[result.userId] = status;
    await saveLocalScreeningStatus(userId: result.userId, status: status);
    _emit(result.userId);
    return saved;
  }

  @override
  Future<ScreeningResult?> getLatestResult(String userId) async {
    final list = _results[userId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }
}
