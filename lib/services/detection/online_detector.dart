import '../../domain/models/enums.dart';
import 'detection_signal.dart';
import 'gambling_catalog.dart';
import 'url_payment_monitors.dart';
import 'usage_monitor.dart';

/// Tracks online gambling activity: app opens/logins and website visits.
class OnlineDetector {
  OnlineDetector({
    required this.usageMonitor,
    required this.urlMonitor,
    GamblingCatalog? catalog,
  }) : _catalog = catalog ?? GamblingCatalog.instance;

  final UsageMonitor usageMonitor;
  final UrlMonitor urlMonitor;
  final GamblingCatalog _catalog;

  /// Seconds to look back for recent app launches (login proxy).
  static const recentAppWindowSeconds = 300;

  Future<void> initialize() => _catalog.load();

  /// Active foreground app or recent launch within [recentAppWindowSeconds].
  Future<DetectionSignal?> checkAppActivity({
    List<String> blockedApps = const [],
  }) async {
    await initialize();

    final foreground = await usageMonitor.checkActiveApp();
    if (foreground.packageName != null || foreground.appName != null) {
      final package = foreground.packageName ?? '';
      final name = foreground.appName ?? package;
      if (_catalog.matchesApp(
        packageName: package,
        appName: name,
        customBlocklist: blockedApps,
      )) {
        return DetectionSignal(
          channel: DetectionChannel.appLogin,
          signalType: BreachSignalType.app,
          metadata: {
            'appName': name,
            'packageName': package,
            'activity': 'foreground',
          },
        );
      }
    }

    final recent = await usageMonitor.checkRecentLaunches(
      windowSeconds: recentAppWindowSeconds,
    );
    for (final launch in recent) {
      final package = launch.packageName ?? '';
      final name = launch.appName ?? package;
      if (_catalog.matchesApp(
        packageName: package,
        appName: name,
        customBlocklist: blockedApps,
      )) {
        return DetectionSignal(
          channel: DetectionChannel.appLogin,
          signalType: BreachSignalType.app,
          metadata: {
            'appName': name,
            'packageName': package,
            'activity': 'recent_launch',
            if (launch.lastUsedMs != null) 'lastUsedMs': launch.lastUsedMs,
          },
        );
      }
    }

    return null;
  }

  /// Recent gambling website visit (Android VPN/DNS in Phase 2; simulator for demo).
  Future<DetectionSignal?> checkWebsiteVisit({
    List<String> blockedDomains = const [],
  }) async {
    await initialize();

    final result = await urlMonitor.checkRecentUrl();
    if (!result.isGamblingUrl || result.url == null) return null;

    final url = result.url!;
    final isBlocked = blockedDomains.isEmpty
        ? _catalog.matchesDomain(url)
        : _catalog.matchesDomain(url, customBlocklist: blockedDomains);
    if (!isBlocked) return null;

    final domainEntry = _catalog.findDomain(url);
    return DetectionSignal(
      channel: DetectionChannel.websiteVisit,
      signalType: BreachSignalType.url,
      metadata: {
        'url': url,
        if (domainEntry != null) 'siteName': domainEntry.displayName,
      },
    );
  }
}

/// Payment check for spending commitments (mock for MVP).
class SpendingDetector {
  SpendingDetector({PaymentMonitor? paymentMonitor})
      : _paymentMonitor = paymentMonitor ?? PaymentMonitor();

  final PaymentMonitor _paymentMonitor;

  Future<DetectionSignal?> checkPayment({double? maxSpend}) async {
    final result = await _paymentMonitor.checkRecentPayment();
    if (!result.isSuspiciousGamblingPayment) return null;

    if (maxSpend != null &&
        result.amount != null &&
        result.amount! < maxSpend) {
      return null;
    }

    return DetectionSignal(
      channel: DetectionChannel.payment,
      signalType: BreachSignalType.payment,
      severity: 'high',
      metadata: {
        'merchant': result.merchant,
        if (result.amount != null) 'amountRange': 'under_100',
      },
    );
  }

  PaymentMonitor get paymentMonitor => _paymentMonitor;
}
