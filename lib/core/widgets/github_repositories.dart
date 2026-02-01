import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/features/auth/auth.dart';
import 'package:autogit/features/github/github.dart';

class GithubRepositories extends ConsumerWidget {
  const GithubRepositories({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final reposAsync = ref.watch(repoProvider);

    if (!hasToken) {
      return const Center(
        child: Text('Sign in with GitHub to see your repositories.'),
      );
    }

    return reposAsync.when(
      data: (githubRepos) => Expanded(
        child: ListView.separated(
          itemCount: githubRepos.length,
          itemBuilder: (context, index) {
            final repo = githubRepos[index];
            final name = repo.name ?? 'Unnamed';
            return ListTile(
              title: Text(name),
              subtitle: Text(
                'Updated at ${repo.updatedAt?.toString().substring(0, 10) ?? '—'}',
              ),
              trailing: Text('${repo.stargazersCount ?? 0} ⭐'),
              onTap: () {
                context.push('/home/github/$name');
              },
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider();
          },
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
