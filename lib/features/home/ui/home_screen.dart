import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/auth.dart';
import 'package:autogit/features/github/github.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final username = ref.watch(githubUsernameProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final issuesAsync = ref.watch(myIssuesProvider);
    final prsAsync = ref.watch(myPullRequestsProvider);

    final notificationsList = notificationsAsync.value;
    final issuesList = issuesAsync.value;
    final prsList = prsAsync.value;
    final unreadCount =
        notificationsList?.where((n) => n['unread'] == true).length ?? 0;
    final issuesCount = issuesList?.length ?? 0;
    final prsCount = prsList?.length ?? 0;

    final title = username != null && username.isNotEmpty
        ? 'Welcome, $username!'
        : 'Welcome!';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(
            title: title,
            actions: [
              IconButton(
                icon: unreadCount > 0
                    ? Badge(
                        label: Text('$unreadCount'),
                        child: const Icon(Icons.notifications_outlined),
                      )
                    : const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/home/notifications'),
                tooltip: 'Notifications',
              ),
            ],
          ),

          // --- Repositories (primary actions) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Repositories',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 400;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: isNarrow
                      ? Column(
                          children: [
                            _RepoCard(
                              icon: PhosphorIconsRegular.folder,
                              label: 'Local',
                              subtitle: 'On this device',
                              onTap: () => context.push('/home/local'),
                            ),
                            const SizedBox(height: 12),
                            _RepoCard(
                              icon: FontAwesomeIcons.github,
                              label: 'Remote (GitHub)',
                              subtitle: 'Browse & edit on GitHub',
                              onTap: () => context.push('/home/github'),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _RepoCard(
                                icon: PhosphorIconsRegular.folder,
                                label: 'Local',
                                subtitle: 'On this device',
                                onTap: () => context.push('/home/local'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RepoCard(
                                icon: FontAwesomeIcons.github,
                                label: 'Remote (GitHub)',
                                subtitle: 'Browse & edit on GitHub',
                                onTap: () => context.push('/home/github'),
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),

          // --- Your activity ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'Your activity',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card.outlined(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HomeEntry(
                      icon: PhosphorIconsRegular.star,
                      title: 'Starred',
                      subtitle: 'Repositories you starred',
                      onTap: () => context.push('/home/starred'),
                    ),
                    const Divider(height: 1),
                    _HomeEntry(
                      icon: PhosphorIconsRegular.eye,
                      title: 'Watched',
                      subtitle: 'Repositories you watch',
                      onTap: () => context.push('/home/watched'),
                    ),
                    const Divider(height: 1),
                    _HomeEntry(
                      icon: PhosphorIconsRegular.clipboardText,
                      title: 'Issues',
                      subtitle: issuesCount > 0 ? '$issuesCount open' : null,
                      onTap: () => context.push('/home/issues'),
                      trailing: issuesCount > 0
                          ? Chip(
                              label: Text('$issuesCount'),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                    const Divider(height: 1),
                    _HomeEntry(
                      icon: PhosphorIconsRegular.gitPullRequest,
                      title: 'Pull requests',
                      subtitle: prsCount > 0 ? '$prsCount open' : null,
                      onTap: () => context.push('/home/pull-requests'),
                      trailing: prsCount > 0
                          ? Chip(
                              label: Text('$prsCount'),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- More from GitHub ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                'More from GitHub',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Card.outlined(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HomeEntry(
                      icon: PhosphorIconsRegular.globe,
                      title: 'Sites (GitHub Pages)',
                      subtitle: 'Hosted pages',
                      onTap: () => context.push('/home/sites'),
                    ),
                    const Divider(height: 1),
                    _HomeEntry(
                      icon: PhosphorIconsRegular.squaresFour,
                      title: 'Projects',
                      subtitle: 'Boards and tables',
                      onTap: () => context.push('/home/projects'),
                    ),
                    const Divider(height: 1),
                    _HomeEntry(
                      icon: PhosphorIconsRegular.chatCircle,
                      title: 'Discussions',
                      subtitle: 'Community Q&A',
                      onTap: () => context.push('/home/discussions'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _RepoCard extends StatelessWidget {
  const _RepoCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: colorScheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEntry extends StatelessWidget {
  const _HomeEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
