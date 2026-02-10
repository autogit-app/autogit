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

  // Built-in templates when repo is empty or unreachable (always appended so users always have options).
  final builtIn = [
    SiteTemplate(
      id: 'builtin_minimal',
      name: 'Minimal page',
      description: 'Single index.html with basic structure',
      templateOwner: _templatesRepoOwner,
      templateRepo: _templatesRepo,
      folderPath: 'builtin_minimal',
    ),
    SiteTemplate(
      id: 'builtin_blog',
      name: 'Simple blog',
      description: 'Blog-style page with CSS',
      templateOwner: _templatesRepoOwner,
      templateRepo: _templatesRepo,
      folderPath: 'builtin_blog',
    ),
    SiteTemplate(
      id: 'builtin_docs',
      name: 'Documentation',
      description: 'Docs-style page with sections',
      templateOwner: _templatesRepoOwner,
      templateRepo: _templatesRepo,
      folderPath: 'builtin_docs',
    ),
  ];
  for (final t in builtIn) {
    if (results.every((r) => r.id != t.id)) results.add(t);
  }
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

/// Content for built-in site templates (when folderPath is builtin_*).
Map<String, String> getBuiltInSiteTemplateContents(String folderPath) {
  switch (folderPath) {
    case 'builtin_minimal':
      return {
        'index.html': '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Site</title>
</head>
<body>
  <h1>Welcome</h1>
  <p>This is my GitHub Pages site.</p>
</body>
</html>''',
      };
    case 'builtin_blog':
      return {
        'index.html': '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Blog</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <header><h1>My Blog</h1></header>
  <main>
    <article>
      <h2>First post</h2>
      <p>Hello, world! This is my first post.</p>
    </article>
  </main>
</body>
</html>''',
        'style.css':
            '''body { font-family: system-ui; max-width: 720px; margin: 0 auto; padding: 1rem; }
header { border-bottom: 1px solid #eee; }
article { margin: 2rem 0; }''',
      };
    case 'builtin_docs':
      return {
        'index.html': '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Documentation</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <nav>
    <h2>Docs</h2>
    <ul>
      <li><a href="#intro">Introduction</a></li>
      <li><a href="#usage">Usage</a></li>
    </ul>
  </nav>
  <main>
    <section id="intro"><h1>Introduction</h1><p>Welcome to the documentation.</p></section>
    <section id="usage"><h2>Usage</h2><p>Get started by reading the sections above.</p></section>
  </main>
</body>
</html>''',
        'style.css':
            '''body { font-family: system-ui; display: flex; max-width: 960px; margin: 0 auto; }
nav { width: 200px; padding: 1rem; border-right: 1px solid #eee; }
main { padding: 1rem 2rem; }
section { margin: 2rem 0; }''',
      };
    default:
      return {};
  }
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
    final repo = await createRepo(token, newRepoName);
    final builtIn = getBuiltInSiteTemplateContents(folderPath);
    if (builtIn.isNotEmpty) {
      for (final entry in builtIn.entries) {
        await GitHubContentsApi.instance.createFile(
          owner: owner,
          repo: newRepoName,
          path: entry.key,
          content: entry.value,
          message: 'Add ${entry.key} from template',
          token: token,
        );
      }
      return {
        'name': repo.name,
        'full_name': '${repo.owner!.login}/${repo.name}',
        'clone_url': repo.htmlUrl,
        'private': repo.isPrivate,
      };
    }
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
