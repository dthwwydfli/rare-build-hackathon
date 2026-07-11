import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/notification_service.dart';
import 'core/providers/repository_providers.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/detection/detection_coordinator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: AccountabilityApp()));
}

class AccountabilityApp extends ConsumerStatefulWidget {
  const AccountabilityApp({super.key});

  @override
  ConsumerState<AccountabilityApp> createState() => _AccountabilityAppState();
}

class _AccountabilityAppState extends ConsumerState<AccountabilityApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    if (!useMockAuth) {
      await ref.read(notificationServiceProvider).initialize();
    }
    ref.read(detectionCoordinatorProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Accountability',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
