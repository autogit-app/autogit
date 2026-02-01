import 'package:autogit/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppThemeMode', () {
    test('has four values', () {
      expect(AppThemeMode.values.length, 4);
    });
    test('contains amoled dark light system', () {
      expect(AppThemeMode.values, contains(AppThemeMode.amoled));
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
      expect(AppThemeMode.values, contains(AppThemeMode.light));
      expect(AppThemeMode.values, contains(AppThemeMode.system));
    });
  });

  group('themeModeProvider', () {
    testWidgets('reads initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              return const SizedBox();
            },
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      expect(container.read(themeModeProvider), isNotNull);
    });
  });

  group('colorSchemeSeedProvider', () {
    testWidgets('reads initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              return const SizedBox();
            },
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      expect(container.read(colorSchemeSeedProvider), isA<Color>());
    });
  });
}
