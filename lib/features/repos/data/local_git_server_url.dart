import 'package:shared_preferences/shared_preferences.dart';

import 'package:autogit/features/repos/data/termux_local_repo_service.dart';

const String _kLocalGitServerUrlKey = 'local_git_server_url';

/// Loads the saved Local Git Server URL (Android / remote server).
Future<String> loadLocalGitServerUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kLocalGitServerUrlKey) ?? kDefaultTermuxGitServerUrl;
}

/// Saves the Local Git Server URL. Call [invalidateLocalRepoService] after this.
Future<void> saveLocalGitServerUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLocalGitServerUrlKey, trimmed);
}
