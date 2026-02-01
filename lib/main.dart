import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:autogit/app.dart';
import 'package:autogit/core/providers/theme_persistence.dart';
import 'package:autogit/features/auth/data/github_auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterGemma.initialize(maxDownloadRetries: 10);
  await GitHubAuthService.init();
  await loadThemeFromPrefs();
  runApp(const ProviderScope(child: AGApp()));
}
