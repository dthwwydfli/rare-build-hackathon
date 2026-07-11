import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/models/breach_event.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import 'location_service.dart';
import 'url_payment_monitors.dart';
import 'usage_monitor.dart';

class DetectionCoordinator {
  DetectionCoordinator({
    required this.locationService,
    required this.usageMonitor,
    required this.urlMonitor,
    required this.paymentMonitor,
    required this.ref,
  });

  final LocationService locationService;
  final UsageMonitor usageMonitor;
  final UrlMonitor urlMonitor;
  final PaymentMonitor paymentMonitor;
  final Ref ref;

  Timer? _timer;
  final Map<String, DateTime> _cooldowns = {};
  static const _cooldownDuration = Duration(minutes: 15);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _runChecks());
    _runChecks();
  }

  void stop() {
    _timer?.cancel();
  }

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

      final groupId = groups.first.id;

      for (final commitment in active) {
        await _checkLocation(commitment, user.id, user.displayName, groupId);
        await _checkAppUsage(commitment, user.id, user.displayName, groupId);
        await _checkUrl(commitment, user.id, user.displayName, groupId);
        await _checkPayment(commitment, user.id, user.displayName, groupId);
      }
    } catch (e) {
      debugPrint('Detection check error: $e');
    }
  }

  Future<void> _checkLocation(
    Commitment commitment,
    String userId,
    String userName,
    String groupId,
  ) async {
    if (commitment.type != CommitmentType.location) return;
    final key = 'location-$userId';
    if (_isOnCooldown(key)) return;

    final result = await locationService.checkNearbyGamblingLocations(
      radiusMeters: commitment.rules.geofenceRadiusM,
    );
    if (!result.isNearGamblingLocation || result.nearestPoi == null) return;

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitment.id,
      groupId: groupId,
      signalType: BreachSignalType.location,
      metadata: {
        'placeName': result.nearestPoi!.name,
        'lat': result.nearestPoi!.lat,
        'lng': result.nearestPoi!.lng,
        'distanceM': result.distanceMeters,
        'poiType': result.nearestPoi!.type,
      },
    );
    _setCooldown(key);
  }

  Future<void> _checkAppUsage(
    Commitment commitment,
    String userId,
    String userName,
    String groupId,
  ) async {
    if (commitment.type != CommitmentType.online) return;
    final key = 'app-$userId';
    if (_isOnCooldown(key)) return;

    final result = await usageMonitor.checkActiveApp();
    if (!result.isGamblingAppActive) return;

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitment.id,
      groupId: groupId,
      signalType: BreachSignalType.app,
      metadata: {
        'appName': result.appName,
        'packageName': result.packageName,
      },
    );
    _setCooldown(key);
  }

  Future<void> _checkUrl(
    Commitment commitment,
    String userId,
    String userName,
    String groupId,
  ) async {
    if (commitment.type != CommitmentType.online) return;
    final key = 'url-$userId';
    if (_isOnCooldown(key)) return;

    final result = await urlMonitor.checkRecentUrl();
    if (!result.isGamblingUrl) return;

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitment.id,
      groupId: groupId,
      signalType: BreachSignalType.url,
      metadata: {'url': result.url},
    );
    _setCooldown(key);
  }

  Future<void> _checkPayment(
    Commitment commitment,
    String userId,
    String userName,
    String groupId,
  ) async {
    if (commitment.type != CommitmentType.spending) return;
    final key = 'payment-$userId';
    if (_isOnCooldown(key)) return;

    final result = await paymentMonitor.checkRecentPayment();
    if (!result.isSuspiciousGamblingPayment) return;

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitment.id,
      groupId: groupId,
      signalType: BreachSignalType.payment,
      metadata: {
        'merchant': result.merchant,
        // Do not expose exact amount in notifications — stored for demo only
        'amountRange': result.amount != null ? 'under_100' : null,
      },
      severity: 'high',
    );
    _setCooldown(key);
  }

  Future<BreachEvent> emitManualBreach({
    required BreachSignalType signalType,
    Map<String, dynamic>? metadata,
  }) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) throw Exception('Not signed in');

    final commitments = await ref
        .read(commitmentRepositoryProvider)
        .watchUserCommitments(user.id)
        .first;
    final groups = await ref
        .read(groupRepositoryProvider)
        .watchUserGroups(user.id)
        .first;

    if (commitments.isEmpty) throw Exception('Create a commitment first');
    if (groups.isEmpty) throw Exception('Join a group first');

    return _emitBreach(
      userId: user.id,
      userName: user.displayName,
      commitmentId: commitments.first.id,
      groupId: groups.first.id,
      signalType: signalType,
      metadata: metadata ?? {},
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
  }) {
    return ref.read(breachRepositoryProvider).createBreach(
          BreachEvent(
            id: '',
            userId: userId,
            commitmentId: commitmentId,
            groupId: groupId,
            signalType: signalType,
            metadata: metadata,
            severity: severity,
            createdAt: DateTime.now(),
            userName: userName,
          ),
        );
  }
}

final detectionCoordinatorProvider = Provider<DetectionCoordinator>((ref) {
  final coordinator = DetectionCoordinator(
    locationService: LocationService(),
    usageMonitor: UsageMonitorFactory.create(),
    urlMonitor: UrlMonitor(),
    paymentMonitor: PaymentMonitor(),
    ref: ref,
  );
  ref.onDispose(coordinator.stop);
  return coordinator;
});
