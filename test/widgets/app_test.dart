import 'package:autogit/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AGApp builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AGApp()));
    expect(find.byType(AGApp), findsOneWidget);
  });

  testWidgets('AGApp uses MaterialApp when wrapped in ProviderScope', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: AGApp()));
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('AGApp has title AutoGit', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AGApp()));
    await tester.pump();
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'AutoGit');
  });
}
