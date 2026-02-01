import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:autogit/core/providers/github_templates_api.dart';
import 'package:autogit/core/utils/string_utils.dart';
import 'package:autogit/features/repos/data/github_contents_api.dart';

const _base = 'https://api.github.com';
const _envRepoOwner = 'autogit-app';
const _envRepo = 'environments';

Map<String, String> _headers(String? token) {
  final h = <String, String>{
    'Accept': 'application/vnd.github.v3+json',
    'User-Agent': 'AutoGit',
  };
  if (token != null && token.isNotEmpty) h['Authorization'] = 'Bearer $token';
  return h;
}

/// A code / environment template from autogit-app/environments.
/// If [folderPath] is set, the template is a folder inside the repo.
class EnvironmentTemplate {
  EnvironmentTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.templateOwner,
    required this.templateRepo,
    this.folderPath,
  });
  final String id;
  final String name;
  final String? description;
  final String templateOwner;
  final String templateRepo;
  final String? folderPath;
}

/// Fetch environment templates from autogit-app/environments.
/// Lists root directories as folder-based templates; optionally reads environments.json.
Future<List<EnvironmentTemplate>> fetchEnvironments({String? token}) async {
  final results = <EnvironmentTemplate>[];

  try {
    final items = await GitHubContentsApi.instance.listDir(
      owner: _envRepoOwner,
      repo: _envRepo,
      path: '',
      token: token,
    );
    for (final item in items) {
      if (item.type == 'dir') {
        results.add(
          EnvironmentTemplate(
            id: item.name,
            name: humanize(item.name),
            description: 'Folder: ${item.name}',
            templateOwner: _envRepoOwner,
            templateRepo: _envRepo,
            folderPath: item.name,
          ),
        );
      }
    }
  } catch (_) {}

  try {
    final uri = Uri.parse(
      '$_base/repos/$_envRepoOwner/$_envRepo/contents/environments.json',
    );
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as String?;
      if (content != null) {
        final decoded = utf8.decode(
          base64.decode(content.replaceAll('\n', '')),
        );
        final list = jsonDecode(decoded);
        if (list is List) {
          for (final e in list) {
            final m = e as Map<String, dynamic>;
            final repo = m['repo'] as String? ?? '';
            final parts = repo.split('/');
            final owner = parts.isNotEmpty ? parts[0] : _envRepoOwner;
            final repoName = parts.length > 1 ? parts[1] : _envRepo;
            results.add(
              EnvironmentTemplate(
                id: m['id'] as String? ?? repoName,
                name: m['name'] as String? ?? repoName,
                description: m['description'] as String?,
                templateOwner: owner,
                templateRepo: repoName,
                folderPath: null,
              ),
            );
          }
        }
      }
    }
  } catch (_) {}

  if (results.isEmpty) {
    results.add(
      EnvironmentTemplate(
        id: 'default',
        name: 'Default (environments)',
        description: 'Create from autogit-app/environments',
        templateOwner: _envRepoOwner,
        templateRepo: _envRepo,
        folderPath: null,
      ),
    );
  }
  return results;
}

/// Create a new code repo from an environment template (folder or full template repo).
Future<Map<String, dynamic>> createCodeRepoFromTemplate({
  required String templateOwner,
  required String templateRepo,
  required String newRepoName,
  required String owner,
  String? description,
  bool private = false,
  String? folderPath,
  String? token,
}) async {
  return createRepoFromTemplate(
    templateOwner: templateOwner,
    templateRepo: templateRepo,
    newRepoName: newRepoName,
    owner: owner,
    description: description,
    private: private,
    folderPath: folderPath,
    token: token,
  );
}
