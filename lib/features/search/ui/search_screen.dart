import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_octicons/flutter_octicons.dart';
import 'package:go_router/go_router.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/search/data/github_search_service.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _queryController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0; // 0 = Repositories, 1 = Users
  String _query = '';
  bool _loading = false;
  String? _error;
  GitHubSearchReposResult? _reposResult;
  GitHubSearchUsersResult? _usersResult;

  @override
  void dispose() {
    _queryController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryController.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _query = q;
      _loading = true;
      _error = null;
      _reposResult = null;
      _usersResult = null;
    });
    final token = ref.read(githubTokenProvider);
    try {
      if (_selectedIndex == 0) {
        final result = await GitHubSearchService.instance.searchRepositories(
          q,
          token: token,
        );
        if (mounted)
          setState(() {
            _reposResult = result;
          });
      } else {
        final result = await GitHubSearchService.instance.searchUsers(
          q,
          token: token,
        );
        if (mounted)
          setState(() {
            _usersResult = result;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
        });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'Search GitHub'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _queryController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search repositories or users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _loading ? null : _search,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        icon: Icon(Icons.folder),
                        label: Text('Repositories'),
                      ),
                      ButtonSegment(
                        value: 1,
                        icon: Icon(Icons.person),
                        label: Text('Users'),
                      ),
                    ],
                    selected: {_selectedIndex},
                    onSelectionChanged: (Set<int> selected) {
                      setState(() {
                        _selectedIndex = selected.first;
                        _error = null;
                        if (_query.isNotEmpty) _search();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            )
          else if (_query.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'Enter a search term and tap search',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else if (_selectedIndex == 0 && _reposResult != null)
            _buildReposList(context, _reposResult!)
          else if (_selectedIndex == 1 && _usersResult != null)
            _buildUsersList(context, _usersResult!),
        ],
      ),
    );
  }

  Widget _buildReposList(BuildContext context, GitHubSearchReposResult result) {
    final theme = Theme.of(context);
    if (result.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No repositories found for "$_query"')),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final repo = result.items[index];
        return ListTile(
          leading: const Icon(OctIcons.repo_16),
          title: Text(repo.fullName),
          subtitle: repo.description != null
              ? Text(
                  repo.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (repo.language != null)
                Chip(
                  label: Text(
                    repo.language!,
                    style: theme.textTheme.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 4),
              Text(
                '${repo.stargazersCount} ★',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          onTap: () {
            final owner = repo.ownerLogin.isNotEmpty
                ? Uri.encodeComponent(repo.ownerLogin)
                : 'unknown';
            final repoName = Uri.encodeComponent(repo.name);
            context.push('/home/github/$owner/$repoName');
          },
        );
      }, childCount: result.items.length),
    );
  }

  Widget _buildUsersList(BuildContext context, GitHubSearchUsersResult result) {
    if (result.items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No users found for "$_query"')),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final user = result.items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.login.isNotEmpty ? user.login[0].toUpperCase() : '?',
                  )
                : null,
          ),
          title: Text(user.login),
          subtitle: user.bio != null
              ? Text(user.bio!, maxLines: 2, overflow: TextOverflow.ellipsis)
              : null,
          onTap: () => context.push('/user/${Uri.encodeComponent(user.login)}'),
        );
      }, childCount: result.items.length),
    );
  }
}
