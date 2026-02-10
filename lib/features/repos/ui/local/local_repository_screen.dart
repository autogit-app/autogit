import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/repos/data/local_repo_providers.dart';
import 'package:autogit/features/repos/data/local_repo_service.dart';
import 'package:autogit/features/settings/data/git_identity_persistence.dart';
import 'package:autogit/features/settings/logic/git_identity_providers.dart';

class LocalRepositoryScreen extends ConsumerStatefulWidget {
  const LocalRepositoryScreen({super.key, required this.param});

  final String param;

  @override
  ConsumerState<LocalRepositoryScreen> createState() =>
      _LocalRepositoryScreenState();
}

class _LocalRepositoryScreenState extends ConsumerState<LocalRepositoryScreen> {
  final List<String> _pathSegments = [];
  List<LocalRepoEntry>? _entries;
  String? _statusOutput;
  String? _branchesOutput;
  String? _remoteOutput;
  String? _graphOutput;
  bool _loading = false;
  String? _error;
  bool _showGitInfo = false;
  String? _currentBranch;
  List<String> _localBranchNames = [];

  String get _repoName => Uri.decodeComponent(widget.param);
  String get _currentPath => _pathSegments.join('/');

  Future<void> _loadDir() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) {
      setState(() {
        _error = 'Local git service not ready';
        _entries = [];
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await service.listDir(_repoName, _currentPath);
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _entries = [];
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadGitInfo() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    try {
      final status = await service.runCommand(_repoName, ['status']);
      final branches = await service.runCommand(_repoName, ['branch', '-a']);
      String? remoteOutput;
      String? graphOutput;
      try {
        remoteOutput = await service.runCommand(_repoName, ['remote', '-v']);
      } catch (_) {}
      try {
        graphOutput = await service.runCommand(
          _repoName,
          ['log', '--oneline', '--graph', '--all', '-n', '25'],
        );
      } catch (_) {}
      if (mounted) {
        setState(() {
          _statusOutput = status;
          _branchesOutput = branches;
          _remoteOutput = remoteOutput;
          _graphOutput = graphOutput;
          _currentBranch = _parseCurrentBranch(branches);
          _localBranchNames = _parseLocalBranches(branches);
        });
      }
    } catch (_) {}
  }

  static String? _parseCurrentBranch(String branchesOutput) {
    for (final line in branchesOutput.split('\n')) {
      final t = line.trim();
      if (t.startsWith('* ')) return t.substring(2).trim();
    }
    return null;
  }

  static List<String> _parseLocalBranches(String branchesOutput) {
    final names = <String>[];
    for (final line in branchesOutput.split('\n')) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('remotes/')) continue;
      final name = t.startsWith('* ') ? t.substring(2).trim() : t;
      if (name.isNotEmpty && !names.contains(name)) names.add(name);
    }
    return names;
  }

  static String? _parseOriginUrl(String remoteOutput) {
    for (final line in remoteOutput.split('\n')) {
      if (line.contains('origin') && line.contains('\t')) {
        final parts = line.split('\t');
        if (parts.length >= 2 && parts[0].trim() == 'origin') {
          return parts[1].trim().split(' ').first;
        }
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDir());
  }

  void _navigateInto(String name) {
    setState(() {
      _pathSegments.add(name);
      _loadDir();
    });
  }

  void _navigateUp() {
    if (_pathSegments.isEmpty) return;
    setState(() {
      _pathSegments.removeLast();
      _loadDir();
    });
  }

  Future<void> _openFile(String path) async {
    if (!mounted) return;
    await context.push(
      '/home/local/${Uri.encodeComponent(_repoName)}/file?path=${Uri.encodeComponent(path)}',
    );
    if (mounted) _loadDir();
  }

  Future<void> _createFile() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    final pathController = TextEditingController(
      text:
          _currentPath.isEmpty ? 'filename.txt' : '$_currentPath/filename.txt',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New file'),
        content: TextField(
          controller: pathController,
          decoration: const InputDecoration(
            labelText: 'Path (relative to repo root)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(pathController.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await service.writeFile(_repoName, name, '');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created $name')),
        );
        _loadDir();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _gitAddAll() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    try {
      await service.runCommand(_repoName, ['add', '.']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staged all changes')),
        );
        _loadGitInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<String?> _ensureGitIdentity() async {
    String? name = await ref.read(effectiveGitUserNameProvider.future);
    String? email = await ref.read(effectiveGitUserEmailProvider.future);
    if (name != null && name.isNotEmpty && email != null && email.isNotEmpty) {
      return null; // have identity
    }
    // Prompt for name and email
    if (!mounted) return null;
    final nameController = TextEditingController(text: name ?? '');
    final emailController = TextEditingController(text: email ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Git identity required'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Git needs your name and email to record who made each commit. '
                'Set them below or in Settings → Git identity.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Your Name',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(false);
              context.push('/settings/git-identity');
            },
            child: const Text('Settings'),
          ),
          FilledButton(
            onPressed: () async {
              final n = nameController.text.trim();
              final e = emailController.text.trim();
              if (n.isEmpty || e.isEmpty) return;
              await saveGitUserName(n);
              await saveGitUserEmail(e);
              ref.read(gitIdentityInvalidatorProvider)();
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Save & continue'),
          ),
        ],
      ),
    );
    nameController.dispose();
    emailController.dispose();
    if (result != true) return null;
    name = await ref.read(effectiveGitUserNameProvider.future);
    email = await ref.read(effectiveGitUserEmailProvider.future);
    if (name == null || name.isEmpty || email == null || email.isEmpty) {
      return null;
    }
    return null; // caller will re-read providers
  }

  Future<void> _gitCommit() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    await _ensureGitIdentity();
    String? name = await ref.read(effectiveGitUserNameProvider.future);
    String? email = await ref.read(effectiveGitUserEmailProvider.future);
    if (name == null || name.isEmpty || email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Set your name and email in Settings → Git identity to commit'),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    final messageController = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Commit'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(
            labelText: 'Commit message',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(messageController.text.trim()),
            child: const Text('Commit'),
          ),
        ],
      ),
    );
    if (message == null) return;
    try {
      await service.runCommand(_repoName, ['config', 'user.name', name]);
      await service.runCommand(_repoName, ['config', 'user.email', email]);
      await service.runCommand(_repoName, ['commit', '-m', message]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Committed')),
        );
        _loadGitInfo();
        _loadDir();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _createBranch() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    if (_localBranchNames.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No branch to create from')));
      return;
    }
    final nameController = TextEditingController();
    String? selectedFrom = _localBranchNames.contains(_currentBranch)
        ? _currentBranch
        : _localBranchNames.first;
    final result = await showDialog<({String name, String from})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create branch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Branch name',
                  hintText: 'feature/xyz',
                ),
                textCapitalization: TextCapitalization.none,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _localBranchNames.isNotEmpty &&
                        selectedFrom != null &&
                        _localBranchNames.contains(selectedFrom)
                    ? selectedFrom
                    : (_localBranchNames.isNotEmpty
                        ? _localBranchNames.first
                        : null),
                decoration: const InputDecoration(labelText: 'From branch'),
                items: _localBranchNames
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => selectedFrom = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final n = nameController.text.trim();
                if (n.isEmpty) return;
                Navigator.of(ctx).pop(
                    (name: n, from: selectedFrom ?? _localBranchNames.first));
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (result == null) return;
    try {
      await service
          .runCommand(_repoName, ['checkout', '-b', result.name, result.from]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Branch "${result.name}" created')));
        _loadGitInfo();
        _loadDir();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _checkoutBranch(String branch) async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    try {
      await service.runCommand(_repoName, ['checkout', branch]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Switched to $branch')));
        _loadGitInfo();
        _loadDir();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteBranch(String branch) async {
    if (branch == _currentBranch) return;
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete branch'),
        content: Text('Delete branch "$branch"? This does not delete commits.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await service.runCommand(_repoName, ['branch', '-d', branch]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Deleted branch $branch')));
        _loadGitInfo();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showMergeDialog() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    final others = _localBranchNames.where((b) => b != _currentBranch).toList();
    if (others.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No other branch to merge')));
      return;
    }
    String? selected = others.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Merge branch'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'Merge into current'),
            items: others
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) {
              setDialogState(() => selected = v);
            },
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Merge'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == null) return;
    try {
      await service.runCommand(_repoName, ['merge', selected!]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Merged $selected')));
        _loadGitInfo();
        _loadDir();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _addOrSetRemote() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    final urlController =
        TextEditingController(text: _parseOriginUrl(_remoteOutput ?? '') ?? '');
    final hasOrigin =
        _remoteOutput != null && _remoteOutput!.contains('origin');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasOrigin ? 'Set remote origin URL' : 'Add remote origin'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://github.com/user/repo.git',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final u = urlController.text.trim();
              if (u.isEmpty) return;
              Navigator.of(ctx).pop(u);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    urlController.dispose();
    if (url == null || url.isEmpty) return;
    try {
      if (hasOrigin) {
        await service
            .runCommand(_repoName, ['remote', 'set-url', 'origin', url]);
      } else {
        await service.runCommand(_repoName, ['remote', 'add', 'origin', url]);
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Remote updated')));
        _loadGitInfo();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _push() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    final branch = _currentBranch ?? 'main';
    try {
      await service.runCommand(_repoName, ['push', '-u', 'origin', branch]);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Pushed to origin')));
        _loadGitInfo();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pull() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    try {
      await service
          .runCommand(_repoName, ['pull', 'origin', _currentBranch ?? 'main']);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Pulled from origin')));
        _loadGitInfo();
        _loadDir();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(
            title: _repoName,
            onBack: () => context.go('/home/local'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New file',
                onPressed: _createFile,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Git add all',
                onPressed: _gitAddAll,
              ),
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'Commit',
                onPressed: _gitCommit,
              ),
              IconButton(
                icon:
                    Icon(_showGitInfo ? Icons.expand_less : Icons.expand_more),
                tooltip: 'Status & branches',
                onPressed: () => setState(() => _showGitInfo = !_showGitInfo),
              ),
            ],
          ),
          if (_pathSegments.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pathSegments.isEmpty ? null : _navigateUp,
                      child: Chip(
                        avatar: const Icon(Icons.folder_open, size: 18),
                        label: const Text('root'),
                      ),
                    ),
                    ..._pathSegments.map((s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_right, size: 20),
                            GestureDetector(
                              onTap: () {
                                final i = _pathSegments.indexOf(s);
                                setState(() {
                                  _pathSegments.removeRange(
                                    i + 1,
                                    _pathSegments.length,
                                  );
                                  _loadDir();
                                });
                              },
                              child: Chip(label: Text(s)),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          if (_loading && _entries == null)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text(_error!, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        setState(() => _error = null);
                        _loadDir();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_entries != null)
            SliverList(
              delegate: SliverChildListDelegate([
                if (_pathSegments.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('..'),
                    onTap: _navigateUp,
                  ),
                ..._entries!.map((e) {
                  final relPath =
                      _currentPath.isEmpty ? e.name : '$_currentPath/${e.name}';
                  return ListTile(
                    leading: Icon(
                      e.isDir ? Icons.folder : Icons.description_outlined,
                    ),
                    title: Text(e.name),
                    trailing: e.isDir ? const Icon(Icons.chevron_right) : null,
                    onTap: () {
                      if (e.isDir) {
                        _navigateInto(e.name);
                      } else {
                        _openFile(relPath);
                      }
                    },
                  );
                }),
                if (_showGitInfo &&
                    (_statusOutput != null ||
                        _branchesOutput != null ||
                        _graphOutput != null)) ...[
                  const Divider(height: 32),
                  if (_statusOutput != null && _statusOutput!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.gitBranch,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Status',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card.outlined(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            _statusOutput!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_graphOutput != null && _graphOutput!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.treeStructure,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Branch tree',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card.outlined(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            _graphOutput!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_localBranchNames.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Row(
                        children: [
                          Icon(PhosphorIconsRegular.gitBranch,
                              size: 20, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Branches',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card.outlined(
                        child: Column(
                          children: [
                            if (_currentBranch != null)
                              ListTile(
                                dense: true,
                                title: Text(_currentBranch!,
                                    style: theme.textTheme.titleSmall),
                                subtitle: const Text('Current branch'),
                              ),
                            ..._localBranchNames.map((b) {
                              final isCurrent = b == _currentBranch;
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isCurrent
                                      ? Icons.check_circle
                                      : PhosphorIconsRegular.gitBranch,
                                  size: 20,
                                  color: isCurrent
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                                title: Text(b),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isCurrent) ...[
                                      TextButton(
                                        onPressed: () => _checkoutBranch(b),
                                        child: const Text('Checkout'),
                                      ),
                                      TextButton(
                                        onPressed: () => _deleteBranch(b),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: _createBranch,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Create branch'),
                                  ),
                                  TextButton.icon(
                                    onPressed: _showMergeDialog,
                                    icon:
                                        const Icon(Icons.merge_type, size: 18),
                                    label: const Text('Merge'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_outlined,
                            size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Remote',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_remoteOutput != null && _remoteOutput!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card.outlined(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SelectableText(
                                _remoteOutput!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  FilledButton.tonalIcon(
                                    onPressed: _addOrSetRemote,
                                    icon: const Icon(Icons.settings_ethernet,
                                        size: 18),
                                    label: const Text('Origin URL'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: _push,
                                    icon: const Icon(Icons.upload, size: 18),
                                    label: const Text('Push'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.tonalIcon(
                                    onPressed: _pull,
                                    icon: const Icon(Icons.download, size: 18),
                                    label: const Text('Pull'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Card.outlined(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'No remote configured.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton.tonalIcon(
                                onPressed: _addOrSetRemote,
                                icon: const Icon(Icons.add_link, size: 18),
                                label: const Text('Add remote origin'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 32),
              ]),
            ),
        ],
      ),
      floatingActionButton: _entries != null && _error == null
          ? FloatingActionButton.extended(
              onPressed: () {
                setState(() => _showGitInfo = !_showGitInfo);
                if (!_showGitInfo) return;
                _loadGitInfo();
              },
              icon: const Icon(Icons.info_outline),
              label: Text(_showGitInfo ? 'Hide status' : 'Status & branches'),
            )
          : null,
    );
  }
}
