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
import '../../features/groups/join_group_screen.dart';
import '../../features/gamification/stats_detail_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/people/find_people_screen.dart';
import '../../features/screening/crisis_screen.dart';
import '../../features/screening/screening_results_screen.dart';
import '../../features/screening/screening_wizard_screen.dart';
import '../../features/settings/permissions_screen.dart';
import '../../features/support/breach_detail_screen.dart';
import '../../features/support/my_breaches_screen.dart';
import '../../features/support/support_hub_screen.dart';
import '../../features/support/support_inbox_screen.dart';
import '../../features/tools/block_access_screen.dart';
import '../../features/urges/urge_insights_screen.dart';
import '../../features/urges/urge_log_screen.dart';
import '../notifications/notification_service.dart';
import 'app_shell.dart';

bool _isScreeningRoute(String location) {
  return location.startsWith('/screening') || location == '/crisis';
}

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

      final screeningRepo = ref.read(screeningRepositoryProvider);
      final screeningStatus = await screeningRepo.getStatus(user.id);
      final screeningComplete = screeningStatus.screeningCompleted;

      if (isAuthRoute) {
        if (!screeningComplete) return '/screening';
        return '/home';
      }

      if (!screeningComplete && !_isScreeningRoute(location)) {
        return '/screening';
      }

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
      GoRoute(
        path: '/screening',
        builder: (context, state) {
          final isRescreen = state.uri.queryParameters['mode'] == 'rescreen';
          return ScreeningWizardScreen(isRescreen: isRescreen);
        },
      ),
      GoRoute(
        path: '/screening/crisis',
        builder: (context, state) => const CrisisScreen(fromScreening: true),
      ),
      GoRoute(
        path: '/screening/results',
        builder: (context, state) => const ScreeningResultsScreen(),
      ),
      GoRoute(
        path: '/crisis',
        builder: (context, state) =>
            const CrisisScreen(fromScreening: false, allowBack: true),
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
            path: '/support-hub',
            builder: (context, state) {
              final segment = supportHubSegmentFromQuery(
                state.uri.queryParameters['segment'],
              );
              return SupportHubScreen(initialSegment: segment);
            },
          ),
          GoRoute(
            path: '/groups',
            redirect: (_, __) => '/support-hub',
          ),
          GoRoute(
            path: '/leaderboard',
            redirect: (_, __) => '/support-hub?segment=rankings',
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
        path: '/stats',
        builder: (context, state) => const StatsDetailScreen(),
      ),
      GoRoute(
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
      ),
    ],
  );
});
