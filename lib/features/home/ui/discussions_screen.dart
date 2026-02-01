import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class DiscussionsScreen extends ConsumerWidget {
  const DiscussionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);

    if (!hasToken) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Discussions'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in with GitHub to see discussions',
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
          const LargeAppBar(title: 'Discussions'),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GitHub Discussions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Community discussions are available in repositories that enable them.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      // launchUrlString('https://github.com/discussions');
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Explore on GitHub'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
