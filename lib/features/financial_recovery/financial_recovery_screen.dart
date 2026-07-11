import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/access_block_settings.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/financial_recovery_profile.dart';
import '../../domain/models/urge_log.dart';
import '../../services/urges/coping_prompt_service.dart';

class FinancialRecoveryScreen extends ConsumerStatefulWidget {
  const FinancialRecoveryScreen({super.key});

  @override
  ConsumerState<FinancialRecoveryScreen> createState() =>
      _FinancialRecoveryScreenState();
}

class _FinancialRecoveryScreenState
    extends ConsumerState<FinancialRecoveryScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_GB', symbol: '£');

  bool _saving = false;

  Future<void> _save(FinancialRecoveryProfile profile) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(financialRecoveryRepositoryProvider)
          .saveProfile(profile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const Scaffold(body: LoadingView());

    final profileAsync = ref.watch(financialRecoveryProfileProvider(user.id));
    final blocksAsync = ref.watch(blockSettingsProvider(user.id));
    final urgesAsync = ref.watch(_urgesProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial recovery'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: PaperBackground(
        child: profileAsync.when(
          data: (profile) {
            final blocks = blocksAsync.valueOrNull;
            final urges = urgesAsync.valueOrNull ?? [];
            final highMoneyUrges = urges
                .where((u) => (u.moneyOnHand ?? 0) >= 50)
                .length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _OverviewCard(
                  profile: profile,
                  currencyFormat: _currencyFormat,
                ),
                const SizedBox(height: 12),
                _GoalsCard(
                  profile: profile,
                  onSave: _save,
                ),
                const SizedBox(height: 12),
                _BudgetCard(
                  profile: profile,
                  currencyFormat: _currencyFormat,
                  onSave: _save,
                ),
                const SizedBox(height: 12),
                if (blocks != null)
                  _ProtectCard(
                    settings: blocks,
                    urgeCount: urges.length,
                    highMoneyUrges: highMoneyUrges,
                    onOpenBlocks: () => context.push('/tools/blocks'),
                    onOpenUrges: () => context.push('/urges/insights'),
                  ),
                const SizedBox(height: 12),
                _DebtHelpLinkTile(
                  onOpen: () => context.go('/support-hub?segment=help'),
                ),
              ],
            );
          },
          loading: () => const LoadingView(),
          error: (_, __) => const ErrorBanner(
            message: 'could not load financial recovery profile',
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.profile,
    required this.currencyFormat,
  });

  final FinancialRecoveryProfile profile;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LowercaseText(
            'rebuilding step by step',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const LowercaseText(
            'protect what is left, set small goals, and use barriers when urges hit.',
            style: TextStyle(color: AppTheme.inkPlumSoft, height: 1.4),
          ),
          if (profile.hasAnyGoal) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (profile.debtRemaining != null)
                  _StatChip(
                    label:
                        '${currencyFormat.format(profile.debtRemaining!)} debt left',
                  ),
                if (profile.savingsProgress != null)
                  _StatChip(
                    label:
                        '${(profile.savingsProgress! * 100).round()}% saved',
                  ),
                if (profile.paydayDayOfMonth != null)
                  _StatChip(label: 'payday day ${profile.paydayDayOfMonth}'),
              ],
            ),
            if (profile.savingsProgress != null) ...[
              const SizedBox(height: 12),
              _ProgressRow(
                label: 'savings',
                value: profile.savingsProgress!,
                detail:
                    '${currencyFormat.format(profile.savingsCurrent ?? 0)} of ${currencyFormat.format(profile.savingsGoal!)}',
              ),
            ],
            if (profile.debtProgress != null) ...[
              const SizedBox(height: 12),
              _ProgressRow(
                label: 'debt paid off',
                value: profile.debtProgress!,
                detail:
                    '${currencyFormat.format(profile.debtPaidOff ?? 0)} of ${currencyFormat.format(profile.estimatedDebt!)}',
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.sageDeep.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LowercaseText(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.sageDeep,
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LowercaseText(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.sageDeep,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
          backgroundColor: AppTheme.lavenderLight,
          color: AppTheme.sageDeep,
        ),
        const SizedBox(height: 4),
        LowercaseText(
          detail,
          style: const TextStyle(fontSize: 12, color: AppTheme.inkPlumSoft),
        ),
      ],
    );
  }
}

