import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../features/support/support_inbox_screen.dart';
import '../notifications/notification_service.dart';
import '../providers/repository_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/onboarding',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/onboarding';

      if (isLoading) return null;
      if (user == null && !isAuthRoute) return '/login';
      if (user != null && isAuthRoute) return '/home';
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
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/commitments',
        builder: (context, state) => const CommitmentsScreen(),
      ),
      GoRoute(
        path: '/commitments/new',
        builder: (context, state) => const CommitmentFormScreen(),
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const GroupsScreen(),
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
        path: '/support',
        builder: (context, state) => const SupportInboxScreen(),
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
        path: '/permissions',
        builder: (context, state) => const PermissionsScreen(),
      ),
      GoRoute(
        path: '/dev/simulator',
        builder: (context, state) => const BreachSimulatorScreen(),
      ),
    ],
  );
});
