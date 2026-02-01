import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(githubUsernameProvider);
    final hasToken = ref.watch(isSignedInWithGitHubProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'Settings'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Account',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                leading: const Icon(FontAwesomeIcons.github),
                title: const Text('GitHub account'),
                subtitle: Text(
                  hasToken && username != null
                      ? 'Signed in as $username'
                      : 'Not signed in',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/profile'),
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.palette),
                title: const Text('Appearance'),
                subtitle: const Text('Theme, accent color'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/appearance'),
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Features',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                leading: const Icon(FontAwesomeIcons.robot),
                title: const Text('AI / Assistant'),
                subtitle: const Text('Ollama, OpenAI, Claude, Gemini'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/ai'),
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.code),
                title: const Text('Editor'),
                subtitle: const Text('Code editor preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Data',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                leading: const Icon(FontAwesomeIcons.chartLine),
                title: const Text('Statistics'),
                subtitle: const Text('Repos, stars, contributions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/statistics'),
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.database),
                title: const Text('Cache & storage'),
                subtitle: const Text('Clear cached data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'About',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ListTile(
                leading: const Icon(FontAwesomeIcons.info),
                title: const Text('About AutoGit'),
                subtitle: const Text('Version, licenses'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/about'),
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.fileContract),
                title: const Text('Privacy & terms'),
                subtitle: const Text('Privacy policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
