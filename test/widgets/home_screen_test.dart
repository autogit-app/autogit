import 'package:autogit/features/home/ui/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen shows Welcome when not signed in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    expect(find.text('Welcome!'), findsOneWidget);
  });
  testWidgets('HomeScreen has Local Repositories', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    expect(find.text('Local Repositories'), findsOneWidget);
  });
  testWidgets('HomeScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
