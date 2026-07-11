import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';
import 'widgets/commitment_type_tile.dart';

class CommitmentFormScreen extends ConsumerStatefulWidget {
  const CommitmentFormScreen({super.key, this.commitmentId});

  final String? commitmentId;

  bool get isEditing => commitmentId != null;

  @override
  ConsumerState<CommitmentFormScreen> createState() =>
      _CommitmentFormScreenState();
}

class _CommitmentFormScreenState extends ConsumerState<CommitmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  CommitmentType _type = CommitmentType.location;
  final _domainsController =
      TextEditingController(text: 'bet365.com, paddypower.com');
  final _appsController =
      TextEditingController(text: 'Bet365, William Hill');
  final _maxSpendController = TextEditingController();
  int _geofenceRadius = 200;
  bool _loading = false;
  bool _initialized = false;
  bool _loadFailed = false;

  @override
  void dispose() {
    _titleController.dispose();
    _domainsController.dispose();
    _appsController.dispose();
    _maxSpendController.dispose();
    super.dispose();
  }

  void _populateFromCommitment(Commitment c) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = c.title;
    _type = c.type;
    _geofenceRadius = c.rules.geofenceRadiusM;
    _appsController.text = c.rules.blockedApps.join(', ');
    _domainsController.text = c.rules.blockedDomains.join(', ');
    if (c.rules.maxSpend != null) {
      _maxSpendController.text = c.rules.maxSpend!.toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final rules = CommitmentRules(
        blockedApps: _appsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        blockedDomains: _domainsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        maxSpend: double.tryParse(_maxSpendController.text),
        geofenceRadiusM: _geofenceRadius,
      );

      if (widget.isEditing) {
        final commitments = await ref
            .read(commitmentRepositoryProvider)
            .watchUserCommitments(user.id)
            .first;
        final existing =
            commitments.firstWhere((c) => c.id == widget.commitmentId);
        await ref.read(commitmentRepositoryProvider).updateCommitment(
              Commitment(
                id: existing.id,
                userId: existing.userId,
                title: _titleController.text.trim(),
                type: _type,
                rules: rules,
                active: existing.active,
                createdAt: existing.createdAt,
              ),
            );
        if (mounted) {
          showAppSnackBar(context, 'goal updated');
          context.pop();
        }
      } else {
        await ref.read(commitmentRepositoryProvider).createCommitment(
              Commitment(
                id: '',
                userId: user.id,
                title: _titleController.text.trim(),
                type: _type,
                rules: rules,
                active: true,
                createdAt: DateTime.now(),
              ),
            );
        if (mounted) {
          showAppSnackBar(
              context, 'signed & sealed and we\'re watching out for you');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'could not save goal. please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    if (widget.isEditing && user != null) {
      ref.listen(_commitmentsProvider(user.id), (_, next) {
        next.when(
          data: (commitments) {
            final match =
                commitments.where((c) => c.id == widget.commitmentId);
            if (match.isNotEmpty) {
              if (!_initialized) {
                setState(() => _populateFromCommitment(match.first));
              }
            } else if (!_initialized) {
              setState(() => _loadFailed = true);
            }
          },
          error: (_, __) {
            if (!_initialized) setState(() => _loadFailed = true);
          },
          loading: () {},
        );
      });
    }

    if (widget.isEditing && !_initialized) {
      return Scaffold(
        appBar: AppBar(
          title: const LowercaseText('edit goal'),
        ),
        body: _loadFailed
            ? const Center(
                child: LowercaseText(
                  'could not load this goal',
                  style: TextStyle(color: AppTheme.inkPlumSoft),
                ),
              )
            : const LoadingView(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: LowercaseText(widget.isEditing ? 'edit goal' : 'new goal'),
      ),
      body: PaperBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              ContractCard(
                title: widget.isEditing
                    ? 'your commitment'
                    : 'a commitment to yourself',
                signedBy: user?.displayName,
                signaturePending: !widget.isEditing,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'title',
                        hintText: 'no betting shops or gambling apps',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'enter a title' : null,
                    ),
                    const SizedBox(height: 24),
                    const LowercaseText(
                      'type',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const LowercaseText(
                      'how should we watch out for you?',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.inkPlumSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < CommitmentType.values.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      CommitmentTypeTile(
                        type: CommitmentType.values[i],
                        selected: _type == CommitmentType.values[i],
                        enabled: !widget.isEditing,
                        onTap: () => setState(
                            () => _type = CommitmentType.values[i]),
                      ),
                    ],
                    if (widget.isEditing) ...[
                      const SizedBox(height: 8),
                      const LowercaseText(
                        'type can\'t be changed after signing',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.inkPlumSoft,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _TypeSpecificFields(
                        key: ValueKey(_type),
                        type: _type,
                        geofenceRadius: _geofenceRadius,
                        onGeofenceChanged: (v) =>
                            setState(() => _geofenceRadius = v),
                        appsController: _appsController,
                        domainsController: _domainsController,
                        maxSpendController: _maxSpendController,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.draw_outlined, size: 20),
            label: LowercaseText(
                widget.isEditing ? 'update goal' : 'sign it'),
          ),
        ),
      ),
    );
  }
}

class _TypeSpecificFields extends StatelessWidget {
  const _TypeSpecificFields({
    super.key,
    required this.type,
    required this.geofenceRadius,
    required this.onGeofenceChanged,
    required this.appsController,
    required this.domainsController,
    required this.maxSpendController,
  });

  final CommitmentType type;
  final int geofenceRadius;
  final ValueChanged<int> onGeofenceChanged;
  final TextEditingController appsController;
  final TextEditingController domainsController;
  final TextEditingController maxSpendController;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      CommitmentType.location => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: LowercaseText(
                    'geofence radius',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lavenderLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.stitchBorder),
                  ),
                  child: LowercaseText(
                    '${geofenceRadius}m',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lavenderDeep,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const LowercaseText(
              'how close triggers an alert',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.inkPlumSoft,
                height: 1.4,
              ),
            ),
            Slider(
              value: geofenceRadius.toDouble(),
              min: 100,
              max: 500,
              divisions: 8,
              label: '${geofenceRadius}m',
              onChanged: (v) => onGeofenceChanged(v.round()),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LowercaseText(
                  '100m',
                  style: TextStyle(fontSize: 12, color: AppTheme.inkPlumSoft),
                ),
                LowercaseText(
                  '500m',
                  style: TextStyle(fontSize: 12, color: AppTheme.inkPlumSoft),
                ),
              ],
            ),
          ],
        ),
      CommitmentType.online => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: appsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'blocked apps',
                hintText: 'Bet365, William Hill',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: domainsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'blocked domains',
                hintText: 'bet365.com, paddypower.com',
              ),
            ),
          ],
        ),
      CommitmentType.spending => TextFormField(
          controller: maxSpendController,
          decoration: const InputDecoration(
            labelText: 'spend alert threshold',
            prefixText: '£ ',
          ),
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final amount = double.tryParse(v);
            if (amount == null || amount <= 0) {
              return 'enter a positive number';
            }
            return null;
          },
        ),
    };
  }
}

final _commitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
  return ref.watch(commitmentRepositoryProvider).watchUserCommitments(userId);
});
