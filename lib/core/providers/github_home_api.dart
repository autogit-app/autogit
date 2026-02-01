import 'dart:convert';

import 'package:http/http.dart' as http;

const _base = 'https://api.github.com';

/// GitHub API for home screen: notifications, starred, watched, issues, PRs.
Future<List<Map<String, dynamic>>> getNotifications(String? token) async {
  final uri = Uri.parse('$_base/notifications');
  final headers = _headers(token);
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) return [];
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getStarredRepos(String? token) async {
  if (token == null || token.isEmpty) return [];
  final uri = Uri.parse('$_base/user/starred?per_page=30');
  final headers = _headers(token);
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) return [];
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getWatchedRepos(String? token) async {
  if (token == null || token.isEmpty) return [];
  final uri = Uri.parse('$_base/user/subscriptions?per_page=30');
  final headers = _headers(token);
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) return [];
  final list = jsonDecode(response.body);
  if (list is! List) return [];
  return list.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getIssues(
  String? token,
  String? username,
) async {
  if (username == null || username.isEmpty) return [];
  final uri = Uri.parse(
    '$_base/search/issues?q=author:$username+is:open+type:issue&per_page=30',
  );
  final headers = _headers(token);
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) return [];
  final json = jsonDecode(response.body) as Map<String, dynamic>?;
  final items = json?['items'];
  if (items is! List) return [];
  return items.map((e) => e as Map<String, dynamic>).toList();
}

Future<List<Map<String, dynamic>>> getPullRequests(
  String? token,
  String? username,
) async {
  if (username == null || username.isEmpty) return [];
  final uri = Uri.parse(
    '$_base/search/issues?q=author:$username+is:open+type:pr&per_page=30',
  );
  final headers = _headers(token);
  final response = await http.get(uri, headers: headers);
  if (response.statusCode != 200) return [];
  final json = jsonDecode(response.body) as Map<String, dynamic>?;
  final items = json?['items'];
  if (items is! List) return [];
  return items.map((e) => e as Map<String, dynamic>).toList();
}

Map<String, String> _headers(String? token) {
  final h = <String, String>{
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'AutoGit',
  };
  if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
  return h;
}
