import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/repository_providers.dart';
import '../../core/utils/onboarding_prefs.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/commitments/commitment_form_screen.dart';
import '../../features/commitments/commitments_screen.dart';
import '../../features/dev/breach_simulator_screen.dart';
import '../../features/groups/create_group_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/groups/join_group_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/permissions_screen.dart';
import '../../features/support/breach_detail_screen.dart';
import '../../features/support/my_breaches_screen.dart';
import '../../features/support/support_inbox_screen.dart';
import '../notifications/notification_service.dart';
import 'app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/onboarding',
    redirect: (context, state) async {
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
        path: '/dev/simulator',
        builder: (context, state) => const BreachSimulatorScreen(),
      ),
    ],
  );
});
