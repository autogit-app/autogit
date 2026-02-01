import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autogit/features/auth/data/auth_state.dart';

/// Single auth state provider. Invalidate this after login/logout to refresh UI.
final authStateProvider = Provider<AuthStateSnapshot>((ref) {
  return AuthStateSnapshot(
    hasToken: AuthState.hasToken,
    isAuthenticated: AuthState.isAuthenticated,
    username: AuthState.username,
    avatarUrl: AuthState.avatarUrl,
    token: AuthState.token,
  );
});

/// Snapshot of auth state for UI.
class AuthStateSnapshot {
  const AuthStateSnapshot({
    required this.hasToken,
    required this.isAuthenticated,
    this.username,
    this.avatarUrl,
    this.token,
  });
  final bool hasToken;
  final bool isAuthenticated;
  final String? username;
  final String? avatarUrl;
  final String? token;
}

/// Whether the user is signed in with GitHub (has token).
final isSignedInWithGitHubProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).hasToken;
});

/// Whether the user can use the app (signed in or anonymous).
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

/// Current GitHub username, or null if not signed in with GitHub.
final githubUsernameProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).username;
});

/// Current GitHub avatar URL, or null if not signed in.
final githubAvatarUrlProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).avatarUrl;
});

/// Stored GitHub token for API calls. Null if not signed in with GitHub.
final githubTokenProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).token;
});
