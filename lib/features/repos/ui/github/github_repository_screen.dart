import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/repos/data/github_repo_api.dart';

class GithubRepositoryScreen extends ConsumerStatefulWidget {
  const GithubRepositoryScreen({
    super.key,
    required this.owner,
    required this.repo,
  });

  final String owner;
  final String repo;

  @override
  ConsumerState<GithubRepositoryScreen> createState() =>
      _GithubRepositoryScreenState();
}

class _GithubRepositoryScreenState
    extends ConsumerState<GithubRepositoryScreen> {
  @override
  Widget build(BuildContext context) {
    final token = ref.watch(githubTokenProvider);
    const path = '';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.owner}/${widget.repo}${path.isNotEmpty ? '/$path' : ''}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => launchUrlString(
              'https://github.com/${widget.owner}/${widget.repo}',
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _onMenuSelected(context, value, token),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_file',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('New file'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'issue',
                child: ListTile(
                  title: Text('New issue'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'pr',
                child: ListTile(
                  title: Text('New pull request'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'branches',
                child: ListTile(
                  title: Text('Branches'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'list_prs',
                child: ListTile(
                  title: Text('Pull requests'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RepositoryContentsList(
        owner: widget.owner,
        repoName: widget.repo,
        path: path,
        token: token,
      ),
    );
  }

  void _onMenuSelected(BuildContext context, String value, String? token) {
    switch (value) {
      case 'new_file':
        _showNewFileDialog(context, token);
        break;
      case 'issue':
        _showNewIssueDialog(context, token);
        break;
      case 'pr':
        _showNewPRDialog(context, token);
        break;
      case 'branches':
        _showBranchesSheet(context, token);
        break;
      case 'list_prs':
        _showPRsSheet(context, token);
        break;
    }
  }

  Future<void> _showNewFileDialog(BuildContext context, String? token) async {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with GitHub to create files')),
      );
      return;
    }
    final pathController = TextEditingController(text: 'index.html');
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New file'),
        content: TextField(
          controller: pathController,
          decoration: const InputDecoration(
            labelText: 'File path',
            hintText: 'e.g. index.html, src/main.dart',
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
    if (created != true || !context.mounted) return;
    final path = pathController.text.trim();
    if (path.isEmpty) return;
    context.push(
      '/home/github/${Uri.encodeComponent(widget.owner)}/${Uri.encodeComponent(widget.repo)}/file?path=${Uri.encodeComponent(path)}',
    );
  }

  Future<void> _showNewIssueDialog(BuildContext context, String? token) async {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with GitHub to create issues')),
      );
      return;
    }
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New issue'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Body (optional)'),
                maxLines: 4,
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
      ),
    );
    if (created != true || !context.mounted) return;
    try {
      await createIssue(
        owner: widget.owner,
        repo: widget.repo,
        title: titleController.text.trim(),
        body: bodyController.text.trim().isEmpty
            ? null
            : bodyController.text.trim(),
        token: token,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Issue created')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _showNewPRDialog(BuildContext context, String? token) async {
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in with GitHub to create PRs')),
      );
      return;
    }
    String? baseBranch;
    try {
      final info = await getDefaultBranchAndSha(
        owner: widget.owner,
        repo: widget.repo,
        token: token,
      );
      baseBranch = info['branch'];
    } catch (_) {
      baseBranch = 'main';
    }
    final branches = await listBranches(
      owner: widget.owner,
      repo: widget.repo,
      token: token,
    );
    final branchNames = branches
        .map((b) => b['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    var headBranch = branchNames.isNotEmpty ? branchNames.first : '';
    var base = baseBranch ?? 'main';
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('New pull request'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Body (optional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: headBranch.isEmpty ? null : headBranch,
                    decoration: const InputDecoration(labelText: 'Head branch'),
                    items: branchNames
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => headBranch = v ?? ''),
                  ),
                  DropdownButtonFormField<String>(
                    value: base,
                    decoration: const InputDecoration(labelText: 'Base branch'),
                    items: branchNames
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => base = v ?? base),
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
    try {
      await createPullRequest(
        owner: widget.owner,
        repo: widget.repo,
        title: titleController.text.trim(),
        body: bodyController.text.trim().isEmpty
            ? null
            : bodyController.text.trim(),
        head: headBranch,
        base: base,
        token: token,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pull request created')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _showBranchesSheet(BuildContext context, String? token) async {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) =>
            FutureBuilder<List<Map<String, dynamic>>>(
              future: listBranches(
                owner: widget.owner,
                repo: widget.repo,
                token: token,
              ),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final branches = snapshot.data ?? [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Branches', style: theme.textTheme.titleLarge),
                          if (token != null && token.isNotEmpty)
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Create branch'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showCreateBranchDialog(
                                  context,
                                  token,
                                  branches,
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: branches.length,
                        itemBuilder: (ctx, i) {
                          final b = branches[i];
                          final name = b['name'] as String? ?? '';
                          final sha =
                              (b['commit'] as Map<String, dynamic>?)?['sha']
                                  as String? ??
                              '';
                          return ListTile(
                            leading: const Icon(OctIcons.git_branch_16),
                            title: Text(name),
                            subtitle: Text(
                              sha.length > 8 ? sha.substring(0, 8) : sha,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Future<void> _showCreateBranchDialog(
    BuildContext context,
    String token,
    List<Map<String, dynamic>> branches,
  ) async {
    String? defaultBranch;
    String? defaultSha;
    try {
      final info = await getDefaultBranchAndSha(
        owner: widget.owner,
        repo: widget.repo,
        token: token,
      );
      defaultBranch = info['branch'];
      defaultSha = info['sha'];
    } catch (_) {}
    final nameController = TextEditingController();
    var fromBranch =
        defaultBranch ??
        (branches.isNotEmpty ? (branches.first['name'] as String?) : null) ??
        'main';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Create branch'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Branch name'),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: fromBranch,
                  decoration: const InputDecoration(labelText: 'From branch'),
                  items: branches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b['name'] as String?,
                          child: Text(b['name'] as String? ?? ''),
                        ),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => fromBranch = v ?? fromBranch),
                ),
              ],
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
    if (ok != true || !context.mounted) return;
    final branchName = nameController.text.trim();
    if (branchName.isEmpty) return;
    Map<String, dynamic>? fromBranchData;
    for (final b in branches) {
      if (b['name'] == fromBranch) {
        fromBranchData = b;
        break;
      }
    }
    final commit = fromBranchData?['commit'] as Map<String, dynamic>?;
    final sha = commit?['sha'] as String? ?? defaultSha ?? '';
    if (sha.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not get commit SHA')));
      return;
    }
    try {
      await createBranch(
        owner: widget.owner,
        repo: widget.repo,
        branchName: branchName,
        fromSha: sha,
        token: token,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Branch $branchName created')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _showPRsSheet(BuildContext context, String? token) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) =>
            FutureBuilder<List<Map<String, dynamic>>>(
              future: listPullRequests(
                owner: widget.owner,
                repo: widget.repo,
                token: token,
              ),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final prs = snapshot.data ?? [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Pull requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: prs.length,
                        itemBuilder: (ctx, i) {
                          final pr = prs[i];
                          final number = pr['number'] as int? ?? 0;
                          final title = pr['title'] as String? ?? '';
                          final state = pr['state'] as String? ?? 'open';
                          final mergeable = pr['mergeable'] as bool?;
                          return ListTile(
                            leading: Icon(
                              OctIcons.git_pull_request_16,
                              color: state == 'open'
                                  ? Colors.green
                                  : Colors.purple,
                            ),
                            title: Text(
                              '#$number $title',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(state),
                            trailing:
                                state == 'open' &&
                                    mergeable == true &&
                                    token != null
                                ? FilledButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      try {
                                        await mergePullRequest(
                                          owner: widget.owner,
                                          repo: widget.repo,
                                          pullNumber: number,
                                          token: token,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('PR merged'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Merge failed: $e'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('Merge'),
                                  )
                                : null,
                            onTap: () {
                              final url = pr['html_url'] as String?;
                              if (url != null) launchUrlString(url);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class RepositoryContentsList extends ConsumerStatefulWidget {
  final String owner;
  final String repoName;
  final String path;
  final String? token;

  const RepositoryContentsList({
    super.key,
    required this.owner,
    required this.repoName,
    required this.path,
    this.token,
  });

  @override
  ConsumerState<RepositoryContentsList> createState() =>
      _RepositoryContentsListState();
}

class _RepositoryContentsListState
    extends ConsumerState<RepositoryContentsList> {
  final Map<String, bool> _expandedFolders = {};

  Future<List<Map<String, dynamic>>> _fetchContents(
    String owner,
    String repo,
    String path,
    String? token,
  ) async {
    try {
      final pathComponent = path.isNotEmpty ? '/contents/$path' : '/contents';
      final uri = Uri.https(
        'api.github.com',
        '/repos/$owner/$repo$pathComponent',
      );

      debugPrint('Fetching contents from: $uri');

      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'AutoGit',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data)
              .where((item) => item['name'] != null && item['type'] != null)
              .toList();
        } else if (data is Map<String, dynamic> && data['name'] != null) {
          // If it's a single file, return it in a list if it has a name
          return [data];
        }
        return [];
      } else {
        throw Exception(
          'Failed to load repository contents: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching contents: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building RepositoryContentsList with path: ${widget.path}');
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchContents(
        widget.owner,
        widget.repoName,
        widget.path,
        widget.token,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading contents:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text('No files found in this directory'),
              ],
            ),
          );
        }

        // Sort contents (directories first, then files)
        final contents = List<Map<String, dynamic>>.from(snapshot.data!);
        contents.sort((a, b) {
          final aType = a['type']?.toString() ?? '';
          final bType = b['type']?.toString() ?? '';
          final aName = a['name']?.toString().toLowerCase() ?? '';
          final bName = b['name']?.toString().toLowerCase() ?? '';

          if (aType == 'dir' && bType != 'dir') return -1;
          if (aType != 'dir' && bType == 'dir') return 1;
          return aName.compareTo(bName);
        });

        final isNested = widget.path.isNotEmpty;
        return ListView.builder(
          shrinkWrap: isNested,
          physics: isNested ? const NeverScrollableScrollPhysics() : null,
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final item = contents[index];
            final isExpanded = _expandedFolders[item['path']] ?? false;

            if (item['type'] == 'dir') {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListTile(
                    leading: Icon(
                      isExpanded
                          ? OctIcons.chevron_down_16
                          : OctIcons.chevron_right_16,
                    ),
                    title: Text(item['name'] ?? 'Unnamed Directory'),
                    dense: true,
                    onTap: () {
                      setState(() {
                        _expandedFolders[item['path'] ?? ''] = !isExpanded;
                      });
                    },
                  ),
                  if (isExpanded)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: RepositoryContentsList(
                        owner: widget.owner,
                        repoName: widget.repoName,
                        path: item['path'] ?? '',
                        token: widget.token,
                      ),
                    ),
                ],
              );
            } else {
              return ListTile(
                leading: _getFileIcon(item['name'] ?? ''),
                title: Text(item['name'] ?? 'Unnamed File'),
                dense: true,
                onTap: () {
                  // Handle file tap (e.g., view file content)
                  _showFileContent(context, item);
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final iconMap = <String, IconData>{
      'dart': OctIcons.file_code_16,
      'yaml': OctIcons.file_code_16,
      'yml': OctIcons.file_code_16,
      'json': OctIcons.file_code_16,
      'md': OctIcons.markdown_16,
      'jpg': OctIcons.file_media_16,
      'jpeg': OctIcons.file_media_16,
      'png': OctIcons.file_media_16,
      'gif': OctIcons.file_media_16,
      'pdf': OctIcons.file_16, // Using file_16 as fallback for PDF
      'zip': OctIcons.file_zip_16,
      'txt': OctIcons.file_16,
    };

    return Icon(iconMap[extension] ?? OctIcons.file_16);
  }

  void _showFileContent(BuildContext context, Map<String, dynamic> file) async {
    final filePath = file['path']?.toString() ?? file['name']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.25,
        maxChildSize: 0.9,
        builder: (_, controller) => FutureBuilder<String>(
          future: _getFileContent(file),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                AppBar(
                  title: Text(file['name']?.toString() ?? 'File Content'),
                  automaticallyImplyLeading: false,
                  actions: [
                    if (widget.token != null && widget.token!.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit',
                        onPressed: () {
                          Navigator.pop(context);
                          context.push(
                            '/home/github/${Uri.encodeComponent(widget.owner)}/${Uri.encodeComponent(widget.repoName)}/file?path=${Uri.encodeComponent(filePath)}',
                          );
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        snapshot.data ?? 'Unable to load file content',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<String> _getFileContent(Map<String, dynamic> file) async {
    try {
      final downloadUrl = file['download_url']?.toString();
      if (downloadUrl == null || downloadUrl.isEmpty) {
        return 'No download URL available for this file';
      }

      final headers = <String, String>{'User-Agent': 'AutoGit'};
      if (widget.token != null && widget.token!.isNotEmpty) {
        headers['Authorization'] = 'Bearer ${widget.token}';
      }

      final response = await http.get(Uri.parse(downloadUrl), headers: headers);

      if (response.statusCode == 200) {
        return response.body;
      }
      return 'Unable to display file content (Status: ${response.statusCode})';
    } catch (e) {
      debugPrint('Error loading file content: $e');
      return 'Error loading file: $e';
    }
  }
}
