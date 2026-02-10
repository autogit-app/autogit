import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:autogit/core/providers/github_user_issue_pr_api.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/settings/data/git_identity_persistence.dart';
import 'package:autogit/features/settings/logic/git_identity_providers.dart';

class GitIdentityScreen extends ConsumerStatefulWidget {
  const GitIdentityScreen({super.key});

  @override
  ConsumerState<GitIdentityScreen> createState() => _GitIdentityScreenState();
}

class _GitIdentityScreenState extends ConsumerState<GitIdentityScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _saving = false;
  String? _message;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  Future<void> _load() async {
    if (_loaded) return;
    final hasToken = ref.read(isSignedInWithGitHubProvider);
    String name = await loadGitUserName();
    String email = await loadGitUserEmail();
    if (hasToken && (name.isEmpty || email.isEmpty)) {
      final username = ref.read(githubUsernameProvider);
      final token = ref.read(githubTokenProvider);
      if (username != null && name.isEmpty) name = username;
      if (token != null && token.isNotEmpty && email.isEmpty) {
        try {
          final user = await getCurrentUser(token);
          final e = user['email'] as String?;
          if (e != null && e.isNotEmpty) email = e;
        } catch (_) {}
      }
    }
    if (mounted) {
      _nameController.text = name;
      _emailController.text = email;
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      setState(() => _message = 'Name and email are required for Git commits.');
      return;
    }
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await saveGitUserName(name);
      await saveGitUserEmail(email);
      ref.read(gitIdentityInvalidatorProvider)();
      if (mounted) {
        setState(() {
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Git identity saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _message = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasToken = ref.watch(isSignedInWithGitHubProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(
            title: 'Git identity',
            onBack: () => context.pop(),
          ),
          SliverToBoxAdapter(
            child: FutureBuilder<void>(
              future: _load(),
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'This name and email are used as the author for Git commits in local repositories. '
                      'If you sign in with GitHub, your GitHub username and email can be used; you can change them here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasToken)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Signed in with GitHub — values below can be overridden.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'Your Name',
                        helperText: 'git config user.name',
                      ),
                      textCapitalization: TextCapitalization.words,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                        helperText: 'git config user.email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enabled: !_saving,
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(FontAwesomeIcons.gitAlt, size: 18),
                      label: Text(_saving ? 'Saving...' : 'Save'),
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
}
