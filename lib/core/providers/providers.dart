import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:autogit/core/providers/theme_persistence.dart';

final isHomeLocalProvider = StateProvider<bool>(((ref) => false));

/// Theme mode like Mihon/Tachiyomi: AMOLED (pure black), Dark, Light, System.
enum AppThemeMode { amoled, dark, light, system }

/// Default: light. Initial value from ThemePersistence after loadThemeFromPrefs() in main.
final themeModeProvider = StateProvider<AppThemeMode>((ref) {
  return ThemePersistence.themeModeOverride ?? AppThemeMode.light;
});

final colorSchemeSeedProvider = StateProvider<Color>((ref) {
  return ThemePersistence.colorSeedOverride ?? Colors.blue;
});

final brightnessProvider = StateProvider<Brightness>((ref) {
  return Brightness.dark;
});
