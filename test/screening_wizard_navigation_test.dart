import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:accountability_app/core/providers/repository_providers.dart';
import 'package:accountability_app/core/widgets/craft_widgets.dart';
import 'package:accountability_app/core/widgets/tactile_widgets.dart';
import 'package:accountability_app/data/repositories/mock_auth_repository.dart';
import 'package:accountability_app/data/repositories/mock_screening_repository.dart';
import 'package:accountability_app/domain/models/app_user.dart';
import 'package:accountability_app/features/screening/crisis_screen.dart';
import 'package:accountability_app/features/screening/screening_results_screen.dart';
import 'package:accountability_app/features/screening/screening_wizard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  late MockAuthRepository authRepository;
  late GoRouter testRouter;
  late AppUser testUser;

  setUp(() async {
    authRepository = MockAuthRepository();
    testUser = await authRepository.signIn(
      email: 'test@example.com',
      password: 'password',
    );
  });

  Widget buildTestApp({bool isRescreen = false}) {
    testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => ScreeningWizardScreen(isRescreen: isRescreen),
        ),
        GoRoute(
          path: '/screening/crisis',
          builder: (_, __) => const CrisisScreen(),
        ),
        GoRoute(
          path: '/screening/results',
          builder: (_, __) => const ScreeningResultsScreen(),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
        screeningRepositoryProvider.overrideWithValue(MockScreeningRepository()),
      ],
      child: MaterialApp.router(routerConfig: testRouter),
    );
  }

  Future<void> pumpUntilUserReady(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScreeningWizardScreen)),
    );
    while (container.read(currentUserProvider).valueOrNull == null) {
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> answerInstrument(
    WidgetTester tester, {
    required String instrumentTitle,
    required int optionsPerQuestion,
    required int questionCount,
  }) async {
    final card = find.ancestor(
      of: find.text(instrumentTitle),
      matching: find.byType(TactileCard),
    );
    final radios = find.descendant(
      of: card,
      matching: find.byType(RadioListTile<int>),
    );
    expect(radios, findsNWidgets(optionsPerQuestion * questionCount));
    for (var q = 0; q < questionCount; q++) {
      final index = q * optionsPerQuestion;
      await tester.ensureVisible(radios.at(index));
      await tester.tap(radios.at(index));
      await tester.pump();
    }
  }

  Future<void> tapPrimaryButton(WidgetTester tester, String label) async {
    final button = find.widgetWithText(ElevatedButton, label);
    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> advanceToSafetyStep(WidgetTester tester) async {
    await tapPrimaryButton(tester, 'next');

    await answerInstrument(
      tester,
      instrumentTitle: 'gambling severity (pgsi)',
      optionsPerQuestion: 4,
      questionCount: 9,
    );
    await tapPrimaryButton(tester, 'next');

    await answerInstrument(
      tester,
      instrumentTitle: 'low mood check (phq-2)',
      optionsPerQuestion: 4,
      questionCount: 2,
    );
    await answerInstrument(
      tester,
      instrumentTitle: 'anxiety check (gad-2)',
      optionsPerQuestion: 4,
      questionCount: 2,
    );
    await tapPrimaryButton(tester, 'next');

    await answerInstrument(
      tester,
      instrumentTitle: 'alcohol check (audit-c)',
      optionsPerQuestion: 5,
      questionCount: 3,
    );
    await tapPrimaryButton(tester, 'next');

    expect(find.text('safety check'), findsOneWidget);
    expect(find.text('finish'), findsOneWidget);
  }

  Future<void> selectSafetyAnswer(WidgetTester tester, int optionIndex) async {
    final card = find.ancestor(
      of: find.text('safety check'),
      matching: find.byType(TactileCard),
    );
    final radios = find.descendant(
      of: card,
      matching: find.byType(RadioListTile<int>),
    );
    expect(radios, findsNWidgets(4));
    await tester.tap(radios.at(optionIndex));
    await tester.pump();
  }

  testWidgets('required flow shows five progress dots', (tester) async {
    await pumpUntilUserReady(tester);

    final progress = tester.widget<StitchProgress>(find.byType(StitchProgress));
    expect(progress.count, 5);
  });

  testWidgets('safety step shows finish instead of next', (tester) async {
    await pumpUntilUserReady(tester);

    await advanceToSafetyStep(tester);

    expect(find.text('finish'), findsOneWidget);
    expect(find.text('next'), findsNothing);
  });

  testWidgets('finish on safety step routes to crisis for non-zero answer',
      (tester) async {
    await pumpUntilUserReady(tester);

    await advanceToSafetyStep(tester);

    await selectSafetyAnswer(tester, 1);
    await tapPrimaryButton(tester, 'finish');

    expect(testRouter.state.uri.path, '/screening/crisis');
    expect(find.byType(CrisisScreen), findsOneWidget);
    expect(find.text('you are not alone'), findsOneWidget);
  });

  testWidgets('finish on safety step routes to results for not at all answer',
      (tester) async {
    await pumpUntilUserReady(tester);

    await advanceToSafetyStep(tester);

    await selectSafetyAnswer(tester, 0);
    await tapPrimaryButton(tester, 'finish');

    expect(testRouter.state.uri.path, '/screening/results');
    expect(find.byType(ScreeningResultsScreen), findsOneWidget);
    expect(find.text('your check-in summary'), findsOneWidget);
  });
}
