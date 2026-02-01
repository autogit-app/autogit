import 'dart:convert';

import 'package:http/http.dart' as http;

/// GitHub Contents API: get file, update file (creates a commit).
class GitHubContentsApi {
  GitHubContentsApi._();
  static final GitHubContentsApi instance = GitHubContentsApi._();

  static const _base = 'https://api.github.com';

  /// GET /repos/:owner/:repo/contents/:path - list directory (path empty or ends with /).
  /// Returns list of {name, path, type} where type is 'file' or 'dir'.
  Future<List<GitHubContentItem>> listDir({
    required String owner,
    required String repo,
    required String path,
    String? token,
  }) async {
    final uri = Uri.parse(
      '$_base/repos/$owner/$repo/contents/${path.replaceAll(' ', '%20')}',
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'AutoGit',
    };
    if (token != null && token.isNotEmpty)
      headers['Authorization'] = 'Bearer $token';
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to list directory: ${response.statusCode} ${response.body}',
      );
    }
    final list = jsonDecode(response.body);
    if (list is! List) return [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return GitHubContentItem(
        name: m['name'] as String? ?? '',
        path: m['path'] as String? ?? '',
        type: m['type'] as String? ?? 'file',
      );
    }).toList();
  }

  /// GET /repos/:owner/:repo/contents/:path - returns file metadata and base64 content.
  Future<GitHubFileContent> getFile({
    required String owner,
    required String repo,
    required String path,
    String? token,
  }) async {
    final uri = Uri.parse(
      '$_base/repos/$owner/$repo/contents/${path.replaceAll(' ', '%20')}',
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'AutoGit',
    };
    if (token != null && token.isNotEmpty)
      headers['Authorization'] = 'Bearer $token';
    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to get file: ${response.statusCode} ${response.body}',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['content'] as String?;
    if (content == null) throw Exception('No content in response');
    final decoded = utf8.decode(base64.decode(content.replaceAll('\n', '')));
    return GitHubFileContent(
      sha: json['sha'] as String? ?? '',
      content: decoded,
      path: path,
    );
  }

  /// PUT /repos/:owner/:repo/contents/:path - create new file (no sha).
  Future<void> createFile({
    required String owner,
    required String repo,
    required String path,
    required String content,
    required String message,
    String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('GitHub token required to create files.');
    }
    final uri = Uri.parse(
      '$_base/repos/$owner/$repo/contents/${path.replaceAll(' ', '%20')}',
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
      'User-Agent': 'AutoGit',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'message': message,
      'content': base64Encode(utf8.encode(content)),
    });
    final response = await http.put(uri, headers: headers, body: body);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to create file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// PUT /repos/:owner/:repo/contents/:path - update file (creates a commit).
  Future<void> updateFile({
    required String owner,
    required String repo,
    required String path,
    required String content,
    required String message,
    required String sha,
    String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('GitHub token required to update files.');
    }
    final uri = Uri.parse(
      '$_base/repos/$owner/$repo/contents/${path.replaceAll(' ', '%20')}',
    );
    final headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
      'User-Agent': 'AutoGit',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'message': message,
      'content': base64Encode(utf8.encode(content)),
      'sha': sha,
    });
    final response = await http.put(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update file: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Recursively copy a folder from source repo to target repo (creates files).
  /// [folderPath] is the path to the folder in the source repo (e.g. "starter-astro-blog").
  /// Files are created in the target repo with paths relative to repo root (e.g. "index.html").
  Future<void> copyFolderToRepo({
    required String sourceOwner,
    required String sourceRepo,
    required String folderPath,
    required String targetOwner,
    required String targetRepo,
    required String message,
    String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Token required to copy folder');
    }
    await _copyFolderRecursive(
      sourceOwner: sourceOwner,
      sourceRepo: sourceRepo,
      sourcePath: folderPath.isEmpty ? '' : folderPath,
      targetOwner: targetOwner,
      targetRepo: targetRepo,
      targetPrefix: '',
      message: message,
      token: token,
    );
  }

  Future<void> _copyFolderRecursive({
    required String sourceOwner,
    required String sourceRepo,
    required String sourcePath,
    required String targetOwner,
    required String targetRepo,
    required String targetPrefix,
    required String message,
    required String token,
  }) async {
    final items = await listDir(
      owner: sourceOwner,
      repo: sourceRepo,
      path: sourcePath.isEmpty ? '' : sourcePath,
      token: token,
    );
    for (final item in items) {
      if (item.type == 'file') {
        final file = await getFile(
          owner: sourceOwner,
          repo: sourceRepo,
          path: item.path,
          token: token,
        );
        await createFile(
          owner: targetOwner,
          repo: targetRepo,
          path: targetPrefix.isEmpty ? item.name : '$targetPrefix${item.name}',
          content: file.content,
          message: message,
          token: token,
        );
      } else if (item.type == 'dir') {
        await _copyFolderRecursive(
          sourceOwner: sourceOwner,
          sourceRepo: sourceRepo,
          sourcePath: item.path,
          targetOwner: targetOwner,
          targetRepo: targetRepo,
          targetPrefix: '$targetPrefix${item.name}/',
          message: message,
          token: token,
        );
      }
    }
  }
}

class GitHubFileContent {
  GitHubFileContent({
    required this.sha,
    required this.content,
    required this.path,
  });
  final String sha;
  final String content;
  final String path;
}

class GitHubContentItem {
  GitHubContentItem({
    required this.name,
    required this.path,
    required this.type,
  });
  final String name;
  final String path;
  final String type;
}
