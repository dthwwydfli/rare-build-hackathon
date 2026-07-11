import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/utils/onboarding_prefs.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/commitments/commitment_form_screen.dart';
import '../../features/commitments/commitments_screen.dart';
import '../../features/groups/create_group_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/groups/join_group_screen.dart';
import '../../features/gamification/leaderboard_screen.dart';
import '../../features/gamification/stats_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/people/find_people_screen.dart';
import '../../features/settings/permissions_screen.dart';
import '../../features/support/breach_detail_screen.dart';
import '../../features/support/my_breaches_screen.dart';
import '../../features/tools/block_access_screen.dart';
import '../../features/urges/urge_insights_screen.dart';
import '../../features/urges/urge_log_screen.dart';
import '../notifications/notification_service.dart';
import 'app_shell.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final _authRefreshNotifierProvider = Provider<_AuthRefreshNotifier>((ref) {
  final notifier = _AuthRefreshNotifier();
  ref.listen(currentUserProvider, (_, __) => notifier.notify());
  ref.onDispose(notifier.dispose);
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = ref.watch(_authRefreshNotifierProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/onboarding',
    refreshListenable: authRefresh,
    redirect: (context, state) async {
      final authState = ref.read(currentUserProvider);
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/signup' ||
          location == '/onboarding';

      if (isLoading) return null;

      if (user == null) {
        if (location == '/onboarding') {
          final seen = await hasSeenOnboarding();
          if (seen) return '/login';
        }
        if (!isAuthRoute) return '/login';
        return null;
      }

      if (isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/commitments',
            builder: (context, state) => const CommitmentsScreen(),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/support',
            builder: (context, state) => const SupportInboxScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/commitments/new',
        builder: (context, state) => const CommitmentFormScreen(),
      ),
      GoRoute(
        path: '/commitments/:id/edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CommitmentFormScreen(commitmentId: id);
        },
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/people/find',
        builder: (context, state) => const FindPeopleScreen(),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/my-breaches',
        builder: (context, state) => const MyBreachesScreen(),
      ),
      GoRoute(
        path: '/breach/:eventId',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final groupId = state.uri.queryParameters['groupId'] ?? '';
          return BreachDetailScreen(eventId: eventId, groupId: groupId);
        },
      ),
      GoRoute(
<<<<<<< HEAD
        path: '/stats',
        builder: (context, state) => const StatsDetailScreen(),
=======
        path: '/tools/blocks',
        builder: (context, state) => const BlockAccessScreen(),
      ),
      GoRoute(
        path: '/urges/log',
        builder: (context, state) => const UrgeLogScreen(),
      ),
      GoRoute(
        path: '/urges/insights',
        builder: (context, state) => const UrgeInsightsScreen(),
>>>>>>> ba2564f (feat: block access and money feature)
      ),
    ],
  );
});
