import 'package:autogit/features/auth/ui/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthScreen shows Authentication heading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    expect(find.text('Authentication'), findsOneWidget);
  });

  testWidgets('AuthScreen has sign in with GitHub button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    expect(find.text('Continue with GitHub'), findsOneWidget);
  });

  testWidgets('AuthScreen has proceed without sign in option', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    expect(find.text('Proceed without Sign In'), findsOneWidget);
  });

  testWidgets('AuthScreen has Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('AuthScreen has SafeArea', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    expect(find.byType(SafeArea), findsOneWidget);
  });

  testWidgets('AuthScreen builds without throwing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
