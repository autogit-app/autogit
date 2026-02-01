import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';
import 'package:github/github.dart';

import 'package:autogit/core/providers/github.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class UserReposScreen extends ConsumerStatefulWidget {
  const UserReposScreen({super.key, required this.login});

  final String login;

  @override
  ConsumerState<UserReposScreen> createState() => _UserReposScreenState();
}

class _UserReposScreenState extends ConsumerState<UserReposScreen> {
  List<Repository>? _repos;
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
      final repos = await getUserRepos(token, widget.login);
      if (mounted) {
        setState(() {
          _repos = repos;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            LargeAppBar(title: '${widget.login}\'s repositories'),
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: CustomScrollView(
          slivers: [
            LargeAppBar(title: '${widget.login}\'s repositories'),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Error: $_error')),
            ),
          ],
        ),
      );
    }
    final repos = _repos!;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(title: '${widget.login}\'s repositories'),
          if (repos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No public repositories')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final repo = repos[index];
                final name = repo.name;
                final description = repo.description;
                return ListTile(
                  leading: const Icon(OctIcons.repo_16),
                  title: Text(name),
                  subtitle: description != null && description.isNotEmpty
                      ? Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => context.push(
                    '/home/github/${Uri.encodeComponent(widget.login)}/${Uri.encodeComponent(name)}',
                  ),
                );
              }, childCount: repos.length),
            ),
        ],
      ),
    );
  }
}