class _GoalsCard extends StatefulWidget {
  const _GoalsCard({
    required this.profile,
    required this.onSave,
  });

  final FinancialRecoveryProfile profile;
  final Future<void> Function(FinancialRecoveryProfile) onSave;

  @override
  State<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends State<_GoalsCard> {
  late final TextEditingController _debtController;
  late final TextEditingController _paidController;
  late final TextEditingController _goalController;
  late final TextEditingController _currentController;

  @override
  void initState() {
    super.initState();
    _debtController = TextEditingController(
      text: _formatAmount(widget.profile.estimatedDebt),
    );
    _paidController = TextEditingController(
      text: _formatAmount(widget.profile.debtPaidOff),
    );
    _goalController = TextEditingController(
      text: _formatAmount(widget.profile.savingsGoal),
    );
    _currentController = TextEditingController(
      text: _formatAmount(widget.profile.savingsCurrent),
    );
  }

  @override
  void didUpdateWidget(covariant _GoalsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.estimatedDebt != widget.profile.estimatedDebt) {
      _debtController.text = _formatAmount(widget.profile.estimatedDebt);
    }
    if (oldWidget.profile.debtPaidOff != widget.profile.debtPaidOff) {
      _paidController.text = _formatAmount(widget.profile.debtPaidOff);
    }
    if (oldWidget.profile.savingsGoal != widget.profile.savingsGoal) {
      _goalController.text = _formatAmount(widget.profile.savingsGoal);
    }
    if (oldWidget.profile.savingsCurrent != widget.profile.savingsCurrent) {
      _currentController.text = _formatAmount(widget.profile.savingsCurrent);
    }
  }

  @override
  void dispose() {
    _debtController.dispose();
    _paidController.dispose();
    _goalController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  String _formatAmount(double? value) => value == null
      ? ''
      : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);

