import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/core/providers/github_user_issue_pr_api.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class PRDetailScreen extends ConsumerStatefulWidget {
  const PRDetailScreen({
    super.key,
    required this.owner,
    required this.repo,
    required this.number,
  });

  final String owner;
  final String repo;
  final int number;

  @override
  ConsumerState<PRDetailScreen> createState() => _PRDetailScreenState();
}

class _PRDetailScreenState extends ConsumerState<PRDetailScreen> {
  Map<String, dynamic>? _pr;
  List<Map<String, dynamic>> _comments = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(githubTokenProvider);
    try {
      final pr = await getPullRequest(
        owner: widget.owner,
        repo: widget.repo,
        number: widget.number,
        token: token,
      );
      final comments = await getIssueComments(
        owner: widget.owner,
        repo: widget.repo,
        number: widget.number,
        token: token,
      );
      if (mounted) {
        setState(() {
          _pr = pr;
          _comments = comments;
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('PR #${widget.number}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('PR #${widget.number}')),
        body: Center(child: Text('Error: $_error')),
      );
    }
    final pr = _pr!;
    final title = pr['title'] as String? ?? 'Untitled';
    final state = pr['state'] as String? ?? 'open';
    final body = pr['body'] as String?;
    final user = pr['user'] as Map<String, dynamic>?;
    final login = user?['login'] as String? ?? 'unknown';
    final avatarUrl = user?['avatar_url'] as String?;
    final createdAt = pr['created_at'] as String?;
    final htmlUrl = pr['html_url'] as String?;
    final head = pr['head'] as Map<String, dynamic>?;
    final base = pr['base'] as Map<String, dynamic>?;
    final headRef = head?['ref'] as String? ?? '';
    final baseRef = base?['ref'] as String? ?? '';
    final mergeable = pr['mergeable'];
    final merged = pr['merged'] as bool? ?? false;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            title: Text('${widget.owner}/${widget.repo} #${widget.number}'),
            actions: [
              if (htmlUrl != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () => launchUrlString(htmlUrl),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        OctIcons.git_pull_request_16,
                        color: state == 'open'
                            ? Colors.green
                            : (merged ? Colors.purple : Colors.red),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(state),
                        visualDensity: VisualDensity.compact,
                      ),
                      if (merged)
                        const Chip(
                          label: Text('Merged'),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (mergeable != null)
                        Chip(
                          label: Text('Mergeable: $mergeable'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$baseRef \u2190 $headRef',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? Text(
                              login.isNotEmpty ? login[0].toUpperCase() : '?',
                            )
                          : null,
                    ),
                    title: Text(login),
                    subtitle: createdAt != null
                        ? Text(_formatDate(createdAt))
                        : null,
                  ),
                  if (body != null && body.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: body,
                      selectable: true,
                      onTapLink: (text, href, title) {
                        if (href != null) launchUrlString(href);
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge,
                        h1: Theme.of(context).textTheme.headlineSmall,
                        h2: Theme.of(context).textTheme.titleLarge,
                        h3: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_comments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Comments (${_comments.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final c = _comments[index];
                final cUser = c['user'] as Map<String, dynamic>?;
                final cLogin = cUser?['login'] as String? ?? 'unknown';
                final cAvatar = cUser?['avatar_url'] as String?;
                final cBody = c['body'] as String? ?? '';
                final cCreated = c['created_at'] as String?;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: cAvatar != null
                                  ? NetworkImage(cAvatar)
                                  : null,
                              child: cAvatar == null
                                  ? Text(
                                      cLogin.isNotEmpty
                                          ? cLogin[0].toUpperCase()
                                          : '?',
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cLogin,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            if (cCreated != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(cCreated),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        MarkdownBody(
                          data: cBody,
                          selectable: true,
                          onTapLink: (text, href, title) {
                            if (href != null) launchUrlString(href);
                          },
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: _comments.length),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
