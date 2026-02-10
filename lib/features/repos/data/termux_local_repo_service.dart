import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:autogit/features/repos/data/local_repo_service.dart';

/// Default URL for the Termux Git Server (scripts/termux_git_server.py).
/// Can be overridden in settings to use a remote server (e.g. http://192.168.1.5:8765).
const String kDefaultTermuxGitServerUrl = 'http://127.0.0.1:8765';

/// Local repo service for Android: talks to the Termux Git Server over HTTP.
/// [baseUrl] is the full base URL (e.g. http://127.0.0.1:8765 or http://remote:8765).
class TermuxLocalRepoService implements LocalRepoService {
  TermuxLocalRepoService({String? baseUrl})
      : _baseUrl = baseUrl ?? kDefaultTermuxGitServerUrl;

  final String _baseUrl;

  @override
  Future<bool> get isAvailable async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/health')).timeout(
            const Duration(seconds: 2),
          );
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body) as Map<String, dynamic>?;
        return body?['ok'] == true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<String?> get repositoriesPath async => null;

  @override
  Future<void> ensureRepositoriesDirectory() async {
    // Server creates ~/Repositories on first request
    await listRepositories();
  }

  @override
  Future<List<LocalRepoInfo>> listRepositories() async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/repos')).timeout(
            const Duration(seconds: 10),
          );
      if (r.statusCode != 200) {
        throw Exception(_errorFromBody(r.body) ?? 'Failed to list repos');
      }
      final decoded = jsonDecode(r.body);
      if (decoded is! List<dynamic>) return [];
      final list = <LocalRepoInfo>[];
      for (final e in decoded) {
        if (e is! Map<String, dynamic>) continue;
        final name = e['name'];
        if (name is! String || name.isEmpty) continue;
        list.add(_repoInfoFromJson(e));
      }
      return list;
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<LocalRepoInfo> initRepository(String name) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/init'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (r.statusCode != 201) {
      throw Exception(_errorFromBody(r.body) ?? 'Failed to init repo');
    }
    final map = _parseJsonMap(r.body);
    final repoName = map['name'] is String ? map['name'] as String : name;
    final path = map['path'] is String ? map['path'] as String : '';
    return LocalRepoInfo(name: repoName, path: path);
  }

  @override
  Future<LocalRepoInfo> cloneRepository(String cloneUrl, {String? name}) async {
    final body = <String, dynamic>{'url': cloneUrl};
    if (name != null) body['name'] = name;
    final r = await http.post(
      Uri.parse('$_baseUrl/clone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode != 201) {
      throw Exception(_errorFromBody(r.body) ?? 'Failed to clone');
    }
    final map = _parseJsonMap(r.body);
    final repoName = map['name'] is String
        ? map['name'] as String
        : (name ?? _nameFromUrl(cloneUrl));
    final path = map['path'] is String ? map['path'] as String : '';
    return LocalRepoInfo(name: repoName, path: path);
  }

  @override
  Future<String> runCommand(String repoName, List<String> args) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/run'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'repo': repoName, 'args': args}),
    );
    if (r.statusCode != 200) {
      throw Exception(_errorFromBody(r.body) ?? 'Git command failed');
    }
    final map = _parseJsonMap(r.body);
    return map['output'] is String ? map['output'] as String : '';
  }

  @override
  Future<List<LocalRepoEntry>> listDir(String repoName, String path) async {
    final encoded = Uri.encodeComponent(repoName);
    final uri = path.isEmpty
        ? Uri.parse('$_baseUrl/repos/$encoded/list')
        : Uri.parse('$_baseUrl/repos/$encoded/list').replace(
            queryParameters: {'path': path},
          );
    final r = await http.get(uri);
    if (r.statusCode != 200) {
      throw Exception(_errorFromBody(r.body) ?? 'Failed to list directory');
    }
    final decoded = jsonDecode(r.body);
    if (decoded is! List<dynamic>) return [];
    final list = <LocalRepoEntry>[];
    for (final e in decoded) {
      if (e is! Map<String, dynamic>) continue;
      final name = e['name'];
      final isDir = e['isDir'] == true;
      if (name is! String || name.isEmpty) continue;
      list.add(LocalRepoEntry(name: name, isDir: isDir));
    }
    return list;
  }

  @override
  Future<String> readFile(String repoName, String path) async {
    final encoded = Uri.encodeComponent(repoName);
    final uri = Uri.parse('$_baseUrl/repos/$encoded/read')
        .replace(queryParameters: {'path': path});
    final r = await http.get(uri);
    if (r.statusCode != 200) {
      throw Exception(_errorFromBody(r.body) ?? 'Failed to read file');
    }
    final map = _parseJsonMap(r.body);
    return map['content'] is String ? map['content'] as String : '';
  }

  @override
  Future<void> writeFile(String repoName, String path, String content) async {
    final encoded = Uri.encodeComponent(repoName);
    final r = await http.post(
      Uri.parse('$_baseUrl/repos/$encoded/write'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'path': path, 'content': content}),
    );
    if (r.statusCode != 201 && r.statusCode != 200) {
      throw Exception(_errorFromBody(r.body) ?? 'Failed to write file');
    }
  }

  static Map<String, dynamic> _parseJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }

  static String _nameFromUrl(String url) {
    final s = url.trim();
    if (s.endsWith('.git')) return s.substring(0, s.length - 4).split('/').last;
    return s.split('/').last.isNotEmpty ? s.split('/').last : 'repo';
  }

  static String? _errorFromBody(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>?;
      return map?['error'] as String?;
    } catch (_) {
      return null;
    }
  }

  static LocalRepoInfo _repoInfoFromJson(Map<String, dynamic> map) {
    return LocalRepoInfo(
      name: map['name'] is String ? map['name'] as String : '',
      path: map['path'] is String ? map['path'] as String : '',
      currentBranch: map['currentBranch'] is String
          ? map['currentBranch'] as String
          : null,
      isClean: map['isClean'] is bool ? map['isClean'] as bool : null,
    );
  }
}
