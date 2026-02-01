import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/core/providers/github_home_providers.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class StarredScreen extends ConsumerWidget {
  const StarredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final async = ref.watch(starredReposProvider);

    if (!hasToken) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Starred Repositories'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_border,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in with GitHub to see starred repos',
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
          const LargeAppBar(title: 'Starred Repositories'),
          async.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No starred repositories',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final r = list[index];
                  final fullName = r['full_name'] as String? ?? '';
                  final parts = fullName.split('/');
                  final owner = parts.isNotEmpty ? parts[0] : '';
                  final repo = parts.length > 1 ? parts[1] : fullName;
                  final description = r['description'] as String?;
                  final stars = r['stargazers_count'] as int? ?? 0;
                  return ListTile(
                    leading: const Icon(OctIcons.repo_16),
                    title: Text(fullName),
                    subtitle: description != null
                        ? Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Text(
                      '★ $stars',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => context.push(
                      '/home/github/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}',
                    ),
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
