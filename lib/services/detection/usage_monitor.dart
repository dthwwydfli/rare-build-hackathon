import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class GamblingApp {
  const GamblingApp({
    required this.packageName,
    required this.displayName,
  });

  final String packageName;
  final String displayName;

  factory GamblingApp.fromJson(Map<String, dynamic> json) {
    return GamblingApp(
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
    );
  }
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
}

class AndroidUsageMonitor implements UsageMonitor {
  static const _channel = MethodChannel('com.accountability/usage_stats');

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
}

class SimulatedUsageMonitor implements UsageMonitor {
  bool simulateActive = false;
  String simulatedApp = 'Bet365';

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
}

class UsageMonitorFactory {
  static Future<List<GamblingApp>> loadGamblingApps() async {
    final jsonString =
        await rootBundle.loadString('assets/data/gambling_apps.json');
    final list = json.decode(jsonString) as List<dynamic>;
    return list
        .map((e) => GamblingApp.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static UsageMonitor create() {
    if (kIsWeb) return SimulatedUsageMonitor();
    try {
      if (Platform.isAndroid) return AndroidUsageMonitor();
    } catch (_) {}
    return SimulatedUsageMonitor();
  }
}
