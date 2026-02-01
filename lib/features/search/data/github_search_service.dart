import 'dart:convert';

import 'package:http/http.dart' as http;

/// GitHub Search API: repositories and users.
/// With token: 30 req/min; without: 10 req/min.
class GitHubSearchService {
  GitHubSearchService._();
  static final GitHubSearchService instance = GitHubSearchService._();

  static const _base = 'https://api.github.com';

  Future<GitHubSearchReposResult> searchRepositories(
    String query, {
    String? token,
    int perPage = 20,
  }) async {
    if (query.trim().isEmpty) {
      return GitHubSearchReposResult(items: [], totalCount: 0);
    }
    final uri = Uri.parse('$_base/search/repositories').replace(
      queryParameters: {
        'q': query.trim(),
        'per_page': perPage.toString(),
        'sort': 'stars',
      },
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'AutoGit',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items =
        (json['items'] as List<dynamic>?)
            ?.map(
              (e) => GitHubRepoSearchItem.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final totalCount = json['total_count'] as int? ?? 0;
    return GitHubSearchReposResult(items: items, totalCount: totalCount);
  }

  Future<GitHubSearchUsersResult> searchUsers(
    String query, {
    String? token,
    int perPage = 20,
  }) async {
    if (query.trim().isEmpty) {
      return GitHubSearchUsersResult(items: [], totalCount: 0);
    }
    final uri = Uri.parse('$_base/search/users').replace(
      queryParameters: {'q': query.trim(), 'per_page': perPage.toString()},
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'AutoGit',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Search failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items =
        (json['items'] as List<dynamic>?)
            ?.map(
              (e) => GitHubUserSearchItem.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final totalCount = json['total_count'] as int? ?? 0;
    return GitHubSearchUsersResult(items: items, totalCount: totalCount);
  }
}

class GitHubSearchReposResult {
  GitHubSearchReposResult({required this.items, required this.totalCount});
  final List<GitHubRepoSearchItem> items;
  final int totalCount;
}

class GitHubRepoSearchItem {
  GitHubRepoSearchItem({
    required this.fullName,
    required this.name,
    required this.ownerLogin,
    this.description,
    this.stargazersCount = 0,
    this.language,
  });
  final String fullName;
  final String name;
  final String ownerLogin;
  final String? description;
  final int stargazersCount;
  final String? language;

  static GitHubRepoSearchItem fromJson(Map<String, dynamic> json) {
    final fullName = json['full_name'] as String? ?? '';
    final parts = fullName.split('/');
    String ownerLogin = parts.isNotEmpty ? parts[0] : '';
    if (ownerLogin.isEmpty && json['owner'] is Map<String, dynamic>) {
      ownerLogin =
          ((json['owner'] as Map<String, dynamic>)['login'] as String?) ?? '';
    }
    final name = parts.length > 1 ? parts[1] : json['name'] as String? ?? '';
    return GitHubRepoSearchItem(
      fullName: fullName,
      name: name,
      ownerLogin: ownerLogin,
      description: json['description'] as String?,
      stargazersCount: json['stargazers_count'] as int? ?? 0,
      language: json['language'] as String?,
    );
  }
}

class GitHubSearchUsersResult {
  GitHubSearchUsersResult({required this.items, required this.totalCount});
  final List<GitHubUserSearchItem> items;
  final int totalCount;
}

class GitHubUserSearchItem {
  GitHubUserSearchItem({required this.login, this.avatarUrl, this.bio});
  final String login;
  final String? avatarUrl;
  final String? bio;

  static GitHubUserSearchItem fromJson(Map<String, dynamic> json) {
    return GitHubUserSearchItem(
      login: json['login'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }
}
