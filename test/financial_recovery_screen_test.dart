import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:accountability_app/core/providers/repository_providers.dart';
import 'package:accountability_app/data/repositories/mock_access_block_repository.dart';
import 'package:accountability_app/data/repositories/mock_auth_repository.dart';
import 'package:accountability_app/data/repositories/mock_financial_recovery_repository.dart';
import 'package:accountability_app/data/repositories/mock_urge_repository.dart';
import 'package:accountability_app/domain/models/app_user.dart';
import 'package:accountability_app/features/financial_recovery/financial_recovery_screen.dart';
import 'package:accountability_app/features/help/professionals_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  late MockAuthRepository authRepository;
  late AppUser testUser;
  late MockFinancialRecoveryRepository financialRecoveryRepository;
  late MockAccessBlockRepository accessBlockRepository;
  late MockUrgeRepository urgeRepository;

  setUp(() async {
    authRepository = MockAuthRepository();
    testUser = await authRepository.signInWithGoogle();
    financialRecoveryRepository = MockFinancialRecoveryRepository();
    accessBlockRepository = MockAccessBlockRepository();
    urgeRepository = MockUrgeRepository();
  });

  Future<void> pumpFinancialRecovery(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      initialLocation: '/financial-recovery',
      routes: [
        GoRoute(
          path: '/financial-recovery',
          builder: (context, state) => const FinancialRecoveryScreen(),
        ),
        GoRoute(
          path: '/support-hub',
          builder: (context, state) => const Scaffold(
            body: GetHelpContent(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
          financialRecoveryRepositoryProvider
              .overrideWithValue(financialRecoveryRepository),
          accessBlockRepositoryProvider
              .overrideWithValue(accessBlockRepository),
          urgeRepositoryProvider.overrideWithValue(urgeRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows consolidated finance sections', (tester) async {
    await pumpFinancialRecovery(tester);

    expect(find.text('rebuilding step by step'), findsOneWidget);
    expect(find.text('money goals'), findsOneWidget);
    expect(find.text('save goals'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('budget & payday'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('budget & payday'), findsOneWidget);
    expect(find.text('save budget'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('barriers in place'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('barriers in place'), findsOneWidget);
    expect(find.text('urge patterns'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('debt help & money advice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('debt help & money advice'), findsOneWidget);
  });

  testWidgets('does not render inline debt resource cards', (tester) async {
    await pumpFinancialRecovery(tester);

    expect(find.text('StepChange'), findsNothing);
    expect(find.text('National Debtline'), findsNothing);
    expect(find.text('Money Helper'), findsNothing);
    expect(find.text('Citizens Advice'), findsNothing);
    expect(find.text('website'), findsNothing);
  });

  testWidgets('debt help link navigates to get help', (tester) async {
    await pumpFinancialRecovery(tester);

    await tester.scrollUntilVisible(
      find.text('debt help & money advice'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('debt help & money advice'));
    await tester.pumpAndSettle();

    expect(find.text('professional support when you need it'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('debt & money'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('debt & money'), findsOneWidget);
    expect(find.text('StepChange'), findsOneWidget);
  });
}
