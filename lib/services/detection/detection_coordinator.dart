import 'dart:async';
import 'dart:convert';

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
  List<String> _defaultGamblingPackages = [];

  void start() {
    _loadDefaultPackages();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _runChecks());
    _runChecks();
  }

  Future<void> _loadDefaultPackages() async {
    try {
      final apps = await UsageMonitorFactory.loadGamblingApps();
      _defaultGamblingPackages = apps.map((a) => a.packageName).toList();
    } catch (e) {
      debugPrint('Failed to load gambling apps: $e');
    }
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

      for (final commitment in active) {
        for (final group in groups) {
          await _checkLocation(commitment, user.id, user.displayName, group.id);
          await _checkAppUsage(commitment, user.id, user.displayName, group.id);
          await _checkUrl(commitment, user.id, user.displayName, group.id);
          await _checkPayment(commitment, user.id, user.displayName, group.id);
        }
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
    final key = 'location-$userId-$groupId';
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
    final key = 'app-$userId-$groupId';
    if (_isOnCooldown(key)) return;

    final result = await usageMonitor.checkActiveApp();
    if (result.packageName == null && result.appName == null) return;

    final blockedApps = commitment.rules.blockedApps;
    final packageName = result.packageName ?? '';
    final appName = result.appName ?? '';

    final isBlocked = _matchesBlockedApp(
      packageName: packageName,
      appName: appName,
      blockedApps: blockedApps,
    );
    if (!isBlocked) return;

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitment.id,
      groupId: groupId,
      signalType: BreachSignalType.app,
      metadata: {
        'appName': appName,
        'packageName': packageName,
      },
    );
    _setCooldown(key);
  }

  bool _matchesBlockedApp({
    required String packageName,
    required String appName,
    required List<String> blockedApps,
  }) {
    final targets = blockedApps.isNotEmpty ? blockedApps : _defaultGamblingPackages;
    final lowerPackage = packageName.toLowerCase();
    final lowerApp = appName.toLowerCase();
    for (final target in targets) {
      final t = target.toLowerCase();
      if (lowerPackage.contains(t) || lowerApp.contains(t)) return true;
    }
    return false;
  }

  Future<void> _checkUrl(
    Commitment commitment,
    String userId,
    String userName,
    String groupId,
  ) async {
    if (commitment.type != CommitmentType.online) return;
    final key = 'url-$userId-$groupId';
    if (_isOnCooldown(key)) return;

    final result = await urlMonitor.checkRecentUrl();
    if (!result.isGamblingUrl || result.url == null) return;

    final domains = commitment.rules.blockedDomains;
    final isBlocked = domains.isEmpty
        ? urlMonitor.isBlockedDomain(result.url!)
        : domains.any((d) => result.url!.toLowerCase().contains(d.toLowerCase()));
    if (!isBlocked) return;

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
    final key = 'payment-$userId-$groupId';
    if (_isOnCooldown(key)) return;

    final result = await paymentMonitor.checkRecentPayment();
    if (!result.isSuspiciousGamblingPayment) return;

    if (commitment.rules.maxSpend != null &&
        result.amount != null &&
        result.amount! < commitment.rules.maxSpend!) {
      return;
    }

    await _emitBreach(
      userId: userId,
      userName: userName,
      commitmentId: commitment.id,
      groupId: groupId,
      signalType: BreachSignalType.payment,
      metadata: {
        'merchant': result.merchant,
        'amountRange': result.amount != null ? 'under_100' : null,
      },
      severity: 'high',
    );
    _setCooldown(key);
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
    final groups = await ref
        .read(groupRepositoryProvider)
        .watchUserGroups(user.id)
        .first;

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
