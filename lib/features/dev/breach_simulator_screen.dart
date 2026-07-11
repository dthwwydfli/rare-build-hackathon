import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/friend_group.dart';
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

      final events = await coordinator.emitManualBreach(
        signalType: type,
        metadata: metadata,
      );
      setState(() => _lastResult =
          'Created ${events.length} breach(es)\n${events.first.summary}');
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Breach simulator')),
        body: const Center(
          child: Text('Simulator is only available in debug builds'),
        ),
      );
    }

    final user = ref.watch(currentUserProvider).valueOrNull;
    final commitmentsAsync = user == null
        ? const AsyncValue<List<Commitment>>.loading()
        : ref.watch(_commitmentsProvider(user.id));
    final groupsAsync = user == null
        ? const AsyncValue<List<FriendGroup>>.loading()
        : ref.watch(_groupsProvider(user.id));

    final commitments = commitmentsAsync.valueOrNull ?? [];
    final groups = groupsAsync.valueOrNull ?? [];
    final ready = commitments.isNotEmpty && groups.isNotEmpty;

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
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prerequisites', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: 'Signed in',
                    ok: user != null,
                  ),
                  _StatusRow(
                    label: 'Commitment (${commitments.length})',
                    ok: commitments.isNotEmpty,
                  ),
                  _StatusRow(
                    label: 'Friend group (${groups.length})',
                    ok: groups.isNotEmpty,
                  ),
                ],
              ),
            ),
          ),
          if (!ready) ...[
            const SizedBox(height: 16),
            const ErrorBanner(
              message: 'Create a commitment and join a group before simulating.',
            ),
          ],
          const SizedBox(height: 24),
          ...BreachSignalType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: _loading || !ready ? null : () => _trigger(type),
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle : Icons.cancel,
            color: ok ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

final _commitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
  return ref.watch(commitmentRepositoryProvider).watchUserCommitments(userId);
});

final _groupsProvider =
    StreamProvider.family<List<FriendGroup>, String>((ref, userId) {
  return ref.watch(groupRepositoryProvider).watchUserGroups(userId);
});
