import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/core/providers/github.dart';
import 'package:autogit/core/providers/github_pages_api.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/repos/data/github_contents_api.dart';

/// Template for GitHub Pages sites.
class PagesTemplate {
  const PagesTemplate(this.label, this.html);
  final String label;
  final String html;

  static const List<PagesTemplate> all = [
    PagesTemplate('Minimal HTML', '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Site</title>
</head>
<body>
  <h1>Hello, World!</h1>
  <p>Welcome to my GitHub Pages site.</p>
</body>
</html>
'''),
    PagesTemplate('Readme style', '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Project</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 720px; margin: 2em auto; padding: 0 1em; line-height: 1.5; }
    h1 { border-bottom: 1px solid #eee; }
    code { background: #f4f4f4; padding: 0.2em 0.4em; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>My Project</h1>
  <p>This is a simple project page hosted on GitHub Pages.</p>
  <h2>Getting started</h2>
  <p>Clone the repo and run <code>npm install</code>.</p>
</body>
</html>
'''),
    PagesTemplate('Simple blog', '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My Blog</title>
  <style>
    body { font-family: Georgia, serif; max-width: 680px; margin: 2em auto; padding: 0 1em; }
    article { margin-bottom: 2em; padding-bottom: 2em; border-bottom: 1px solid #eee; }
    .meta { color: #666; font-size: 0.9em; }
  </style>
</head>
<body>
  <h1>My Blog</h1>
  <article>
    <h2>First post</h2>
    <p class="meta">Posted on 2024-01-01</p>
    <p>Welcome to my blog. More posts coming soon.</p>
  </article>
</body>
</html>
'''),
  ];
}

class SitesScreen extends ConsumerStatefulWidget {
  const SitesScreen({super.key});

  @override
  ConsumerState<SitesScreen> createState() => _SitesScreenState();
}

class _SitesScreenState extends ConsumerState<SitesScreen> {
  List<({String owner, String repo, String url})> _sites = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(githubTokenProvider);
    final username = ref.read(githubUsernameProvider);
    if (username == null || username.isEmpty) {
      setState(() {
        _loading = false;
        _sites = [];
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final repos = await getUserRepos(token, username);
      final sites = <({String owner, String repo, String url})>[];
      for (final r in repos) {
        final url = await getPagesUrl(
          owner: username,
          repo: r.name,
          token: token,
        );
        if (url != null && url.isNotEmpty) {
          sites.add((owner: username, repo: r.name, url: url));
        }
      }
      if (mounted) {
        setState(() {
          _sites = sites;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final username = ref.watch(githubUsernameProvider);

    if (!hasToken || username == null || username.isEmpty) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Sites (GitHub Pages)'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.public_off,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in with GitHub to see your sites',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => context.go('/auth'),
                        icon: const Icon(Icons.login),
                        label: const Text('Sign in'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'Sites (GitHub Pages)'),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $_error')),
            )
          else if (_sites.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.public,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No GitHub Pages sites yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + to create a site from a template',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final s = _sites[index];
                return ListTile(
                  leading: const Icon(Icons.public),
                  title: Text('${s.owner}/${s.repo}'),
                  subtitle: Text(
                    s.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    launchUrlString(s.url);
                  },
                  onLongPress: () => context.push(
                    '/home/github/${Uri.encodeComponent(s.owner)}/${Uri.encodeComponent(s.repo)}',
                  ),
                );
              }, childCount: _sites.length),
            ),
        ],
      ),
      floatingActionButton: hasToken
          ? FloatingActionButton(
              onPressed: () => _showAddSiteDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showAddSiteDialog(BuildContext context) async {
    final username = ref.read(githubUsernameProvider);
    final token = ref.read(githubTokenProvider);
    if (username == null || token == null || token.isEmpty) return;
    final reposAsync = ref.read(userReposProvider);
    final repos = reposAsync.value ?? [];
    if (repos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a repository first')),
      );
      return;
    }
    String? selectedRepo = repos.first.name;
    PagesTemplate selectedTemplate = PagesTemplate.all.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Add GitHub Pages site'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Select repository'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedRepo,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: repos
                        .map(
                          (r) => DropdownMenuItem(
                            value: r.name,
                            child: Text(r.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => selectedRepo = v),
                  ),
                  const SizedBox(height: 16),
                  const Text('Template'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<PagesTemplate>(
                    value: selectedTemplate,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: PagesTemplate.all
                        .map(
                          (t) =>
                              DropdownMenuItem(value: t, child: Text(t.label)),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedTemplate = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true || !context.mounted || selectedRepo == null) return;
    try {
      await createOrUpdatePages(
        owner: username,
        repo: selectedRepo!,
        branch: 'main',
        path: '/',
        token: token,
      );
      await GitHubContentsApi.instance.createFile(
        owner: username,
        repo: selectedRepo!,
        path: 'index.html',
        content: selectedTemplate.html,
        message: 'Add index.html from template',
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site created. It may take a minute to build.'),
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
