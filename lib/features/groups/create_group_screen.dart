import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/craft_widgets.dart';
import '../../core/widgets/tactile_widgets.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final group = await ref.read(groupRepositoryProvider).createGroup(
            name: _nameController.text.trim(),
            ownerId: user.id,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const LowercaseText('group created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LowercaseText('share this invite code with friends:'),
              const SizedBox(height: 12),
              SizedBox(
                width: 300,
                child: TicketStub(
                  code: group.inviteCode,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: group.inviteCode));
                    showAppSnackBar(context, 'code copied');
                  },
                ).stampIn(context),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.inviteCode));
                showAppSnackBar(context, 'code copied');
              },
              child: const LowercaseText('copy code'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const LowercaseText('done'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = 'could not create group. please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LowercaseText('create group')),
      body: PaperBackground(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'group name',
                  hintText: 'my support circle',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'enter a group name' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _create,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const LowercaseText('create group'),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
