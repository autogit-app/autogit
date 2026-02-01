import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/auth.dart';
import 'package:autogit/features/github/github.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _profileContent = 'Loading profile...';
  bool _isLoading = true;
  String? _error;
  String? _lastLoadedUsername;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final username = ref.read(githubUsernameProvider);
    if (username != null && username != _lastLoadedUsername) {
      _lastLoadedUsername = username;
      _loadProfile(username);
    }
  }

  void _reloadProfile() {
    final username = ref.read(githubUsernameProvider);
    if (username != null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _loadProfile(username);
    }
  }

  Future<void> _loadProfile(String username) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/$username/$username/main/README.md',
        ),
      );

      if (mounted) {
        setState(() {
          if (response.statusCode == 200) {
            _profileContent = response.body;
          } else {
            _profileContent = '# $username\n\nWelcome to my GitHub profile!';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await GitHubAuthService.instance.logout();
    if (mounted) {
      ref.invalidate(authStateProvider);
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final username = ref.watch(githubUsernameProvider);
    final hasToken = ref.watch(isSignedInWithGitHubProvider);
    final reposAsync = ref.watch(userReposProvider);

    if (!hasToken || username == null || username.isEmpty) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            const LargeAppBar(title: 'Your Profile'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 64,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in with GitHub to see your profile',
                      style: textTheme.titleMedium,
                      textAlign: TextAlign.center,
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
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _reloadProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'Your Profile'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(
                          ref.watch(githubAvatarUrlProvider) ??
                              'https://github.com/$username.png?size=200',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        username,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('About Me', style: textTheme.titleLarge),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit readme'),
                    onPressed: () => context.push(
                      '/home/github/${Uri.encodeComponent(username)}/${Uri.encodeComponent(username)}/file?path=README.md',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Markdown(
                    shrinkWrap: true,
                    data: _profileContent,
                    selectable: true,
                    padding: EdgeInsets.zero,
                    styleSheet: MarkdownStyleSheet(
                      p: textTheme.bodyLarge,
                      h1: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      h2: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      h3: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      code: TextStyle(
                        backgroundColor: colorScheme.surfaceVariant.withOpacity(
                          0.5,
                        ),
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        border: Border(
                          left: BorderSide(
                            width: 4.0,
                            color: colorScheme.primary,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      blockquote: textTheme.bodyLarge?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      a: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) launchUrlString(href);
                    },
                    imageDirectory: 'https://raw.githubusercontent.com',
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text('Pinned repositories', style: textTheme.titleLarge),
            ),
          ),
          reposAsync.when(
            data: (repos) {
              final pinned = List.of(repos)
                ..sort(
                  (a, b) => (b.stargazersCount).compareTo(a.stargazersCount),
                );
              final top = pinned.take(6).toList();
              if (top.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final r = top[index];
                  return ListTile(
                    leading: const Icon(OctIcons.repo_16),
                    title: Text(r.name),
                    subtitle: r.description.isNotEmpty
                        ? Text(
                            r.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Text(
                      '${r.stargazersCount} ★',
                      style: textTheme.bodySmall,
                    ),
                    onTap: () => context.push(
                      '/home/github/${Uri.encodeComponent(username)}/${Uri.encodeComponent(r.name)}',
                    ),
                  );
                }, childCount: top.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text('Contribution graph', style: textTheme.titleLarge),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your contribution activity on GitHub',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('View contribution graph on GitHub'),
                        onPressed: () =>
                            launchUrlString('https://github.com/$username'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: _logout,
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
