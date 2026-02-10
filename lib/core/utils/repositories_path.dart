import 'dart:io';

import 'package:path/path.dart' as p;

/// Returns the path to the "Repositories" folder in the user's home directory.
/// Used on Linux and Windows. On Android, local git is via Termux server (no path).
Future<String?> getRepositoriesPath() async {
  if (Platform.isAndroid) {
    return null; // Android uses Termux server; server uses ~/Repositories
  }
  String? home;
  if (Platform.isWindows) {
    home = Platform.environment['USERPROFILE'];
  } else {
    home = Platform.environment['HOME'];
  }
  if (home == null || home.isEmpty) return null;
  return p.join(home, 'Repositories');
}

bool get isDesktopOrWeb =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

bool get isAndroid => Platform.isAndroid;
