import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/onboarding_prefs.dart';
import '../../core/widgets/tactile_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.spa_outlined,
      title: 'stay accountable together',
      subtitle:
          'make commitments, invite trusted friends, and get support when you need it most.',
      showWordmark: true,
    ),
    _OnboardingPage(
      icon: Icons.location_on_outlined,
      title: 'location alerts',
      subtitle: 'friends are notified when you are near casinos or betting shops.',
    ),
    _OnboardingPage(
      icon: Icons.phone_android_outlined,
      title: 'online monitoring',
      subtitle: 'detect gambling apps, websites, and spending patterns.',
    ),
    _OnboardingPage(
      icon: Icons.favorite_outline,
      title: 'social support',
      subtitle: 'friends can send encouragement when you struggle.',
    ),
    _OnboardingPage(
      icon: Icons.emoji_events_outlined,
      title: 'earn your rank',
      subtitle:
          'build points, keep streaks alive, and climb friend and global leaderboards.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool toSignup}) async {
    await markOnboardingSeen();
    if (!mounted) return;
    context.go(toSignup ? '/signup' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: TactileCard(
                        useStitch: true,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (page.showWordmark) ...[
                              const BrandWordmark(size: 28),
                              const SizedBox(height: 24),
                            ],
                            Icon(page.icon, size: 72, color: AppTheme.lavender),
                            const SizedBox(height: 16),
                            const OrnamentalDivider(),
                            const SizedBox(height: 16),
                            LowercaseText(
                              page.title,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.lavenderDark,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            LowercaseText(
                              page.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.granolaDark.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentPage ? AppTheme.lavender : AppTheme.lavenderLight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_currentPage < _pages.length - 1)
                      ElevatedButton(
                        onPressed: () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const LowercaseText('next'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => _finish(toSignup: true),
                        child: const LowercaseText('get started'),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _finish(toSignup: false),
                      child: const LowercaseText('i already have an account'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showWordmark = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showWordmark;
}
