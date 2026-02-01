import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
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
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: Icons.folder,
                      label: 'Local Repositories',
                      onTap: () => context.push('/home/local'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      icon: FontAwesomeIcons.github,
                      label: 'Remote Repositories',
                      onTap: () => context.push('/home/github'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              _buildListTile(
                context,
                icon: Icons.star,
                title: 'Starred Repositories',
                onTap: () => context.push('/home/starred'),
              ),
              _buildListTile(
                context,
                icon: Icons.visibility,
                title: 'Watched Repositories',
                onTap: () => context.push('/home/watched'),
              ),
              _buildListTile(
                context,
                icon: Icons.assignment,
                title: 'Issues',
                onTap: () => context.push('/home/issues'),
                trailing: issuesCount > 0
                    ? Text(
                        '$issuesCount',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              ),
              _buildListTile(
                context,
                icon: Icons.call_merge,
                title: 'Pull Requests',
                onTap: () => context.push('/home/pull-requests'),
                trailing: prsCount > 0
                    ? Text(
                        '$prsCount',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              ),
              _buildListTile(
                context,
                icon: Icons.public,
                title: 'Sites (GitHub Pages)',
                onTap: () => context.push('/home/sites'),
              ),
              _buildListTile(
                context,
                icon: Icons.dashboard_customize,
                title: 'Projects',
                onTap: () => context.push('/home/projects'),
              ),
              _buildListTile(
                context,
                icon: Icons.forum_outlined,
                title: 'Discussions',
                onTap: () => context.push('/home/discussions'),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
    );
  }
}
