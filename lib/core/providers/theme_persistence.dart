import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autogit/core/providers/providers.dart';

const _keyThemeMode = 'app_theme_mode';
const _keyColorSeed = 'app_color_seed';

Future<void> loadThemeFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final modeIndex = prefs.getInt(_keyThemeMode);
  final colorValue = prefs.getInt(_keyColorSeed);
  if (modeIndex != null &&
      modeIndex >= 0 &&
      modeIndex < AppThemeMode.values.length) {
    ThemePersistence.themeModeOverride = AppThemeMode.values[modeIndex];
  }
  if (colorValue != null) {
    ThemePersistence.colorSeedOverride = Color(colorValue);
  }
}

Future<void> saveThemeMode(AppThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyThemeMode, mode.index);
}

Future<void> saveColorSeed(Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyColorSeed, color.value);
}

abstract class ThemePersistence {
  static AppThemeMode? themeModeOverride;
  static Color? colorSeedOverride;
}
