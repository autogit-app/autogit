import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:autogit/core/providers/github.dart';
import 'package:autogit/core/utils/string_utils.dart';
import 'package:autogit/features/repos/data/github_contents_api.dart';

const _base = 'https://api.github.com';
const _templatesRepoOwner = 'autogit-app';
const _templatesRepo = 'templates';

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

/// A template from the autogit-app/templates repo.
/// If [folderPath] is set, the template is a folder inside the repo; otherwise
/// [templateOwner]/[templateRepo] is a full GitHub template repository.
class SiteTemplate {
  SiteTemplate({
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

  /// If non-null, template is a folder inside templateRepo; we copy this folder to the new repo.
  final String? folderPath;
}

/// Fetch templates from autogit-app/templates repo.
/// Lists root directories as folder-based templates; optionally reads templates.json for extra entries.
Future<List<SiteTemplate>> fetchTemplates({String? token}) async {
  final results = <SiteTemplate>[];

  // Folder-based: list root of templates repo; each directory is a template.
  try {
    final items = await GitHubContentsApi.instance.listDir(
      owner: _templatesRepoOwner,
      repo: _templatesRepo,
      path: '',
      token: token,
    );
    for (final item in items) {
      if (item.type == 'dir') {
        results.add(
          SiteTemplate(
            id: item.name,
            name: humanize(item.name),
            description: 'Folder: ${item.name}',
            templateOwner: _templatesRepoOwner,
            templateRepo: _templatesRepo,
            folderPath: item.name,
          ),
        );
      }
    }
  } catch (_) {}

  // Optional: templates.json for full template repos or overrides.
  try {
    final uri = Uri.parse(
      '$_base/repos/$_templatesRepoOwner/$_templatesRepo/contents/templates.json',
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
            final owner = parts.isNotEmpty ? parts[0] : _templatesRepoOwner;
            final repoName = parts.length > 1 ? parts[1] : _templatesRepo;
            results.add(
              SiteTemplate(
                id: m['id'] as String? ?? repoName,
                name: m['name'] as String? ?? repoName,
                description: m['description'] as String?,
                templateOwner: owner,
                templateRepo: repoName,
                folderPath: null, // full template repo
              ),
            );
          }
        }
      }
    }
  } catch (_) {}

  if (results.isEmpty) {
    results.add(
      SiteTemplate(
        id: 'default',
        name: 'Default (GitHub Pages)',
        description: 'Create from autogit-app/templates',
        templateOwner: _templatesRepoOwner,
        templateRepo: _templatesRepo,
        folderPath: null,
      ),
    );
  }
  return results;
}

/// Create a new repository from a template (or from a folder in the templates repo).
/// If [folderPath] is non-null, creates an empty repo and copies that folder's contents.
/// Otherwise uses GitHub's POST /repos/{owner}/{repo}/generate.
Future<Map<String, dynamic>> createRepoFromTemplate({
  required String templateOwner,
  required String templateRepo,
  required String newRepoName,
  required String owner,
  String? description,
  bool private = false,
  String? folderPath,
  String? token,
}) async {
  if (token == null || token.isEmpty) {
    throw Exception('Token required to create from template');
  }

  if (folderPath != null && folderPath.isNotEmpty) {
    // Create empty repo and copy folder contents.
    final repo = await createRepo(token, newRepoName);
    await GitHubContentsApi.instance.copyFolderToRepo(
      sourceOwner: templateOwner,
      sourceRepo: templateRepo,
      folderPath: folderPath,
      targetOwner: owner,
      targetRepo: newRepoName,
      message: 'Initial commit from template: $folderPath',
      token: token,
    );
    return {
      'name': repo.name,
      'full_name': '${repo.owner!.login}/${repo.name}',
      'clone_url': repo.htmlUrl,
      'private': repo.isPrivate,
    };
  }

  final uri = Uri.parse('$_base/repos/$templateOwner/$templateRepo/generate');
  final body = jsonEncode({
    'owner': owner,
    'name': newRepoName,
    'description': description ?? '',
    'private': private,
  });
  final response = await http.post(
    uri,
    headers: _headersJson(token),
    body: body,
  );
  if (response.statusCode != 201) {
    throw Exception(
      'Failed to create from template: ${response.statusCode} ${response.body}',
    );
  }
  return jsonDecode(response.body) as Map<String, dynamic>;
}
