import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:accountability_app/features/auth/login_screen.dart';
import 'package:accountability_app/features/auth/widgets/auth_shell.dart';
import 'package:accountability_app/features/auth/widgets/social_auth_buttons.dart';

void main() {
  testWidgets('login screen shows redesigned auth branding', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pump();

    expect(find.text('sign in'), findsWidgets);
    expect(find.text('email'), findsOneWidget);
    expect(find.text('password'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('create an account'), findsOneWidget);
    expect(find.text('lavender'), findsOneWidget);
    expect(
      find.text('start with 1000 points · every day counts'),
      findsNothing,
    );
    expect(find.byType(AuthShell), findsOneWidget);
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.shield_outlined), findsNothing);
  });
}
