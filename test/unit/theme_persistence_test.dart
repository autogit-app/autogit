import 'package:autogit/core/providers/providers.dart';
import 'package:autogit/core/providers/theme_persistence.dart' as tp;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    tp.ThemePersistence.themeModeOverride = null;
    tp.ThemePersistence.colorSeedOverride = null;
  });

  group('ThemePersistence static', () {
    test('themeModeOverride is null initially', () {
      expect(tp.ThemePersistence.themeModeOverride, isNull);
    });
    test('colorSeedOverride is null initially', () {
      expect(tp.ThemePersistence.colorSeedOverride, isNull);
    });
    test('can set themeModeOverride', () {
      tp.ThemePersistence.themeModeOverride = AppThemeMode.dark;
      expect(tp.ThemePersistence.themeModeOverride, AppThemeMode.dark);
    });
    test('can set colorSeedOverride', () {
      tp.ThemePersistence.colorSeedOverride = Colors.blue;
      expect(tp.ThemePersistence.colorSeedOverride, Colors.blue);
    });
  });

  group('saveThemeMode loadThemeFromPrefs', () {
    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
    });
    test('saveThemeMode then loadThemeFromPrefs restores mode', () async {
      await tp.saveThemeMode(AppThemeMode.amoled);
      tp.ThemePersistence.themeModeOverride = null;
      await tp.loadThemeFromPrefs();
      expect(tp.ThemePersistence.themeModeOverride, AppThemeMode.amoled);
    });
    test('saveColorSeed then loadThemeFromPrefs restores color', () async {
      await tp.saveColorSeed(Colors.purple);
      tp.ThemePersistence.colorSeedOverride = null;
      await tp.loadThemeFromPrefs();
      expect(tp.ThemePersistence.colorSeedOverride, Colors.purple);
    });
  });
}
