import 'package:flutter/material.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tactile_widgets.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.teaserLine,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final String? teaserLine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AuthHeader(subtitle: subtitle),
                    const SizedBox(height: 24),
                    StitchedBorder(
                      child: TactileCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LowercaseText(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lavenderDeep,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            child,
                          ],
                        ),
                      ),
                    ),
                    if (teaserLine != null) ...[
                      const SizedBox(height: 16),
                      AuthTeaser(line: teaserLine!),
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandWordmark(size: 32),
        const SizedBox(height: 8),
        const OrnamentalDivider(width: 80),
        const SizedBox(height: 8),
        LowercaseText(
          subtitle ?? 'one day at a time, together.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.inkPlumSoft,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class AuthTeaser extends StatelessWidget {
  const AuthTeaser({super.key, required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.granolaLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.granola.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.spa_outlined, size: 18, color: AppTheme.sageDeep),
          const SizedBox(width: 8),
          const Icon(Icons.favorite_outline, size: 18, color: AppTheme.terracotta),
          const SizedBox(width: 8),
          Flexible(
            child: LowercaseText(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.sageDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
