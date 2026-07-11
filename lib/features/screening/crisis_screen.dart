import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/providers/screening_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import 'widgets/crisis_resource_panel.dart';

class CrisisScreen extends ConsumerStatefulWidget {
  const CrisisScreen({
    super.key,
    this.fromScreening = true,
    this.allowBack = false,
  });

  final bool fromScreening;
  final bool allowBack;

  @override
  ConsumerState<CrisisScreen> createState() => _CrisisScreenState();
}

class _CrisisScreenState extends ConsumerState<CrisisScreen> {
  bool _acknowledged = false;
  bool _saving = false;

  Future<void> _continueAfterAcknowledge() async {
    if (!_acknowledged) return;

    if (widget.fromScreening) {
      final result = ref.read(screeningSessionProvider).result;
      final user = ref.read(currentUserProvider).valueOrNull;
      if (result != null && user != null) {
        setState(() => _saving = true);
        try {
          final saved =
              await ref.read(screeningRepositoryProvider).saveResult(result);
          ref.read(screeningSessionProvider.notifier).setResult(saved);
        } finally {
          if (mounted) setState(() => _saving = false);
        }
      }
      if (mounted) context.go('/screening/results');
    } else if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.allowBack,
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Column(
              children: [
                if (widget.allowBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const StampBadge(
                        label: 'help now',
                        icon: Icons.emergency_outlined,
                        size: 88,
                        color: AppTheme.granola,
                        seed: 'crisis',
                      ),
                      const SizedBox(height: 16),
                      LowercaseText(
                        widget.fromScreening
                            ? 'you are not alone'
                            : 'need help right now?',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const LowercaseText(
                        'if you are thinking about hurting yourself, please reach out now. trained counselors are available 24/7 and it is free and confidential.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.inkPlumSoft, height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.granola.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.granola.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const LowercaseText(
                          'if you are in immediate danger, call 999.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.granola,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const CrisisResourcePanel(),
                      const SizedBox(height: 24),
                      CheckboxListTile(
                        value: _acknowledged,
                        onChanged: (v) =>
                            setState(() => _acknowledged = v ?? false),
                        title: const LowercaseText(
                          "i've seen these options and know who to call",
                          style: TextStyle(height: 1.3),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: _acknowledged && !_saving
                        ? _continueAfterAcknowledge
                        : null,
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : LowercaseText(
                            widget.fromScreening ? 'continue' : 'done',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
