import 'package:autogit/features/search/ui/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SearchScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SearchScreen())),
    );
    expect(find.byType(SearchScreen), findsOneWidget);
  });
  testWidgets('SearchScreen has search or app bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SearchScreen())),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
