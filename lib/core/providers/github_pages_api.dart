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

Map<String, String> _headersJson(String? token) {
  final h = _headers(token);
  h['Content-Type'] = 'application/json';
  return h;
}

/// GET /repos/:owner/:repo/pages - get Pages info. Throws if not configured.
Future<Map<String, dynamic>> getPages({
  required String owner,
  required String repo,
  String? token,
}) async {
  final uri = Uri.parse('$_base/repos/$owner/$repo/pages');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200) {
    throw Exception('Pages not configured or failed: ${response.statusCode}');
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// POST /repos/:owner/:repo/pages - enable/configure Pages.
/// source: { branch: 'main'|'gh-pages', path: '/'|'/docs' }
Future<void> createOrUpdatePages({
  required String owner,
  required String repo,
  required String branch,
  String path = '/',
  String? token,
}) async {
  if (token == null || token.isEmpty) {
    throw Exception('Token required to configure Pages');
  }
  final uri = Uri.parse('$_base/repos/$owner/$repo/pages');
  final body = jsonEncode({
    'source': {'branch': branch, 'path': path},
  });
  final response = await http.post(
    uri,
    headers: _headersJson(token),
    body: body,
  );
  if (response.statusCode != 201 && response.statusCode != 204) {
    throw Exception(
      'Failed to configure Pages: ${response.statusCode} ${response.body}',
    );
  }
}

/// Check if a repo has Pages enabled (returns url or null).
Future<String?> getPagesUrl({
  required String owner,
  required String repo,
  String? token,
}) async {
  try {
    final data = await getPages(owner: owner, repo: repo, token: token);
    final url = data['html_url'] as String?;
    return url;
  } catch (_) {
    return null;
  }
}
