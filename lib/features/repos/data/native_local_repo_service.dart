import 'dart:io';

import 'package:git/git.dart';
import 'package:path/path.dart' as p;

import 'package:autogit/core/utils/repositories_path.dart';
import 'package:autogit/features/repos/data/local_repo_service.dart';

/// Uses the system git binary via the [git] package. For Linux and Windows.
class NativeLocalRepoService implements LocalRepoService {
  @override
  Future<bool> get isAvailable async {
    final path = await repositoriesPath;
    return path != null;
  }

  @override
  Future<String?> get repositoriesPath => getRepositoriesPath();

  @override
  Future<void> ensureRepositoriesDirectory() async {
    final path = await repositoriesPath;
    if (path == null) return;
    final dir = Directory(path);
    if (!await dir.exists()) await dir.create(recursive: true);
  }

  @override
  Future<List<LocalRepoInfo>> listRepositories() async {
    final basePath = await repositoriesPath;
    if (basePath == null) return [];

    final dir = Directory(basePath);
    if (!await dir.exists()) return [];

    final list = <LocalRepoInfo>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      final isGit = await GitDir.isGitDir(entity.path);
      if (!isGit) continue;

      String? currentBranch;
      bool? isClean;
      try {
        final gitDir = await GitDir.fromExisting(entity.path);
        final branch = await gitDir.currentBranch();
        currentBranch = branch.branchName;
        isClean = await gitDir.isWorkingTreeClean();
      } catch (_) {
        // ignore
      }

      list.add(LocalRepoInfo(
        name: name,
        path: entity.path,
        currentBranch: currentBranch,
        isClean: isClean,
      ));
    }

    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Future<LocalRepoInfo> initRepository(String name) async {
    final basePath = await repositoriesPath;
    if (basePath == null) {
      throw StateError('Repositories path not available');
    }

    await ensureRepositoriesDirectory();
    final repoPath = p.join(basePath, name);
    final dir = Directory(repoPath);
    if (await dir.exists()) {
      throw StateError('A directory named "$name" already exists');
    }

    // The git package expects the directory to exist (and be empty) before init.
    await dir.create(recursive: true);
    await GitDir.init(repoPath);
    return LocalRepoInfo(name: name, path: repoPath);
  }

  @override
  Future<LocalRepoInfo> cloneRepository(String cloneUrl, {String? name}) async {
    final basePath = await repositoriesPath;
    if (basePath == null) {
      throw StateError('Repositories path not available');
    }

    await ensureRepositoriesDirectory();
    final targetName = name ?? _nameFromCloneUrl(cloneUrl);
    final repoPath = p.join(basePath, targetName);
    final dir = Directory(repoPath);
    if (await dir.exists()) {
      throw StateError('A directory named "$targetName" already exists');
    }

    final result = await Process.run(
      'git',
      ['clone', cloneUrl, repoPath],
      runInShell: false,
    );
    if (result.exitCode != 0) {
      throw Exception(
        (result.stderr as String).trim().isNotEmpty
            ? result.stderr as String
            : result.stdout as String,
      );
    }

    return LocalRepoInfo(name: targetName, path: repoPath);
  }

  static String _nameFromCloneUrl(String url) {
    String name = url;
    if (name.endsWith('.git')) name = name.substring(0, name.length - 4);
    final last = name.split(RegExp(r'[/\\]')).last;
    return last.isNotEmpty ? last : 'repo';
  }

  @override
  Future<String> runCommand(String repoName, List<String> args) async {
    final basePath = await repositoriesPath;
    if (basePath == null) {
      throw StateError('Repositories path not available');
    }

    final repoPath = p.join(basePath, repoName);
    final dir = Directory(repoPath);
    if (!await dir.exists()) {
      throw StateError('Repository does not exist: $repoName');
    }
    if (!await GitDir.isGitDir(repoPath)) {
      throw StateError('Not a git repository: $repoName');
    }
    final gitDir = await GitDir.fromExisting(repoPath);
    final result = await gitDir.runCommand(args);
    final out = result.stdout as String? ?? '';
    final err = result.stderr as String? ?? '';
    if (out.isNotEmpty && err.isNotEmpty) return '$out\n$err';
    return out.isEmpty ? err : out;
  }

  @override
  Future<List<LocalRepoEntry>> listDir(String repoName, String path) async {
    final basePath = await repositoriesPath;
    if (basePath == null) throw StateError('Repositories path not available');
    final dir = Directory(p.join(basePath, repoName, path));
    if (!await dir.exists()) return [];
    final list = <LocalRepoEntry>[];
    await for (final entity in dir.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      list.add(LocalRepoEntry(name: name, isDir: entity is Directory));
    }
    list.sort((a, b) {
      if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  @override
  Future<String> readFile(String repoName, String path) async {
    final basePath = await repositoriesPath;
    if (basePath == null) throw StateError('Repositories path not available');
    final file = File(p.join(basePath, repoName, path));
    if (!await file.exists()) throw StateError('File not found: $path');
    return file.readAsString();
  }

  @override
  Future<void> writeFile(String repoName, String path, String content) async {
    final basePath = await repositoriesPath;
    if (basePath == null) throw StateError('Repositories path not available');
    final file = File(p.join(basePath, repoName, path));
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }
}
