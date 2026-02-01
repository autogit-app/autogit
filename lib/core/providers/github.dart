import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';

import 'package:autogit/features/auth/providers/auth_provider.dart';

GitHub _createClient(String? token) {
  if (token != null && token.isNotEmpty) {
    return GitHub(auth: Authentication.withToken(token));
  }
  return GitHub();
}

Future<List<Repository>> getUserRepos(String? token, String username) async {
  if (username.isEmpty) return [];
  final github = _createClient(token);
  return github.repositories.listUserRepositories(username).toList();
}

Future<RepositoryContents> getRepositoryContents(
  String? token,
  String owner,
  String name,
  String path,
) async {
  final github = _createClient(token);
  return github.repositories.getContents(RepositorySlug(owner, name), path);
}

/// Remote repositories for the current user. Empty if not signed in with GitHub.
final userReposProvider = FutureProvider<List<Repository>>((ref) async {
  final token = ref.watch(githubTokenProvider);
  final username = ref.watch(githubUsernameProvider);
  if (username == null || username.isEmpty) return [];
  return getUserRepos(token, username);
});

/// Legacy provider name for compatibility.
final repoProvider = userReposProvider;

Future<Repository> createRepo(String? token, String name) async {
  final github = _createClient(token);
  return github.repositories.createRepository(CreateRepository(name));
}

Future<bool> deleteRepo(String? token, RepositorySlug slug) async {
  final github = _createClient(token);
  return github.repositories.deleteRepository(slug);
}
