import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/auth_error_helper.dart';
import '../../core/utils/permissions_helper.dart';
import '../../core/widgets/app_widgets.dart';
import 'widgets/auth_shell.dart';
import 'widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterAuth() async {
    if (!mounted) return;
    final needsPerms = await needsPermissionsSetup();
    context.go(needsPerms ? '/permissions' : '/home');
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      await _navigateAfterAuth();
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      await _navigateAfterAuth();
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      await _navigateAfterAuth();
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !isValidEmail(email)) {
      setState(() => _error = 'enter a valid email to reset your password');
      return;
    }
    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      if (mounted) {
        showAppSnackBar(context, 'check your email for a reset link');
      }
    } catch (e) {
      setState(() => _error = friendlyAuthError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'sign in',
      teaserLine: null,
      footer: TextButton(
        onPressed: () => context.go('/signup'),
        child: const LowercaseText('create an account'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'email'),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'enter your email';
                if (!isValidEmail(v)) return 'enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'password'),
              obscureText: true,
              validator: (v) =>
                  v == null || v.isEmpty ? 'enter your password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading ? null : _resetPassword,
                child: const LowercaseText('forgot password?'),
              ),
            ),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: _loading ? null : _signIn,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const LowercaseText('sign in'),
            ),
            const SizedBox(height: 12),
            GoogleSignInButton(
              onPressed: _loading ? null : _signInWithGoogle,
              enabled: !_loading,
            ),
            if (AppleSignInButton.isSupported) ...[
              const SizedBox(height: 12),
              AppleSignInButton(
                text: 'Sign in with Apple',
                onPressed: _loading ? null : _signInWithApple,
                enabled: !_loading,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
