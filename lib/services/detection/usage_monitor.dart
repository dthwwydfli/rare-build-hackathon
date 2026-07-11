import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gambling_catalog.dart';

class AppLaunchResult {
  const AppLaunchResult({
    this.packageName,
    this.appName,
    this.lastUsedMs,
  });

  final String? packageName;
  final String? appName;
  final int? lastUsedMs;
}

class AppUsageResult {
  const AppUsageResult({
    required this.isGamblingAppActive,
    this.appName,
    this.packageName,
  });

  final bool isGamblingAppActive;
  final String? appName;
  final String? packageName;
}

abstract class UsageMonitor {
  Future<AppUsageResult> checkActiveApp();

  /// Recent app opens within [windowSeconds] — proxy for logins.
  Future<List<AppLaunchResult>> checkRecentLaunches({
    int windowSeconds = 300,
  });
}

class AndroidUsageMonitor implements UsageMonitor {
  static const _channel = MethodChannel('com.accountability/usage_stats');

  Future<void> syncPackageList(List<String> packages) async {
    if (kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
    } catch (_) {
      return;
    }
    try {
      await _channel.invokeMethod('setGamblingPackages', packages);
    } catch (e) {
      debugPrint('Failed to sync gambling packages: $e');
    }
  }

  @override
  Future<AppUsageResult> checkActiveApp() async {
    if (kIsWeb) {
      return const AppUsageResult(isGamblingAppActive: false);
    }
    try {
      if (!Platform.isAndroid) {
        return const AppUsageResult(isGamblingAppActive: false);
      }
    } catch (_) {
      return const AppUsageResult(isGamblingAppActive: false);
    }
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getForegroundApp',
      );
      if (result == null) {
        return const AppUsageResult(isGamblingAppActive: false);
      }
      final packageName = result['packageName'] as String? ?? '';
      final appName = result['appName'] as String? ?? packageName;
      return AppUsageResult(
        isGamblingAppActive: result['isGambling'] as bool? ?? false,
        appName: appName,
        packageName: packageName,
      );
    } catch (e) {
      debugPrint('UsageStats error: $e');
      return const AppUsageResult(isGamblingAppActive: false);
    }
  }

  @override
  Future<List<AppLaunchResult>> checkRecentLaunches({
    int windowSeconds = 300,
  }) async {
    if (kIsWeb) return const [];
    try {
      if (!Platform.isAndroid) return const [];
    } catch (_) {
      return const [];
    }
    try {
      final result = await _channel.invokeMethod<List<dynamic>>(
        'getRecentGamblingLaunches',
        {'windowSeconds': windowSeconds},
      );
      if (result == null) return const [];
      return result.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return AppLaunchResult(
          packageName: map['packageName'] as String?,
          appName: map['appName'] as String?,
          lastUsedMs: map['lastUsedMs'] as int?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Recent launches error: $e');
      return const [];
    }
  }
}

class SimulatedUsageMonitor implements UsageMonitor {
  bool simulateActive = false;
  String simulatedApp = 'Bet365';
  bool simulateRecentLaunch = false;

  @override
  Future<AppUsageResult> checkActiveApp() async {
    if (!simulateActive) {
      return const AppUsageResult(isGamblingAppActive: false);
    }
    return AppUsageResult(
      isGamblingAppActive: true,
      appName: simulatedApp,
      packageName: 'com.bet365',
    );
  }

  @override
  Future<List<AppLaunchResult>> checkRecentLaunches({
    int windowSeconds = 300,
  }) async {
    if (!simulateRecentLaunch && !simulateActive) return const [];
    return [
      AppLaunchResult(
        packageName: 'com.bet365',
        appName: simulatedApp,
        lastUsedMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
  }
}

class UsageMonitorFactory {
  static Future<List<GamblingAppEntry>> loadGamblingApps() async {
    await GamblingCatalog.instance.load();
    return GamblingCatalog.instance.apps;
  }

  static UsageMonitor create() {
    if (kIsWeb) return SimulatedUsageMonitor();
    try {
      if (Platform.isAndroid) return AndroidUsageMonitor();
    } catch (_) {}
    return SimulatedUsageMonitor();
  }
}
