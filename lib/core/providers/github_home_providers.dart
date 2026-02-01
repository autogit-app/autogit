import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autogit/core/providers/github_home_api.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = ref.watch(githubTokenProvider);
  return getNotifications(token);
});

final starredReposProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = ref.watch(githubTokenProvider);
  return getStarredRepos(token);
});

final watchedReposProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = ref.watch(githubTokenProvider);
  return getWatchedRepos(token);
});

final myIssuesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = ref.watch(githubTokenProvider);
  final username = ref.watch(githubUsernameProvider);
  return getIssues(token, username);
});

final myPullRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final token = ref.watch(githubTokenProvider);
  final username = ref.watch(githubUsernameProvider);
  return getPullRequests(token, username);
});
