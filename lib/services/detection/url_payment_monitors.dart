import 'dart:math';

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
  static const _gamblingDomains = [
    'bet365.com',
    'paddypower.com',
    'williamhill.com',
    'ladbrokes.com',
    'betway.com',
    'skybet.com',
    'betfair.com',
  ];

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
    final isGambling = _gamblingDomains.any(
      (d) => _simulatedUrl.toLowerCase().contains(d),
    );
    return UrlCheckResult(isGamblingUrl: isGambling, url: _simulatedUrl);
  }

  bool isBlockedDomain(String domain) {
    return _gamblingDomains.any(
      (d) => domain.toLowerCase().contains(d),
    );
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

  double randomDemoAmount() {
    return (Random().nextInt(200) + 10).toDouble();
  }
}
