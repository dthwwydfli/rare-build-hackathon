import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/onboarding_prefs.dart';

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
      icon: Icons.shield_outlined,
      title: 'Stay accountable together',
      subtitle:
          'Make commitments, invite trusted friends, and get support when you need it most.',
    ),
    _OnboardingPage(
      icon: Icons.location_on_outlined,
      title: 'Location alerts',
      subtitle: 'Friends are notified when you are near casinos or betting shops.',
    ),
    _OnboardingPage(
      icon: Icons.phone_android_outlined,
      title: 'Online monitoring',
      subtitle: 'Detect gambling apps, websites, and spending patterns.',
    ),
    _OnboardingPage(
      icon: Icons.favorite_outline,
      title: 'Social support',
      subtitle: 'Friends can send encouragement when you struggle.',
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
      body: SafeArea(
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon,
                            size: 80, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
                        ),
                      ],
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
                    color: i == _currentPage
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
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
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _finish(toSignup: true),
                      child: const Text('Get started'),
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _finish(toSignup: false),
                    child: const Text('I already have an account'),
                  ),
                ],
              ),
            ),
          ],
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
