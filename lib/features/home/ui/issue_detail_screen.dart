import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/core/providers/github_user_issue_pr_api.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class IssueDetailScreen extends ConsumerStatefulWidget {
  const IssueDetailScreen({
    super.key,
    required this.owner,
    required this.repo,
    required this.number,
  });

  final String owner;
  final String repo;
  final int number;

  @override
  ConsumerState<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends ConsumerState<IssueDetailScreen> {
  Map<String, dynamic>? _issue;
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
      final issue = await getIssue(
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
          _issue = issue;
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
        appBar: AppBar(title: Text('#${widget.number}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('#${widget.number}')),
        body: Center(child: Text('Error: $_error')),
      );
    }
    final issue = _issue!;
    final title = issue['title'] as String? ?? 'Untitled';
    final state = issue['state'] as String? ?? 'open';
    final body = issue['body'] as String?;
    final user = issue['user'] as Map<String, dynamic>?;
    final login = user?['login'] as String? ?? 'unknown';
    final avatarUrl = user?['avatar_url'] as String?;
    final createdAt = issue['created_at'] as String?;
    final htmlUrl = issue['html_url'] as String?;

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
                  onPressed: () => _openUrl(htmlUrl),
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
                        state == 'open'
                            ? OctIcons.issue_opened_16
                            : OctIcons.issue_closed_16,
                        color: state == 'open' ? Colors.green : Colors.red,
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
                        if (href != null) _openUrl(href);
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
                            if (href != null) _openUrl(href);
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

  void _openUrl(String url) {
    launchUrlString(url);
  }
}
