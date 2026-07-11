import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:accountability_app/core/providers/repository_providers.dart';
import 'package:accountability_app/data/repositories/mock_auth_repository.dart';
import 'package:accountability_app/data/repositories/mock_screening_repository.dart';
import 'package:accountability_app/domain/models/app_user.dart';
import 'package:accountability_app/features/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  late MockAuthRepository authRepository;
  late AppUser testUser;

  setUp(() async {
    authRepository = MockAuthRepository();
    testUser = await authRepository.signInWithGoogle();
  });

  Future<void> pumpHome(
    WidgetTester tester, {
    required Size viewport,
    EdgeInsets safePadding = const EdgeInsets.only(top: 44, bottom: 34),
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          currentUserProvider.overrideWith((ref) => Stream.value(testUser)),
          screeningRepositoryProvider.overrideWithValue(
            MockScreeningRepository(),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: viewport,
              padding: safePadding,
              disableAnimations: true,
            ),
            child: Column(
              children: [
                const Expanded(child: HomeScreen()),
                NavigationBar(
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      label: 'home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.flag_outlined),
                      label: 'goals',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_outline),
                      label: 'support',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inbox_outlined),
                      label: 'alerts',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool _isVisibleInListViewport(WidgetTester tester, Finder finder) {
    final target = tester.renderObject<RenderBox>(finder);
    final listView = tester.renderObject<RenderBox>(find.byType(ListView));

    final targetTop = target.localToGlobal(Offset.zero).dy;
    final targetBottom = targetTop + target.size.height;
    final viewportTop = listView.localToGlobal(Offset.zero).dy;
    final viewportBottom = viewportTop + listView.size.height;

    return targetTop >= viewportTop && targetBottom <= viewportBottom + 1;
  }

  testWidgets('safety cards appear before positive reminder in layout order',
      (tester) async {
    await pumpHome(tester, viewport: const Size(390, 844));

    final help = find.text('help');
    final flag = find.text('flag');
    final reminder = find.text('positive reminder');

    expect(help, findsOneWidget);
    expect(flag, findsOneWidget);
    expect(reminder, findsOneWidget);

    final helpY = tester.getTopLeft(help).dy;
    final flagY = tester.getTopLeft(flag).dy;
    final reminderY = tester.getTopLeft(reminder).dy;

    expect(helpY, lessThan(reminderY));
    expect(flagY, lessThan(reminderY));
  });

  testWidgets('crisis and flag buttons visible without scroll on iPhone SE',
      (tester) async {
    await pumpHome(tester, viewport: const Size(375, 667));

    expect(_isVisibleInListViewport(tester, find.text('help')), isTrue);
    expect(_isVisibleInListViewport(tester, find.text('flag')), isTrue);
  });

  testWidgets('crisis and flag buttons visible without scroll on iPhone 14',
      (tester) async {
    await pumpHome(tester, viewport: const Size(390, 844));

    expect(_isVisibleInListViewport(tester, find.text('help')), isTrue);
    expect(_isVisibleInListViewport(tester, find.text('flag')), isTrue);
  });

  testWidgets('home AppBar shows stats and settings but not logout',
      (tester) async {
    await pumpHome(tester, viewport: const Size(390, 844));

    expect(find.byIcon(Icons.bar_chart_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsNothing);
  });
}
