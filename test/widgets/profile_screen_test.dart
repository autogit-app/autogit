import 'package:autogit/features/profile/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProfileScreen builds', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );
    expect(find.byType(ProfileScreen), findsOneWidget);
  });
  testWidgets('ProfileScreen has Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
