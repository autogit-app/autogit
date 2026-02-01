import 'dart:convert';

import 'package:http/http.dart' as http;

const _base = 'https://api.github.com';

Map<String, String> _headers(String? token) {
  final h = <String, String>{
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'AutoGit',
  };
  if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
  return h;
}

/// GET /users/:username
Future<Map<String, dynamic>> getUser(String login, {String? token}) async {
  final uri = Uri.parse('$_base/users/${Uri.encodeComponent(login)}');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200) {
    throw Exception('Failed to get user: ${response.statusCode}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// GET /repos/:owner/:repo/issues/:issue_number
Future<Map<String, dynamic>> getIssue({
  required String owner,
  required String repo,
  required int number,
  String? token,
}) async {
  final uri = Uri.parse('$_base/repos/$owner/$repo/issues/$number');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200) {
    throw Exception('Failed to get issue: ${response.statusCode}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// GET /repos/:owner/:repo/issues/:issue_number/comments
Future<List<Map<String, dynamic>>> getIssueComments({
  required String owner,
  required String repo,
  required int number,
  String? token,
}) async {
  final uri = Uri.parse(
    '$_base/repos/$owner/$repo/issues/$number/comments?per_page=100',
  );
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200) return [];
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// GET /repos/:owner/:repo/pulls/:pull_number
Future<Map<String, dynamic>> getPullRequest({
  required String owner,
  required String repo,
  required int number,
  String? token,
}) async {
  final uri = Uri.parse('$_base/repos/$owner/$repo/pulls/$number');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200) {
    throw Exception('Failed to get PR: ${response.statusCode}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Parse owner and repo from repository_url (e.g. https://api.github.com/repos/owner/repo)
void parseRepoUrl(
  String? repositoryUrl,
  void Function(String owner, String repo) onParsed,
) {
  if (repositoryUrl == null || repositoryUrl.isEmpty) return;
  final segments = Uri.parse(repositoryUrl).pathSegments;
  if (segments.length >= 2) {
    onParsed(segments[segments.length - 2], segments.last);
  }
}
