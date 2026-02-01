import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/core/providers/github_home_providers.dart';
import 'package:autogit/core/providers/github_user_issue_pr_api.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class PullRequestsScreen extends ConsumerWidget {
  const PullRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final async = ref.watch(myPullRequestsProvider);

    if (!hasToken) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Pull Requests'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.call_merge,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in with GitHub to see your pull requests',
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
          const LargeAppBar(title: 'Pull Requests'),
          async.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No open pull requests',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final pr = list[index];
                  final title = pr['title'] as String? ?? 'Untitled';
                  final number = pr['number'] as int?;
                  final state = pr['state'] as String? ?? 'open';
                  final repoUrl = pr['repository_url'] as String? ?? '';
                  final segments = repoUrl
                      .split('/')
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final repoName = segments.length >= 2
                      ? '${segments[segments.length - 2]}/${segments.last}'
                      : repoUrl;
                  String? owner;
                  String? repo;
                  parseRepoUrl(repoUrl, (o, r) {
                    owner = o;
                    repo = r;
                  });
                  return ListTile(
                    leading: Icon(
                      OctIcons.git_pull_request_16,
                      color: state == 'open' ? Colors.green : Colors.purple,
                    ),
                    title: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      repoName + (number != null ? ' #$number' : ''),
                    ),
                    onTap: () {
                      if (owner != null && repo != null && number != null) {
                        context.push(
                          '/home/pr/${Uri.encodeComponent(owner!)}/${Uri.encodeComponent(repo!)}/$number',
                        );
                      }
                    },
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
