import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:autogit/core/providers/github.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

const _base = 'https://api.github.com';

Map<String, String> _headers(String? token) {
  final h = <String, String>{
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'AutoGit',
  };
  if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
  return h;
}

/// Stats derived from current user's repos.
final githubRepoStatsProvider = FutureProvider<GitHubRepoStats>((ref) async {
  final repos = await ref.watch(userReposProvider.future);
  int totalStars = 0;
  int totalForks = 0;
  int publicCount = 0;
  int privateCount = 0;
  for (final r in repos) {
    totalStars += r.stargazersCount;
    totalForks += r.forksCount;
    if (r.isPrivate) {
      privateCount++;
    } else {
      publicCount++;
    }
  }
  return GitHubRepoStats(
    repoCount: repos.length,
    publicRepoCount: publicCount,
    privateRepoCount: privateCount,
    totalStars: totalStars,
    totalForks: totalForks,
  );
});

class GitHubRepoStats {
  GitHubRepoStats({
    required this.repoCount,
    required this.publicRepoCount,
    required this.privateRepoCount,
    required this.totalStars,
    required this.totalForks,
  });
  final int repoCount;
  final int publicRepoCount;
  final int privateRepoCount;
  final int totalStars;
  final int totalForks;
}

/// Current user profile stats (from GET /user).
final githubUserStatsProvider = FutureProvider<GitHubUserStats?>((ref) async {
  final token = ref.watch(githubTokenProvider);
  final username = ref.watch(githubUsernameProvider);
  if (token == null || token.isEmpty || username == null || username.isEmpty) {
    return null;
  }
  try {
    final uri = Uri.parse('$_base/user');
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return GitHubUserStats(
      publicRepos: data['public_repos'] as int? ?? 0,
      followers: data['followers'] as int? ?? 0,
      following: data['following'] as int? ?? 0,
    );
  } catch (_) {
    return null;
  }
});

class GitHubUserStats {
  GitHubUserStats({
    required this.publicRepos,
    required this.followers,
    required this.following,
  });
  final int publicRepos;
  final int followers;
  final int following;
}
