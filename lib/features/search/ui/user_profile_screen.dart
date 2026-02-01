import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/core/providers/github_user_issue_pr_api.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key, required this.login});

  final String login;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _user;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(githubTokenProvider);
    try {
      final user = await getUser(widget.login, token: token);
      if (mounted)
        setState(() {
          _user = user;
          _loading = false;
          _error = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.login)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.login)),
        body: Center(child: Text('Error: $_error')),
      );
    }
    final u = _user!;
    final avatarUrl = u['avatar_url'] as String?;
    final name = u['name'] as String?;
    final bio = u['bio'] as String?;
    final company = u['company'] as String?;
    final location = u['location'] as String?;
    final blog = u['blog'] as String?;
    final publicRepos = u['public_repos'] as int? ?? 0;
    final followers = u['followers'] as int? ?? 0;
    final following = u['following'] as int? ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(title: name ?? widget.login),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            (widget.login.isNotEmpty
                                ? widget.login[0].toUpperCase()
                                : '?'),
                            style: Theme.of(context).textTheme.headlineMedium,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.login,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      bio,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: OctIcons.repo_16,
                        label: '$publicRepos repos',
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: OctIcons.people_16,
                        label: '$followers followers',
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.person_outline,
                        label: '$following following',
                      ),
                    ],
                  ),
                  if (company != null && company.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          OctIcons.organization_16,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(company),
                      ],
                    ),
                  ],
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(location),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(
                      '/user/${Uri.encodeComponent(widget.login)}/repos',
                    ),
                    icon: const Icon(OctIcons.repo_16),
                    label: const Text('View repositories'),
                  ),
                  if (blog != null && blog.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        final url = blog.startsWith('http')
                            ? blog
                            : 'https://$blog';
                        launchUrlString(url);
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Website'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
