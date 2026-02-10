import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/repos/data/local_repo_providers.dart';
import 'package:autogit/features/repos/data/local_repo_service.dart';

final _localReposProvider = FutureProvider<List<LocalRepoInfo>>((ref) async {
  final serviceAsync = ref.watch(localRepoServiceProvider);
  final service = serviceAsync.value;
  if (service == null) return [];
  if (!await service.isAvailable) return [];
  await service.ensureRepositoriesDirectory();
  return service.listRepositories();
});

class LocalReposScreen extends ConsumerStatefulWidget {
  const LocalReposScreen({super.key});

  /// Call from FAB or elsewhere to open the "Create repository" dialog.
  static void showCreateRepoDialog(BuildContext context, WidgetRef ref) {
    _showNewRepoDialogStatic(context, ref);
  }

  static void _showNewRepoDialogStatic(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New repository'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Repository name',
            hintText: 'my-project',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          onSubmitted: (_) =>
              _submitNewRepoStatic(context, ctx, ref, nameController.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                _submitNewRepoStatic(context, ctx, ref, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  static Future<void> _submitNewRepoStatic(
    BuildContext screenContext,
    BuildContext dialogContext,
    WidgetRef ref,
    String name,
  ) async {
    final n = name.trim();
    if (n.isEmpty) return;
    Navigator.of(dialogContext).pop();
    final theme = Theme.of(dialogContext);
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) {
      if (screenContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          const SnackBar(content: Text('Local git service not ready')),
        );
      }
      return;
    }
    try {
      final info = await service.initRepository(n);
      if (!screenContext.mounted) return;
      final nameToNavigate = info.name.isNotEmpty ? info.name : n;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(_localReposProvider);
        if (!screenContext.mounted) return;
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(content: Text('Created repository "${info.name}"')),
        );
        screenContext
            .push('/home/local/${Uri.encodeComponent(nameToNavigate)}');
      });
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: theme.colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  @override
  ConsumerState<LocalReposScreen> createState() => _LocalReposScreenState();
}

class _LocalReposScreenState extends ConsumerState<LocalReposScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(_localReposProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAndroid = Platform.isAndroid;
    final serviceAsync = ref.watch(localRepoServiceProvider);
    final reposAsync = ref.watch(_localReposProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(
            title: 'Local Repositories',
            onBack: () => context.go('/home'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh list',
                onPressed: () => ref.invalidate(_localReposProvider),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New repository',
                onPressed: () =>
                    LocalReposScreen._showNewRepoDialogStatic(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Clone repository',
                onPressed: () => _showCloneDialog(context, ref),
              ),
            ],
          ),
          if (isAndroid) _TermuxBanner(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Repositories are stored in a "Repositories" folder in your home directory.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          serviceAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Could not load local git service',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            data: (_) => reposAsync.when(
              data: (repos) {
                if (repos.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.folderOpen,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No local repositories yet',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                LocalReposScreen._showNewRepoDialogStatic(
                                    context, ref),
                            icon: const Icon(Icons.add),
                            label: const Text('Create repository'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showCloneDialog(context, ref),
                            icon: const Icon(Icons.download),
                            label: const Text('Clone from URL'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final repo = repos[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            PhosphorIconsFill.gitBranch,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(repo.name),
                        subtitle: repo.currentBranch != null
                            ? Text(
                                repo.currentBranch! +
                                    (repo.isClean == true ? ' • clean' : ''),
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                            '/home/local/${Uri.encodeComponent(repo.name)}'),
                      );
                    },
                    childCount: repos.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: theme.colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (isAndroid) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Make sure the Termux Git Server is running (see banner above).',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _showCloneDialog(BuildContext context, WidgetRef ref) {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clone repository'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Repository URL',
                hintText: 'https://github.com/user/repo.git',
              ),
              autofocus: true,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Folder name (optional)',
                hintText: 'Leave blank to use repo name',
              ),
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _submitClone(
              context,
              ctx,
              ref,
              urlController.text.trim(),
              nameController.text.trim().isEmpty
                  ? null
                  : nameController.text.trim(),
            ),
            child: const Text('Clone'),
          ),
        ],
      ),
    ).then((_) {
      urlController.dispose();
      nameController.dispose();
    });
  }

  static Future<void> _submitClone(
    BuildContext screenContext,
    BuildContext dialogContext,
    WidgetRef ref,
    String url,
    String? name,
  ) async {
    if (url.isEmpty) return;
    Navigator.of(dialogContext).pop();
    final theme = Theme.of(dialogContext);
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) {
      if (screenContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          const SnackBar(content: Text('Local git service not ready')),
        );
      }
      return;
    }
    try {
      final info = await service.cloneRepository(url, name: name);
      if (!screenContext.mounted) return;
      final displayName = info.name.isNotEmpty
          ? info.name
          : (name ?? url.split('/').last.replaceFirst(RegExp(r'\.git$'), ''));
      final nameToNavigate = info.name.isNotEmpty ? info.name : displayName;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(_localReposProvider);
        if (!screenContext.mounted) return;
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(content: Text('Cloned "$displayName"')),
        );
        screenContext
            .push('/home/local/${Uri.encodeComponent(nameToNavigate)}');
      });
    } catch (e) {
      if (screenContext.mounted) {
        ScaffoldMessenger.of(screenContext).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: theme.colorScheme.errorContainer,
          ),
        );
      }
    }
  }
}

class _TermuxBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Material(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    PhosphorIconsFill.info,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Android: Termux required',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Termux: run the one-command setup from the README (curl the setup script | bash). It installs deps, downloads the server, and runs it from bashrc. URL: Settings → Local Git Server.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
