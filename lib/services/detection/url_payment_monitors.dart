import 'gambling_catalog.dart';

class UrlCheckResult {
  const UrlCheckResult({
    required this.isGamblingUrl,
    this.url,
  });

  final bool isGamblingUrl;
  final String? url;
}

/// MVP mock — real implementation would use VPN/DNS on Android.
class UrlMonitor {
  bool _simulateActive = false;
  String _simulatedUrl = 'https://www.bet365.com';

  void simulateVisit(String url) {
    _simulateActive = true;
    _simulatedUrl = url;
  }

  void clearSimulation() {
    _simulateActive = false;
  }

  Future<UrlCheckResult> checkRecentUrl() async {
    if (!_simulateActive) {
      return const UrlCheckResult(isGamblingUrl: false);
    }
    await GamblingCatalog.instance.load();
    final isGambling =
        GamblingCatalog.instance.matchesDomain(_simulatedUrl);
    return UrlCheckResult(isGamblingUrl: isGambling, url: _simulatedUrl);
  }

  bool isBlockedDomain(String domain) {
    return GamblingCatalog.instance.matchesDomain(domain);
  }
}

class PaymentCheckResult {
  const PaymentCheckResult({
    required this.isSuspiciousGamblingPayment,
    this.amount,
    this.merchant,
  });

  final bool isSuspiciousGamblingPayment;
  final double? amount;
  final String? merchant;
}

/// MVP mock — Phase 2 would integrate Open Banking (Plaid/TrueLayer).
class PaymentMonitor {
  static const _gamblingMerchants = [
    'bet365',
    'william hill',
    'ladbrokes',
    'paddy power',
    'betway',
    'paypal gambling',
  ];

  bool _simulateActive = false;
  double _simulatedAmount = 50;
  String _simulatedMerchant = 'Bet365';

  void simulatePayment({double? amount, String? merchant}) {
    _simulateActive = true;
    if (amount != null) _simulatedAmount = amount;
    if (merchant != null) _simulatedMerchant = merchant;
  }

  void clearSimulation() {
    _simulateActive = false;
  }

  Future<PaymentCheckResult> checkRecentPayment() async {
    if (!_simulateActive) {
      return const PaymentCheckResult(isSuspiciousGamblingPayment: false);
    }
    final isGambling = _gamblingMerchants.any(
      (m) => _simulatedMerchant.toLowerCase().contains(m),
    );
    return PaymentCheckResult(
      isSuspiciousGamblingPayment: isGambling,
      amount: _simulatedAmount,
      merchant: _simulatedMerchant,
    );
  }
}
