import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import 'detection_signal.dart';
import 'gambling_catalog.dart';
import 'online_detector.dart';
import 'physical_detector.dart';
import 'url_payment_monitors.dart';
import 'usage_monitor.dart';

/// Orchestrates periodic detection across physical, online, and spending channels.
class DetectionCoordinator {
  DetectionCoordinator({
    required this.physicalDetector,
    required this.onlineDetector,
    required this.spendingDetector,
    required this.usageMonitor,
    required this.urlMonitor,
    required this.ref,
  });

  final PhysicalDetector physicalDetector;
  final OnlineDetector onlineDetector;
  final SpendingDetector spendingDetector;
  final UsageMonitor usageMonitor;
  final UrlMonitor urlMonitor;
  final Ref ref;

  PaymentMonitor get paymentMonitor => spendingDetector.paymentMonitor;

  Timer? _timer;
  final Map<String, DateTime> _cooldowns = {};
  static const _cooldownDuration = Duration(minutes: 15);

  void start() {
    _initialize();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _runChecks());
    _runChecks();
  }

  Future<void> _initialize() async {
    try {
      await GamblingCatalog.instance.load();
      if (usageMonitor is AndroidUsageMonitor) {
        await (usageMonitor as AndroidUsageMonitor)
            .syncPackageList(GamblingCatalog.instance.packageNames);
      }
    } catch (e) {
      debugPrint('Detection init error: $e');
    }
  }

  void stop() {
    _timer?.cancel();
  }

  void clearCooldowns() {
    _cooldowns.clear();
  }

  Future<void> runChecksNow() => _runChecks();

  bool _isOnCooldown(String key) {
    final last = _cooldowns[key];
    if (last == null) return false;
    return DateTime.now().difference(last) < _cooldownDuration;
  }

  void _setCooldown(String key) {
    _cooldowns[key] = DateTime.now();
  }

  Future<void> _runChecks() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    try {
      final commitments = await ref
          .read(commitmentRepositoryProvider)
          .watchUserCommitments(user.id)
          .first;
      final active = commitments.where((c) => c.active).toList();
      if (active.isEmpty) return;

      final groups = await ref
          .read(groupRepositoryProvider)
          .watchUserGroups(user.id)
          .first;
      if (groups.isEmpty) return;

      for (final commitment in active) {
        for (final group in groups) {
          await _evaluateCommitment(
            commitment: commitment,
            userId: user.id,
            userName: user.displayName,
            groupId: group.id,
          );
        }
      }
    } catch (e) {
      debugPrint('Detection check error: $e');
    }
  }

  Future<void> _evaluateCommitment({
    required Commitment commitment,
    required String userId,
    required String userName,
    required String groupId,
  }) async {
    switch (commitment.type) {
      case CommitmentType.location:
        await _emitIfDetected(
          signal: await physicalDetector.checkNearbyVenue(
            radiusMeters: commitment.rules.geofenceRadiusM,
          ),
          cooldownKey: 'location-$userId-$groupId',
          userId: userId,
          userName: userName,
          commitmentId: commitment.id,
          groupId: groupId,
        );
      case CommitmentType.online:
        await _emitIfDetected(
          signal: await onlineDetector.checkAppActivity(
            blockedApps: commitment.rules.blockedApps,
          ),
          cooldownKey: 'app-$userId-$groupId',
          userId: userId,
          userName: userName,
          commitmentId: commitment.id,
          groupId: groupId,
        );
        await _emitIfDetected(
          signal: await onlineDetector.checkWebsiteVisit(
            blockedDomains: commitment.rules.blockedDomains,
          ),
          cooldownKey: 'url-$userId-$groupId',
          userId: userId,
          userName: userName,
          commitmentId: commitment.id,
          groupId: groupId,
        );
      case CommitmentType.spending:
        await _emitIfDetected(
          signal: await spendingDetector.checkPayment(
            maxSpend: commitment.rules.maxSpend,
          ),
          cooldownKey: 'payment-$userId-$groupId',
          userId: userId,
          userName: userName,
          commitmentId: commitment.id,
          groupId: groupId,
        );
    }
  }

  Future<void> _emitIfDetected({
    required DetectionSignal? signal,
    required String cooldownKey,
    required String userId,
    required String userName,
    required String commitmentId,
    required String groupId,
  }) async {
    if (signal == null) return;
    if (_isOnCooldown(cooldownKey)) return;

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitmentId,
      groupId: groupId,
      signalType: signal.signalType,
      metadata: signal.metadata,
      severity: signal.severity,
    );
    _setCooldown(cooldownKey);
  }

  Future<List<BreachEvent>> emitManualBreach({
    required BreachSignalType signalType,
    Map<String, dynamic>? metadata,
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) throw Exception('Not signed in');

    final commitments = await ref
        .read(commitmentRepositoryProvider)
        .watchUserCommitments(user.id)
        .first;
    final groups =
        await ref.read(groupRepositoryProvider).watchUserGroups(user.id).first;

    if (commitments.isEmpty) throw Exception('Create a commitment first');
    if (groups.isEmpty) throw Exception('Join a group first');

    final commitment = _commitmentForSignal(commitments, signalType);
    final events = <BreachEvent>[];

    for (final group in groups) {
      final event = await _emitBreach(
        userId: user.id,
        userName: user.displayName,
        commitmentId: commitment.id,
        groupId: group.id,
        signalType: signalType,
        metadata: metadata ?? {},
      );
      events.add(event);
    }

    return events;
  }

  Commitment _commitmentForSignal(
    List<Commitment> commitments,
    BreachSignalType signalType,
  ) {
    CommitmentType? targetType;
    switch (signalType) {
      case BreachSignalType.location:
        targetType = CommitmentType.location;
      case BreachSignalType.app:
      case BreachSignalType.url:
        targetType = CommitmentType.online;
      case BreachSignalType.payment:
        targetType = CommitmentType.spending;
      case BreachSignalType.manual:
        return commitments.first;
    }
    return commitments.firstWhere(
      (c) => c.type == targetType && c.active,
      orElse: () => commitments.first,
    );
  }

  Future<BreachEvent> _emitBreach({
    required String userId,
    required String userName,
    required String commitmentId,
    required String groupId,
    required BreachSignalType signalType,
    required Map<String, dynamic> metadata,
    String severity = 'medium',
  }) async {
    final event = await ref.read(breachRepositoryProvider).createBreach(
          BreachEvent(
            id: '',
            userId: userId,
            commitmentId: commitmentId,
            groupId: groupId,
            signalType: signalType,
            metadata: metadata,
            severity: severity,
            flagged: true,
            createdAt: DateTime.now(),
            userName: userName,
          ),
        );
    await ref.read(gamificationRepositoryProvider).applyBreachPenalty(
          userId,
          severity: severity == 'severe' ? 2 : 1,
        );
    return event;
  }
}

final detectionCoordinatorProvider = Provider<DetectionCoordinator>((ref) {
  final usageMonitor = UsageMonitorFactory.create();
  final urlMonitor = UrlMonitor();
  final spendingDetector = SpendingDetector();
  final coordinator = DetectionCoordinator(
    physicalDetector: PhysicalDetector(),
    onlineDetector: OnlineDetector(
      usageMonitor: usageMonitor,
      urlMonitor: urlMonitor,
    ),
    spendingDetector: spendingDetector,
    usageMonitor: usageMonitor,
    urlMonitor: urlMonitor,
    ref: ref,
  );
  ref.onDispose(coordinator.stop);
  return coordinator;
});
