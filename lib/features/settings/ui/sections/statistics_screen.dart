import 'package:flutter/material.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:autogit/core/providers/github_stats_providers.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class StatisticsItem extends StatelessWidget {
  const StatisticsItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final repoStatsAsync = ref.watch(githubRepoStatsProvider);
    final userStatsAsync = ref.watch(githubUserStatsProvider);

    if (!hasToken) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Statistics'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in with GitHub to see your statistics',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
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
          const LargeAppBar(title: 'Statistics'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Repositories',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          repoStatsAsync.when(
            data: (stats) => SliverList(
              delegate: SliverChildListDelegate([
                StatisticsItem(
                  title: 'Total repositories',
                  value: '${stats.repoCount}',
                  icon: OctIcons.repo_16,
                ),
                StatisticsItem(
                  title: 'Public repositories',
                  value: '${stats.publicRepoCount}',
                  icon: OctIcons.repo_16,
                ),
                StatisticsItem(
                  title: 'Private repositories',
                  value: '${stats.privateRepoCount}',
                  icon: OctIcons.lock_16,
                ),
                StatisticsItem(
                  title: 'Total stars received',
                  value: '${stats.totalStars}',
                  icon: OctIcons.star_16,
                ),
                StatisticsItem(
                  title: 'Total forks',
                  value: '${stats.totalForks}',
                  icon: OctIcons.repo_forked_16,
                ),
              ]),
            ),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error: $e',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Profile',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          userStatsAsync.when(
            data: (stats) {
              if (stats == null)
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverList(
                delegate: SliverChildListDelegate([
                  StatisticsItem(
                    title: 'Public repos (profile)',
                    value: '${stats.publicRepos}',
                    icon: OctIcons.repo_16,
                  ),
                  StatisticsItem(
                    title: 'Followers',
                    value: '${stats.followers}',
                    icon: OctIcons.people_16,
                  ),
                  StatisticsItem(
                    title: 'Following',
                    value: '${stats.following}',
                    icon: Icons.person_outline,
                  ),
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