  Future<void> _submit() async {
    final debt = _parseAmount(_debtController.text);
    final paid = _parseAmount(_paidController.text);
    final goal = _parseAmount(_goalController.text);
    final current = _parseAmount(_currentController.text);
    await widget.onSave(
      widget.profile.copyWith(
        estimatedDebt: debt,
        debtPaidOff: paid,
        savingsGoal: goal,
        savingsCurrent: current,
        clearEstimatedDebt: debt == null,
        clearDebtPaidOff: paid == null,
        clearSavingsGoal: goal == null,
        clearSavingsCurrent: current == null,
      ),
    );
    if (mounted) {
      showAppSnackBar(context, 'goals saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LowercaseText(
            'money goals',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const LowercaseText(
            'optional — only track what feels safe. protecting what is left is the win.',
            style: TextStyle(color: AppTheme.inkPlumSoft, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const LowercaseText(
            'debt recovery',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.sageDeep,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _MoneyField(
            controller: _debtController,
            label: 'estimated debt',
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          _MoneyField(
            controller: _paidController,
            label: 'amount paid off',
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          const LowercaseText(
            'savings goal',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.sageDeep,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const LowercaseText(
            'move money out of reach on payday — even a small buffer helps.',
            style: TextStyle(color: AppTheme.inkPlumSoft, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _MoneyField(
            controller: _goalController,
            label: 'savings target',
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          _MoneyField(
            controller: _currentController,
            label: 'saved so far',
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submit,
              child: const LowercaseText('save goals'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatefulWidget {
  const _BudgetCard({
    required this.profile,
    required this.currencyFormat,
    required this.onSave,
  });

  final FinancialRecoveryProfile profile;
  final NumberFormat currencyFormat;
  final Future<void> Function(FinancialRecoveryProfile) onSave;

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard> {
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.profile.monthlySpendingLimit == null
          ? ''
          : widget.profile.monthlySpendingLimit!.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _BudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.monthlySpendingLimit !=
        widget.profile.monthlySpendingLimit) {
      _limitController.text = widget.profile.monthlySpendingLimit == null
          ? ''
          : widget.profile.monthlySpendingLimit!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _submitLimit() async {
    final limit = _parseAmount(_limitController.text);
    await widget.onSave(
      widget.profile.copyWith(
        monthlySpendingLimit: limit,
        clearMonthlySpendingLimit: limit == null,
      ),
    );
    if (mounted) {
      showAppSnackBar(context, 'budget saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final paydayPrompt = CopingPromptService().promptForUrge(
      trigger: UrgeTrigger.payday,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LowercaseText(
            'budget & payday',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const LowercaseText(
            'a calm ceiling for unplanned spend, plus payday awareness.',
            style: TextStyle(color: AppTheme.inkPlumSoft, fontSize: 13),
          ),
          const SizedBox(height: 16),
          _MoneyField(
            controller: _limitController,
            label: 'monthly spending limit',
            onSubmitted: (_) => _submitLimit(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: widget.profile.paydayDayOfMonth,
            decoration: const InputDecoration(
              labelText: 'payday (day of month)',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: LowercaseText('not set'),
              ),
              for (var day = 1; day <= 28; day++)
                DropdownMenuItem(
                  value: day,
                  child: Text('day $day'),
                ),
            ],
            onChanged: (day) async {
              await widget.onSave(
                widget.profile.copyWith(
                  paydayDayOfMonth: day,
                  clearPaydayDayOfMonth: day == null,
                ),
              );
              if (context.mounted) {
                showAppSnackBar(context, 'payday saved');
              }
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.lavenderLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LowercaseText(
                  paydayPrompt.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lavenderDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paydayPrompt.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkPlumSoft,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submitLimit,
              child: const LowercaseText('save budget'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtectCard extends StatelessWidget {
  const _ProtectCard({
    required this.settings,
    required this.urgeCount,
    required this.highMoneyUrges,
    required this.onOpenBlocks,
    required this.onOpenUrges,
  });

  final AccessBlockSettings settings;
  final int urgeCount;
  final int highMoneyUrges;
  final VoidCallback onOpenBlocks;
  final VoidCallback onOpenUrges;

  @override
  Widget build(BuildContext context) {
    final blockPrompt = CopingPromptService().promptForBlocksIncomplete(
      settings.activeBlockCount,
      5,
    );
    final urgeSubtitle = urgeCount == 0
        ? 'log urges to spot money-on-hand patterns'
        : highMoneyUrges >= 2
            ? '$highMoneyUrges urges with £50+ available — review patterns'
            : '$urgeCount urges logged — see what triggers spending urges';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppTheme.sageDeep.withValues(alpha: 0.12),
              child:
                  const Icon(Icons.shield_outlined, color: AppTheme.sageDeep),
            ),
            title: const LowercaseText('barriers in place'),
            subtitle: LowercaseText(
              '${settings.activeBlockCount} of 5 active — ${blockPrompt.message}',
              style: const TextStyle(color: AppTheme.inkPlumSoft),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenBlocks,
          ),
          Divider(
            height: 1,
            color: AppTheme.stitchBorder.withValues(alpha: 0.6),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppTheme.lavenderLight,
              child: Icon(Icons.insights_outlined, color: AppTheme.lavenderDeep),
            ),
            title: const LowercaseText('urge patterns'),
            subtitle: LowercaseText(
              urgeSubtitle,
              style: const TextStyle(color: AppTheme.inkPlumSoft),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenUrges,
          ),
        ],
      ),
    );
  }
}

class _DebtHelpLinkTile extends StatelessWidget {
  const _DebtHelpLinkTile({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppTheme.lavenderLight,
          child: const Icon(
            Icons.support_agent_outlined,
            color: AppTheme.lavenderDeep,
          ),
        ),
        title: const LowercaseText('debt help & money advice'),
        subtitle: const LowercaseText(
          'free, confidential support — StepChange, National Debtline, and more',
          style: TextStyle(color: AppTheme.inkPlumSoft),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.controller,
    required this.label,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '£ ',
        border: const OutlineInputBorder(),
      ),
      onFieldSubmitted: onSubmitted,
    );
  }
}

double? _parseAmount(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

final _urgesProvider = StreamProvider.family<List<UrgeLog>, String>((ref, userId) {
  return ref.watch(urgeRepositoryProvider).watchUserUrges(userId);
});
