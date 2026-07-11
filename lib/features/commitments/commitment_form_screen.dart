import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_widgets.dart';
import '../../domain/models/commitment.dart';
import '../../domain/models/enums.dart';

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
  final _domainsController = TextEditingController(text: 'bet365.com, paddypower.com');
  final _appsController = TextEditingController(text: 'Bet365, William Hill');
  final _maxSpendController = TextEditingController();
  int _geofenceRadius = 200;
  bool _loading = false;
  bool _initialized = false;

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
        final existing = commitments.firstWhere((c) => c.id == widget.commitmentId);
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
          showAppSnackBar(context, 'goal created — detection is now active');
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
      final commitmentsAsync = ref.watch(_commitmentsProvider(user.id));
      commitmentsAsync.whenData((commitments) {
        final match = commitments.where((c) => c.id == widget.commitmentId);
        if (match.isNotEmpty) {
          _populateFromCommitment(match.first);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: LowercaseText(widget.isEditing ? 'edit goal' : 'new goal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
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
            const LowercaseText('type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<CommitmentType>(
              segments: CommitmentType.values
                  .map((t) => ButtonSegment(value: t, label: LowercaseText(t.label)))
                  .toList(),
              selected: {_type},
              onSelectionChanged: widget.isEditing
                  ? null
                  : (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 24),
            if (_type == CommitmentType.location) ...[
              LowercaseText('geofence radius: ${_geofenceRadius}m'),
              Slider(
                value: _geofenceRadius.toDouble(),
                min: 100,
                max: 500,
                divisions: 8,
                label: '${_geofenceRadius}m',
                onChanged: (v) => setState(() => _geofenceRadius = v.round()),
              ),
            ],
            if (_type == CommitmentType.online) ...[
              TextFormField(
                controller: _appsController,
                decoration: const InputDecoration(
                  labelText: 'blocked apps (comma-separated)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _domainsController,
                decoration: const InputDecoration(
                  labelText: 'blocked domains (comma-separated)',
                ),
              ),
            ],
            if (_type == CommitmentType.spending) ...[
              TextFormField(
                controller: _maxSpendController,
                decoration: const InputDecoration(
                  labelText: 'max spend alert threshold (£)',
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
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : LowercaseText(widget.isEditing ? 'update goal' : 'save goal'),
            ),
          ],
        ),
      ),
    );
  }
}

final _commitmentsProvider =
    StreamProvider.family<List<Commitment>, String>((ref, userId) {
  return ref.watch(commitmentRepositoryProvider).watchUserCommitments(userId);
});
