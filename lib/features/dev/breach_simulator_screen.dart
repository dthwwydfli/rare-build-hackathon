import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../domain/models/enums.dart';
import '../../services/detection/detection_coordinator.dart';
import '../../services/detection/url_payment_monitors.dart';
import '../../services/detection/usage_monitor.dart';

class BreachSimulatorScreen extends ConsumerStatefulWidget {
  const BreachSimulatorScreen({super.key});

  @override
  ConsumerState<BreachSimulatorScreen> createState() =>
      _BreachSimulatorScreenState();
}

class _BreachSimulatorScreenState extends ConsumerState<BreachSimulatorScreen> {
  bool _loading = false;
  String? _lastResult;

  Future<void> _trigger(BreachSignalType type) async {
    setState(() {
      _loading = true;
      _lastResult = null;
    });

    try {
      final coordinator = ref.read(detectionCoordinatorProvider);
      Map<String, dynamic> metadata = {};

      switch (type) {
        case BreachSignalType.location:
          metadata = {
            'placeName': 'Coral Betting - Oxford Street',
            'lat': 51.5154,
            'lng': -0.1419,
            'distanceM': 85,
            'poiType': 'betting_shop',
          };
        case BreachSignalType.app:
          final monitor = coordinator.usageMonitor;
          if (monitor is SimulatedUsageMonitor) {
            monitor.simulateActive = true;
            monitor.simulatedApp = 'Bet365';
          }
          metadata = {'appName': 'Bet365', 'packageName': 'com.bet365'};
        case BreachSignalType.url:
          coordinator.urlMonitor.simulateVisit('https://www.bet365.com');
          metadata = {'url': 'https://www.bet365.com'};
        case BreachSignalType.payment:
          coordinator.paymentMonitor.simulatePayment(
            amount: 75,
            merchant: 'Bet365',
          );
          metadata = {'merchant': 'Bet365', 'amountRange': 'under_100'};
        case BreachSignalType.manual:
          metadata = {'note': 'Manual demo breach'};
      }

      final event = await coordinator.emitManualBreach(
        signalType: type,
        metadata: metadata,
      );
      setState(() => _lastResult = 'Breach created: ${event.id}\n${event.summary}');
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Breach simulator')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Dev tool for demoing the breach → friend notification flow. '
            'Triggers write to Firestore and invoke Cloud Functions.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          ...BreachSignalType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: _loading ? null : () => _trigger(type),
                child: Text('Simulate ${type.label} breach'),
              ),
            );
          }),
          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_lastResult!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
