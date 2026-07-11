import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/access_block_settings.dart';

const _gamstopUrl = 'https://www.gamstop.co.uk/';
const _spendingDelayOptions = [0, 15, 30, 60, 1440];

class BlockAccessScreen extends ConsumerStatefulWidget {
  const BlockAccessScreen({super.key});

  @override
  ConsumerState<BlockAccessScreen> createState() => _BlockAccessScreenState();
}

class _BlockAccessScreenState extends ConsumerState<BlockAccessScreen> {
  bool _saving = false;

  Future<void> _save(AccessBlockSettings settings) async {
    setState(() => _saving = true);
    try {
      await ref.read(accessBlockRepositoryProvider).saveSettings(settings);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _startSpendingDelay(AccessBlockSettings settings) async {
    if (settings.spendingDelayMinutes <= 0) {
      showAppSnackBar(context, 'Set a spending delay duration first');
      return;
    }
    final until = DateTime.now().add(Duration(minutes: settings.spendingDelayMinutes));
    await _save(settings.copyWith(spendingDelayUntil: until));
    if (mounted) {
      showAppSnackBar(
        context,
        'Spending locked for ${settings.spendingDelayMinutes} minutes',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final settingsAsync = ref.watch(_blockSettingsProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Block access & money'),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _HeaderCard(activeCount: settings.activeBlockCount),
            if (settings.spendingDelayActive) ...[
              const SizedBox(height: 16),
              _SpendingDelayActiveCard(until: settings.spendingDelayUntil!),
            ],
            const SizedBox(height: 24),
            Text(
              'Cut off access and not willpower',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'These barriers stop gambling in the moment. An app can do what '
              'talking cannot: block the money and the access.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            _BlockTile(
              icon: Icons.block,
              title: 'GAMSTOP',
              subtitle: 'UK self-exclusion from all licensed online gambling',
              enabled: settings.gamstopRegistered,
              onToggle: (v) => _save(settings.copyWith(gamstopRegistered: v)),
              actionLabel: 'Sign up',
              onAction: () => _openUrl(_gamstopUrl),
            ),
            _BlockTile(
              icon: Icons.account_balance,
              title: 'Bank gambling block',
              subtitle: settings.bankName != null
                  ? '${settings.bankName} block enabled'
                  : 'Block gambling transactions at your bank',
              enabled: settings.bankBlockEnabled,
              onToggle: (v) => _save(settings.copyWith(bankBlockEnabled: v)),
              child: _BankPicker(
                selected: settings.bankName,
                onSelected: (bank) => _save(settings.copyWith(
                  bankName: bank,
                  bankBlockEnabled: true,
                )),
                onOpenGuide: _openUrl,
              ),
            ),
            _BlockTile(
              icon: Icons.phone_android,
              title: 'App blocker',
              subtitle: 'Monitor gambling apps via Usage Access (Android)',
              enabled: settings.appBlockerEnabled,
              onToggle: (v) => _save(settings.copyWith(appBlockerEnabled: v)),
              actionLabel: 'Permissions',
              onAction: () => context.push('/permissions'),
            ),
            _BlockTile(
              icon: Icons.public_off,
              title: 'Website blocker',
              subtitle: 'Track gambling domains (full block Phase 2)',
              enabled: settings.websiteBlockerEnabled,
              onToggle: (v) => _save(settings.copyWith(websiteBlockerEnabled: v)),
            ),
            _BlockTile(
              icon: Icons.timer_outlined,
              title: 'Spending delay',
              subtitle: settings.spendingDelayMinutes == 0
                  ? 'Cooling-off period before any spend'
                  : '${settings.spendingDelayMinutes} min delay active',
              enabled: settings.spendingDelayMinutes > 0,
              onToggle: (v) => _save(settings.copyWith(
                spendingDelayMinutes: v ? 30 : 0,
                clearSpendingDelayUntil: !v,
              )),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _spendingDelayOptions.where((m) => m > 0).map((m) {
                      final label = m >= 60 ? '${m ~/ 60}h' : '${m}m';
                      return ChoiceChip(
                        label: Text(label),
                        selected: settings.spendingDelayMinutes == m,
                        onSelected: (_) => _save(
                          settings.copyWith(spendingDelayMinutes: m),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: settings.spendingDelayActive
                        ? null
                        : () => _startSpendingDelay(settings),
                    icon: const Icon(Icons.lock_clock),
                    label: const Text('Start delay now because I feel an urge to spend'),
                  ),
                ],
              ),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
        loading: () => const LoadingView(),
        error: (_, __) => const ErrorBanner(message: 'Could not load block settings'),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.activeCount});

  final int activeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeCount of 5 barriers active',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeCount >= 3
                      ? 'Strong protection in place'
                      : 'Enable more blocks for stronger protection',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingDelayActiveCard extends StatelessWidget {
  const _SpendingDelayActiveCard({required this.until});

  final DateTime until;

  @override
  Widget build(BuildContext context) {
    final remaining = until.difference(DateTime.now());
    final mins = remaining.inMinutes.clamp(0, 9999);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock, color: AppTheme.danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Spending locked with $mins minutes remaining',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  const _BlockTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    this.actionLabel,
    this.onAction,
    this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: enabled ? AppTheme.primary : Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Switch(value: enabled, onChanged: onToggle),
              ],
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ),
            ],
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

class _BankPicker extends StatelessWidget {
  const _BankPicker({
    required this.selected,
    required this.onSelected,
    required this.onOpenGuide,
  });

  final String? selected;
  final ValueChanged<String> onSelected;
  final Future<void> Function(String url) onOpenGuide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ukBankBlockOptions.map((bank) {
            return ActionChip(
              label: Text(bank.name),
              backgroundColor: selected == bank.name
                  ? AppTheme.accent
                  : null,
              onPressed: () {
                onSelected(bank.name);
                onOpenGuide(bank.url);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

final _blockSettingsProvider =
    StreamProvider.family<AccessBlockSettings, String>((ref, userId) {
  return ref.watch(accessBlockRepositoryProvider).watchSettings(userId);
});
