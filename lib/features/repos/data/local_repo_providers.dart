import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autogit/features/repos/data/local_git_server_url.dart';
import 'package:autogit/features/repos/data/local_repo_service.dart';
import 'package:autogit/features/repos/data/native_local_repo_service.dart';
import 'package:autogit/features/repos/data/termux_local_repo_service.dart';

/// Saved Local Git Server URL (Android). Used for Termux or remote server.
final localGitServerUrlProvider =
    FutureProvider<String>((ref) => loadLocalGitServerUrl());

/// Provides the appropriate [LocalRepoService]. On Android this is async
/// (loads saved server URL). On desktop returns [NativeLocalRepoService] sync.
final localRepoServiceProvider = FutureProvider<LocalRepoService>((ref) async {
  if (Platform.isAndroid) {
    final url = await ref.watch(localGitServerUrlProvider.future);
    return TermuxLocalRepoService(baseUrl: url);
  }
  return NativeLocalRepoService();
});
