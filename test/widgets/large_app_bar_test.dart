import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LargeAppBar shows title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [const LargeAppBar(title: 'Test Title')],
          ),
        ),
      ),
    );
    expect(find.text('Test Title'), findsOneWidget);
  });

  testWidgets('LargeAppBar has SliverAppBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(slivers: [const LargeAppBar(title: 'Title')]),
        ),
      ),
    );
    expect(find.byType(SliverAppBar), findsOneWidget);
  });

  testWidgets('LargeAppBar with empty title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(slivers: [const LargeAppBar(title: '')]),
        ),
      ),
    );
    expect(find.byType(LargeAppBar), findsOneWidget);
  });

  testWidgets('LargeAppBar with actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              LargeAppBar(
                title: 'Title',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
