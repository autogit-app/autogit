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

/// List branches. Returns list of { name, commit: { sha } }.
Future<List<Map<String, dynamic>>> listBranches({
  required String owner,
  required String repo,
  String? token,
}) async {
  final uri = Uri.parse('$_base/repos/$owner/$repo/branches?per_page=100');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200)
    throw Exception('Failed to list branches: ${response.statusCode}');
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// Create a branch (create ref from head sha).
Future<void> createBranch({
  required String owner,
  required String repo,
  required String branchName,
  required String fromSha,
  String? token,
}) async {
  if (token == null || token.isEmpty)
    throw Exception('Token required to create branch');
  final uri = Uri.parse('$_base/repos/$owner/$repo/git/refs');
  final body = jsonEncode({'ref': 'refs/heads/$branchName', 'sha': fromSha});
  final response = await http.post(
    uri,
    headers: _headersJson(token),
    body: body,
  );
  if (response.statusCode != 201)
    throw Exception(
      'Failed to create branch: ${response.statusCode} ${response.body}',
    );
}

/// Create an issue.
Future<Map<String, dynamic>> createIssue({
  required String owner,
  required String repo,
  required String title,
  String? body,
  String? token,
}) async {
  if (token == null || token.isEmpty)
    throw Exception('Token required to create issue');
  final uri = Uri.parse('$_base/repos/$owner/$repo/issues');
  final bodyJson = jsonEncode({'title': title, 'body': body ?? ''});
  final response = await http.post(
    uri,
    headers: _headersJson(token),
    body: bodyJson,
  );
  if (response.statusCode != 201)
    throw Exception(
      'Failed to create issue: ${response.statusCode} ${response.body}',
    );
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// Create a pull request.
Future<Map<String, dynamic>> createPullRequest({
  required String owner,
  required String repo,
  required String title,
  String? body,
  required String head,
  required String base,
  String? token,
}) async {
  if (token == null || token.isEmpty)
    throw Exception('Token required to create PR');
  final uri = Uri.parse('$_base/repos/$owner/$repo/pulls');
  final bodyJson = jsonEncode({
    'title': title,
    'body': body ?? '',
    'head': head,
    'base': base,
  });
  final response = await http.post(
    uri,
    headers: _headersJson(token),
    body: bodyJson,
  );
  if (response.statusCode != 201)
    throw Exception(
      'Failed to create PR: ${response.statusCode} ${response.body}',
    );
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// List pull requests for the repo.
Future<List<Map<String, dynamic>>> listPullRequests({
  required String owner,
  required String repo,
  String state = 'open',
  String? token,
}) async {
  final uri = Uri.parse(
    '$_base/repos/$owner/$repo/pulls?state=$state&per_page=30',
  );
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200)
    throw Exception('Failed to list PRs: ${response.statusCode}');
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// Merge a pull request.
Future<void> mergePullRequest({
  required String owner,
  required String repo,
  required int pullNumber,
  String? commitTitle,
  String? token,
}) async {
  if (token == null || token.isEmpty)
    throw Exception('Token required to merge PR');
  final uri = Uri.parse('$_base/repos/$owner/$repo/pulls/$pullNumber/merge');
  final body = jsonEncode(
    commitTitle != null ? {'commit_title': commitTitle} : <String, dynamic>{},
  );
  final response = await http.put(
    uri,
    headers: _headersJson(token),
    body: body,
  );
  if (response.statusCode != 200)
    throw Exception('Failed to merge: ${response.statusCode} ${response.body}');
}

/// Get repo info (default_branch, clone_url, ssh_url).
Future<Map<String, dynamic>> getRepo({
  required String owner,
  required String repo,
  String? token,
}) async {
  final uri = Uri.parse('$_base/repos/$owner/$repo');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200)
    throw Exception('Failed to get repo: ${response.statusCode}');
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  return data;
}

/// Get default branch (e.g. main) and latest commit sha for it.
Future<Map<String, String>> getDefaultBranchAndSha({
  required String owner,
  required String repo,
  String? token,
}) async {
  final data = await getRepo(owner: owner, repo: repo, token: token);
  final defaultBranch = data['default_branch'] as String? ?? 'main';
  final branchesUri = Uri.parse(
    '$_base/repos/$owner/$repo/branches/$defaultBranch',
  );
  final branchRes = await http.get(
    branchesUri,
    headers: _headers(token),
  );
  if (branchRes.statusCode != 200)
    throw Exception('Failed to get branch: ${branchRes.statusCode}');
  final branchData = jsonDecode(branchRes.body) as Map<String, dynamic>;
  final commit = branchData['commit'] as Map<String, dynamic>?;
  final sha = commit?['sha'] as String? ?? '';
  return {'branch': defaultBranch, 'sha': sha};
}

/// Delete a branch (refs/heads/branchName).
Future<void> deleteBranch({
  required String owner,
  required String repo,
  required String branchName,
  String? token,
}) async {
  if (token == null || token.isEmpty)
    throw Exception('Token required to delete branch');
  final ref = 'heads/$branchName';
  final uri = Uri.parse('$_base/repos/$owner/$repo/git/refs/$ref');
  final response = await http.delete(uri, headers: _headers(token));
  if (response.statusCode != 204)
    throw Exception(
      'Failed to delete branch: ${response.statusCode} ${response.body}',
    );
}

/// Merge a branch into another (base = target, head = source).
Future<Map<String, dynamic>> mergeBranch({
  required String owner,
  required String repo,
  required String base,
  required String head,
  String? commitMessage,
  String? token,
}) async {
  if (token == null || token.isEmpty)
    throw Exception('Token required to merge');
  final uri = Uri.parse('$_base/repos/$owner/$repo/merges');
  final body = <String, dynamic>{
    'base': base,
    'head': head,
  };
  if (commitMessage != null && commitMessage.isNotEmpty) {
    body['commit_message'] = commitMessage;
  }
  final response = await http.post(
    uri,
    headers: _headersJson(token),
    body: jsonEncode(body),
  );
  if (response.statusCode != 201)
    throw Exception(
      'Failed to merge: ${response.statusCode} ${response.body}',
    );
  return jsonDecode(response.body) as Map<String, dynamic>;
}

/// List commits (optionally for a branch via sha).
Future<List<Map<String, dynamic>>> listCommits({
  required String owner,
  required String repo,
  String? sha,
  int perPage = 25,
  String? token,
}) async {
  final query =
      sha != null ? '?sha=$sha&per_page=$perPage' : '?per_page=$perPage';
  final uri = Uri.parse('$_base/repos/$owner/$repo/commits$query');
  final response = await http.get(uri, headers: _headers(token));
  if (response.statusCode != 200)
    throw Exception('Failed to list commits: ${response.statusCode}');
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

/// PATCH /repos/:owner/:repo - update repo settings.
Future<Map<String, dynamic>> updateRepo({
  required String owner,
  required String repo,
  String? name,
  String? description,
  bool? private,
  String? homepage,
  String? defaultBranch,
  String? token,
}) async {
  if (token == null || token.isEmpty) {
    throw Exception('Token required to update repo');
  }
  final uri = Uri.parse('$_base/repos/$owner/$repo');
  final body = <String, dynamic>{};
  if (name != null) body['name'] = name;
  if (description != null) body['description'] = description;
  if (private != null) body['private'] = private;
  if (homepage != null) body['homepage'] = homepage;
  if (defaultBranch != null) body['default_branch'] = defaultBranch;
  final response = await http.patch(
    uri,
    headers: _headersJson(token),
    body: jsonEncode(body),
  );
  if (response.statusCode != 200) {
    throw Exception(
      'Failed to update repo: ${response.statusCode} ${response.body}',
    );
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
