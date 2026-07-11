import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_widgets.dart';

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(groupRepositoryProvider).joinGroupByInviteCode(
            inviteCode: _codeController.text.trim().toUpperCase(),
            userId: user.id,
          );
      if (mounted) {
        showAppSnackBar(context, 'joined group successfully');
        context.pop();
      }
    } catch (e) {
      setState(() => _error = 'invalid invite code — ask your friend to share again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LowercaseText('join group')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LowercaseText(
              'enter the 6-character invite code shared by your friend.',
              style: TextStyle(color: AppTheme.granolaDark.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'invite code',
                hintText: 'ABC123',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _join,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const LowercaseText('join group'),
            ),
          ],
        ),
      ),
    );
  }
}
