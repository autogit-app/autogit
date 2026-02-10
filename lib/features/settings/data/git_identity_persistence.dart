import 'package:shared_preferences/shared_preferences.dart';

const String _kGitUserNameKey = 'git_user_name';
const String _kGitUserEmailKey = 'git_user_email';

/// Loads the saved Git user name (for commits when not using GitHub identity).
Future<String> loadGitUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kGitUserNameKey) ?? '';
}

/// Loads the saved Git user email (for commits when not using GitHub identity).
Future<String> loadGitUserEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kGitUserEmailKey) ?? '';
}

/// Saves the Git user name.
Future<void> saveGitUserName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kGitUserNameKey, name.trim());
}

/// Saves the Git user email.
Future<void> saveGitUserEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kGitUserEmailKey, email.trim());
}
