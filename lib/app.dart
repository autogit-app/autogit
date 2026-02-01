import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:autogit/core/core.dart';
import 'package:autogit/core/router/app_router.dart';

class AGApp extends ConsumerWidget {
  const AGApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorSchemeSeed = ref.watch(colorSchemeSeedProvider);

    Brightness effectiveBrightness;
    switch (themeMode) {
      case AppThemeMode.system:
        effectiveBrightness = MediaQuery.platformBrightnessOf(context);
        break;
      case AppThemeMode.light:
        effectiveBrightness = Brightness.light;
        break;
      case AppThemeMode.dark:
      case AppThemeMode.amoled:
        effectiveBrightness = Brightness.dark;
        break;
    }

    final useAmoled =
        themeMode == AppThemeMode.amoled &&
        effectiveBrightness == Brightness.dark;

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSchemeSeed,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: colorSchemeSeed,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
    );

    final amoledTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.dark(
        primary: colorSchemeSeed,
        onPrimary: Colors.white,
        secondary: colorSchemeSeed,
        onSecondary: Colors.white,
        surface: const Color(0xFF000000),
        onSurface: const Color(0xFFE6E6E6),
        surfaceContainerHighest: const Color(0xFF0D0D0D),
        onSurfaceVariant: const Color(0xFFB3B3B3),
        outline: const Color(0xFF404040),
        error: Colors.red.shade400,
        onError: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      cardColor: const Color(0xFF0D0D0D),
      dialogBackgroundColor: const Color(0xFF0D0D0D),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0D0D0D),
      ),
    );

    final themeModeForApp = switch (themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark || AppThemeMode.amoled => ThemeMode.dark,
    };

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AutoGit',
      theme: lightTheme,
      darkTheme: useAmoled ? amoledTheme : darkTheme,
      themeMode: themeModeForApp,
      routerConfig: appRouter,
    );
  }
}
