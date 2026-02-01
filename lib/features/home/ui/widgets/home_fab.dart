import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class HomeFab extends ConsumerWidget {
  const HomeFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasToken = ref.watch(isSignedInWithGitHubProvider);

    return FloatingActionButton(
      onPressed: () => _showOptions(context, ref, hasToken),
      child: const Icon(Icons.add),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref, bool hasToken) {
    if (!hasToken) {
      context.push('/auth');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Create repository'),
              subtitle: const Text('New GitHub repository'),
              onTap: () {
                Navigator.pop(context);
                context.push('/home/github');
              },
            ),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Create site'),
              subtitle: const Text('New site from template (GitHub Pages)'),
              onTap: () {
                Navigator.pop(context);
                context.push('/home/create-site');
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Create code repo'),
              subtitle: const Text('New repo from autogit-app/environments'),
              onTap: () {
                Navigator.pop(context);
                context.push('/home/create-code-repo');
              },
            ),
          ],
        ),
      ),
    );
  }
}
