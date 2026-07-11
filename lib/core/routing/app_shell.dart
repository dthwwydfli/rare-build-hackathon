import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/support/support_inbox_screen.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/commitments')) return 1;
    if (location.startsWith('/financial-recovery')) return 2;
    if (location.startsWith('/support-hub') ||
        location.startsWith('/groups') ||
        location.startsWith('/leaderboard')) {
      return 3;
    }
    if (location.startsWith('/support') || location.startsWith('/breach')) {
      return 4;
    }
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/commitments');
      case 2:
        context.go('/financial-recovery');
      case 3:
        context.go('/support-hub');
      case 4:
        context.go('/support');
    }
  }

  Widget _alertsIcon({required IconData icon, required int count}) {
    if (count <= 0) return Icon(icon);
    return Badge(
      label: Text('$count'),
      child: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadAlertsCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'goals',
          ),
          const NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'finance',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'support',
          ),
          NavigationDestination(
            icon: _alertsIcon(icon: Icons.inbox_outlined, count: unreadCount),
            selectedIcon: _alertsIcon(icon: Icons.inbox, count: unreadCount),
            label: 'alerts',
          ),
        ],
      ),
    );
  }
}
