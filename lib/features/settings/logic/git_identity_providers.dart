import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autogit/core/providers/github_user_issue_pr_api.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/settings/data/git_identity_persistence.dart';

/// Effective Git user name for commits: stored value, or GitHub username when signed in.
final effectiveGitUserNameProvider = FutureProvider<String?>((ref) async {
  final stored = await loadGitUserName();
  if (stored.isNotEmpty) return stored;
  final username = ref.watch(githubUsernameProvider);
  return username;
});

/// Effective Git user email for commits: stored value, or GitHub email when signed in.
final effectiveGitUserEmailProvider = FutureProvider<String?>((ref) async {
  final stored = await loadGitUserEmail();
  if (stored.isNotEmpty) return stored;
  final token = ref.watch(githubTokenProvider);
  if (token == null || token.isEmpty) return null;
  try {
    final user = await getCurrentUser(token);
    final email = user['email'] as String?;
    return email?.isNotEmpty == true ? email : null;
  } catch (_) {
    return null;
  }
});

/// Invalidates git identity providers (e.g. after saving in settings).
final gitIdentityInvalidatorProvider = Provider<void Function()>((ref) {
  return () {
    ref.invalidate(effectiveGitUserNameProvider);
    ref.invalidate(effectiveGitUserEmailProvider);
  };
});
