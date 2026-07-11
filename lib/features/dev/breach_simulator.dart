import 'package:flutter/material.dart';

import '../../domain/models/breach_event.dart';
import '../../domain/models/enums.dart';
import '../../services/detection/detection_coordinator.dart';
import '../../services/detection/detection_signal.dart';
import '../../services/detection/gambling_catalog.dart';
import '../../services/detection/usage_monitor.dart';

enum BreachSimulatorMode {
  direct,
  viaDetection,
}

/// Demo scenarios mapped to detection channels.
enum BreachSimulationPreset {
  physicalShop,
  appForeground,
  appRecentLogin,
  websiteVisit,
  payment,
}

extension BreachSimulationPresetX on BreachSimulationPreset {
  DetectionChannel get channel => switch (this) {
        BreachSimulationPreset.physicalShop => DetectionChannel.physical,
        BreachSimulationPreset.appForeground ||
        BreachSimulationPreset.appRecentLogin =>
          DetectionChannel.appLogin,
        BreachSimulationPreset.websiteVisit => DetectionChannel.websiteVisit,
        BreachSimulationPreset.payment => DetectionChannel.payment,
      };

  BreachSignalType get signalType => switch (this) {
        BreachSimulationPreset.physicalShop => BreachSignalType.location,
        BreachSimulationPreset.appForeground ||
        BreachSimulationPreset.appRecentLogin =>
          BreachSignalType.app,
        BreachSimulationPreset.websiteVisit => BreachSignalType.url,
        BreachSimulationPreset.payment => BreachSignalType.payment,
      };

  CommitmentType get requiredCommitmentType => switch (this) {
        BreachSimulationPreset.physicalShop => CommitmentType.location,
        BreachSimulationPreset.appForeground ||
        BreachSimulationPreset.appRecentLogin ||
        BreachSimulationPreset.websiteVisit =>
          CommitmentType.online,
        BreachSimulationPreset.payment => CommitmentType.spending,
      };

  String get title => switch (this) {
        BreachSimulationPreset.physicalShop => 'Near betting shop',
        BreachSimulationPreset.appForeground => 'Gambling app open',
        BreachSimulationPreset.appRecentLogin => 'Gambling app login',
        BreachSimulationPreset.websiteVisit => 'Gambling website visit',
        BreachSimulationPreset.payment => 'Gambling payment',
      };

  String get description => switch (this) {
        BreachSimulationPreset.physicalShop =>
          'Simulates GPS proximity to a Coral betting shop',
        BreachSimulationPreset.appForeground =>
          'Simulates Bet365 in the foreground (Android UsageStats)',
        BreachSimulationPreset.appRecentLogin =>
          'Simulates a recent Bet365 app launch within 5 minutes',
        BreachSimulationPreset.websiteVisit =>
          'Simulates visiting bet365.com in the browser',
        BreachSimulationPreset.payment =>
          'Simulates a £75 payment to Bet365',
      };

  IconData get icon => switch (this) {
        BreachSimulationPreset.physicalShop => Icons.store_outlined,
        BreachSimulationPreset.appForeground => Icons.phone_android_outlined,
        BreachSimulationPreset.appRecentLogin => Icons.login_outlined,
        BreachSimulationPreset.websiteVisit => Icons.language_outlined,
        BreachSimulationPreset.payment => Icons.payments_outlined,
      };
}

class BreachSimulatorResult {
  const BreachSimulatorResult({
    required this.preset,
    required this.mode,
    required this.events,
    required this.metadata,
  });

  final BreachSimulationPreset preset;
  final BreachSimulatorMode mode;
  final List<BreachEvent> events;
  final Map<String, dynamic> metadata;

  String get summary {
    if (mode == BreachSimulatorMode.viaDetection) {
      return 'Detection pipeline ran — check Alerts tab or Firestore';
    }
    if (events.isEmpty) {
      return 'No breach created';
    }
    return events.map((e) => e.summary).join('\n');
  }
}

/// Arms detection monitors and triggers breaches for demo / E2E testing.
class BreachSimulator {
  BreachSimulator(this._coordinator);

  final DetectionCoordinator _coordinator;

  Future<void> loadCatalog() => GamblingCatalog.instance.load();

  Future<BreachSimulatorResult> trigger(
    BreachSimulationPreset preset, {
    BreachSimulatorMode mode = BreachSimulatorMode.direct,
  }) async {
    await loadCatalog();
    final metadata = await _armPreset(preset);

    if (mode == BreachSimulatorMode.viaDetection) {
      _coordinator.clearCooldowns();
      await _coordinator.runChecksNow();
      return BreachSimulatorResult(
        preset: preset,
        mode: mode,
        events: const [],
        metadata: metadata,
      );
    }

    final events = await _coordinator.emitManualBreach(
      signalType: preset.signalType,
      metadata: metadata,
    );
    return BreachSimulatorResult(
      preset: preset,
      mode: mode,
      events: events,
      metadata: metadata,
    );
  }

  void clearAll() {
    _coordinator.physicalDetector.clearSimulation();
    _coordinator.urlMonitor.clearSimulation();
    _coordinator.paymentMonitor.clearSimulation();
    final monitor = _coordinator.usageMonitor;
    if (monitor is SimulatedUsageMonitor) {
      monitor.simulateActive = false;
      monitor.simulateRecentLaunch = false;
    }
  }

  Future<Map<String, dynamic>> _armPreset(BreachSimulationPreset preset) async {
    final catalog = GamblingCatalog.instance;

    switch (preset) {
      case BreachSimulationPreset.physicalShop:
        final poi = catalog.pois.firstWhere(
          (p) => p.name.contains('Coral'),
          orElse: () => catalog.pois.first,
        );
        _coordinator.physicalDetector.simulateVenueVisit(poi, distanceM: 85);
        return {
          'placeName': poi.name,
          'lat': poi.lat,
          'lng': poi.lng,
          'distanceM': 85,
          'poiType': poi.type,
          'simulated': true,
        };

      case BreachSimulationPreset.appForeground:
        _armAppSimulation(foreground: true);
        return _defaultAppMetadata(activity: 'foreground');

      case BreachSimulationPreset.appRecentLogin:
        _armAppSimulation(recentLaunch: true);
        return _defaultAppMetadata(activity: 'recent_launch');

      case BreachSimulationPreset.websiteVisit:
        const url = 'https://www.bet365.com';
        _coordinator.urlMonitor.simulateVisit(url);
        return {
          'url': url,
          'siteName': catalog.findDomain(url)?.displayName ?? 'Bet365',
          'simulated': true,
        };

      case BreachSimulationPreset.payment:
        _coordinator.paymentMonitor.simulatePayment(
          amount: 75,
          merchant: 'Bet365',
        );
        return {
          'merchant': 'Bet365',
          'amountRange': 'under_100',
          'simulated': true,
        };
    }
  }

  void _armAppSimulation({bool foreground = false, bool recentLaunch = false}) {
    final monitor = _coordinator.usageMonitor;
    if (monitor is SimulatedUsageMonitor) {
      monitor.simulatedApp = 'Bet365';
      monitor.simulateActive = foreground;
      monitor.simulateRecentLaunch = recentLaunch;
    }
  }

  Map<String, dynamic> _defaultAppMetadata({required String activity}) {
    return {
      'appName': 'Bet365',
      'packageName': 'com.bet365',
      'activity': activity,
      'simulated': true,
    };
  }
}
