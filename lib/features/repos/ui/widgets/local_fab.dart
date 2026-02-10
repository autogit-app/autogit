import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autogit/features/repos/ui/local/local_repos_screen.dart';

/// FAB on the Local Repositories screen. Opens the "Create repository" dialog
/// instead of redirecting to auth.
class LocalReposFab extends ConsumerWidget {
  const LocalReposFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => LocalReposScreen.showCreateRepoDialog(context, ref),
      child: const Icon(Icons.add),
    );
  }
}
