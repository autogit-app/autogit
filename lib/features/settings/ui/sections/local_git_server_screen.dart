import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/repos/data/local_git_server_url.dart';
import 'package:autogit/features/repos/data/local_repo_providers.dart';
import 'package:autogit/features/repos/data/termux_local_repo_service.dart';

class LocalGitServerScreen extends ConsumerStatefulWidget {
  const LocalGitServerScreen({super.key});

  @override
  ConsumerState<LocalGitServerScreen> createState() =>
      _LocalGitServerScreenState();
}

class _LocalGitServerScreenState extends ConsumerState<LocalGitServerScreen> {
  late TextEditingController _controller;
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    final url = await loadLocalGitServerUrl();
    if (mounted) {
      _controller.text = url;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await saveLocalGitServerUrl(url);
      ref.invalidate(localGitServerUrlProvider);
      ref.invalidate(localRepoServiceProvider);
      if (mounted) {
        setState(() {
          _saving = false;
          _message = 'Saved';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Server URL saved'),
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          LargeAppBar(
            title: 'Local Git Server',
            onBack: () => context.pop(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connect to a Termux Git Server or a remote server running the same API (e.g. scripts/termux_git_server.py).',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: kDefaultTermuxGitServerUrl,
                      helperText:
                          'e.g. http://127.0.0.1:8765 or http://192.168.1.5:8765',
                    ),
                    keyboardType: TextInputType.url,
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
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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
