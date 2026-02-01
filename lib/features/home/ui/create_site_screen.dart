import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/auth.dart';
import 'package:autogit/features/github/github.dart';

class CreateSiteScreen extends ConsumerStatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  ConsumerState<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends ConsumerState<CreateSiteScreen> {
  List<SiteTemplate>? _templates;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(githubTokenProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await fetchTemplates(token: token);
      if (mounted) {
        setState(() {
          _templates = list;
          _loading = false;
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

  Future<void> _createFromTemplate(SiteTemplate template) async {
    final username = ref.read(githubUsernameProvider);
    final token = ref.read(githubTokenProvider);
    if (username == null || token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in with GitHub first')),
        );
      }
      return;
    }
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create site: ${template.name}'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Repository name',
            hintText: 'my-site',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
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
      ),
    );
    if (ok != true || !mounted) return;
    final repoName = nameController.text.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9\-_]'),
      '-',
    );
    if (repoName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a repository name')));
      return;
    }
    try {
      await createRepoFromTemplate(
        templateOwner: template.templateOwner,
        templateRepo: template.templateRepo,
        newRepoName: repoName,
        owner: username,
        folderPath: template.folderPath,
        token: token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Site created: $username/$repoName. GitHub Actions will deploy to Pages.',
          ),
        ),
      );
      context.push(
        '/home/github/${Uri.encodeComponent(username)}/${Uri.encodeComponent(repoName)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);

    if (!hasToken) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Create site'),
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
                        'Sign in with GitHub to create sites from templates',
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

    if (_loading) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Create site'),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Create site'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
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

    final templates = _templates ?? [];
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'Create site'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Choose a template. Your new repo will be created from it and deployed to GitHub Pages via Actions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (templates.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No templates found')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final t = templates[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.public),
                    title: Text(t.name),
                    subtitle: t.description != null && t.description!.isNotEmpty
                        ? Text(t.description!)
                        : Text('${t.templateOwner}/${t.templateRepo}'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () => _createFromTemplate(t),
                  ),
                );
              }, childCount: templates.length),
            ),
        ],
      ),
    );
  }
}
