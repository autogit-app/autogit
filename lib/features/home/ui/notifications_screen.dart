import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/core/providers/github_home_providers.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final async = ref.watch(notificationsProvider);

    if (!hasToken) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Notifications'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in with GitHub to see notifications',
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
          const LargeAppBar(title: 'Notifications'),
          async.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No notifications',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final n = list[index];
                  final subject = n['subject'] as Map<String, dynamic>?;
                  final title = subject?['title'] as String? ?? 'Notification';
                  final type = subject?['type'] as String? ?? '';
                  final repo = n['repository'] as Map<String, dynamic>?;
                  final fullName = repo?['full_name'] as String? ?? '';
                  final reason = n['reason'] as String? ?? '';
                  final unread = n['unread'] as bool? ?? false;
                  return ListTile(
                    leading: Icon(
                      type == 'PullRequest'
                          ? OctIcons.git_pull_request_16
                          : OctIcons.issue_opened_16,
                    ),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text('$fullName · $reason'),
                    isThreeLine: true,
                    trailing: unread
                        ? Icon(
                            Icons.circle,
                            size: 8,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  );
                }, childCount: list.length),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('Error: $e', textAlign: TextAlign.center),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
