import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:accountability_app/main.dart';

void main() {
  testWidgets('App loads onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AccountabilityApp()));
    await tester.pumpAndSettle();
    expect(find.text('Stay accountable together'), findsOneWidget);
  });
}
