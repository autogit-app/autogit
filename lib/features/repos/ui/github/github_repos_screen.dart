import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:github/github.dart';

import 'package:autogit/core/providers/github.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class GithubReposScreen extends ConsumerWidget {
  const GithubReposScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final username = ref.watch(githubUsernameProvider);
    final reposAsync = ref.watch(userReposProvider);

    if (!hasToken || username == null || username.isEmpty) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Remote Repositories'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.folder_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in with GitHub to see your remote repositories',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
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
          ],
        ),
      );
    }

    return reposAsync.when(
      data: (repositories) => Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Remote Repositories'),
            SliverToBoxAdapter(
              child: _ReposList(
                ref: ref,
                repositories: repositories,
                username: username,
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateRepoDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      loading: () => Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Remote Repositories'),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (error, stack) => Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Remote Repositories'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load repositories',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCreateRepoDialog(BuildContext context, WidgetRef ref) async {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  var isPrivate = false;
  final created = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('Create repository'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Repository name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Private'),
                  value: isPrivate,
                  onChanged: (v) => setDialogState(() => isPrivate = v),
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
  if (created != true || !context.mounted) return;
  final name = nameController.text.trim();
  if (name.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Enter a repository name')));
    return;
  }
  final token = ref.read(githubTokenProvider);
  try {
    final github = GitHub(auth: Authentication.withToken(token));
    await github.repositories.createRepository(
      CreateRepository(
        name,
        description: descController.text.trim().isEmpty
            ? null
            : descController.text.trim(),
        private: isPrivate,
      ),
    );
    ref.invalidate(userReposProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Repository created')));
      context.push(
        '/home/github/${Uri.encodeComponent(ref.read(githubUsernameProvider)!)}/${Uri.encodeComponent(name)}',
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _ReposList extends StatelessWidget {
  const _ReposList({
    required this.ref,
    required this.repositories,
    required this.username,
  });

  final WidgetRef ref;
  final List<Repository> repositories;
  final String username;

  @override
  Widget build(BuildContext context) {
    if (repositories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_open, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No repositories found'),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final repo = repositories[index];
        final repoName = repo.name;
        final isOwner = repo.owner?.login == username;
        return ListTile(
          leading: const Icon(OctIcons.repo_16),
          title: Text(repoName),
          dense: true,
          onTap: () => context.push(
            '/home/github/${Uri.encodeComponent(username)}/${Uri.encodeComponent(repoName)}',
          ),
          trailing: isOwner
              ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'settings') {
                      context.push(
                        '/home/github/${Uri.encodeComponent(username)}/${Uri.encodeComponent(repoName)}/settings',
                      );
                    } else if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete repository?'),
                          content: Text(
                            'This will permanently delete $username/$repoName. This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true || !context.mounted) return;
                      final token = ref.read(githubTokenProvider);
                      try {
                        await deleteRepo(
                          token,
                          RepositorySlug(username, repoName),
                        );
                        ref.invalidate(userReposProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Repository deleted')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'settings',
                      child: ListTile(
                        leading: Icon(Icons.settings),
                        title: Text('Settings'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
