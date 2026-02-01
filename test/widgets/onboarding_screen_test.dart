import 'package:autogit/features/onboarding/ui/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('OnboardingScreen shows Welcome to AutoGit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('Welcome to AutoGit!'), findsOneWidget);
  });
  testWidgets('OnboardingScreen has Scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
  testWidgets('OnboardingScreen has Get Started title on last page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pump();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pump();
    expect(find.text('Get Started'), findsOneWidget);
  });
}
