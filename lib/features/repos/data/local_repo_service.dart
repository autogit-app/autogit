/// Result of listing local repositories.
class LocalRepoInfo {
  const LocalRepoInfo({
    required this.name,
    required this.path,
    this.currentBranch,
    this.isClean,
  });

  final String name;
  final String path;
  final String? currentBranch;
  final bool? isClean;
}

/// Service for listing and managing local git repositories.
/// On Linux/Windows uses the [git] package (git binary). On Android uses
/// a Termux-hosted HTTP server; user must run the provided script in Termux.
abstract class LocalRepoService {
  /// Whether this backend is available (e.g. Termux server reachable).
  Future<bool> get isAvailable;

  /// Path to the Repositories folder, if applicable (null on Android).
  Future<String?> get repositoriesPath;

  /// Ensures the Repositories directory exists (desktop only).
  Future<void> ensureRepositoriesDirectory();

  /// List repository names (directory names that are git repos).
  Future<List<LocalRepoInfo>> listRepositories();

  /// Initialize a new git repo with the given name (creates [reposPath]/[name]).
  Future<LocalRepoInfo> initRepository(String name);

  /// Clone a repo into the Repositories folder. Returns [LocalRepoInfo] or throws.
  Future<LocalRepoInfo> cloneRepository(String cloneUrl, {String? name});

  /// Run a git command in a repo. Returns stdout + stderr.
  Future<String> runCommand(String repoName, List<String> args);

  /// List entries in a repo path (files and dirs). Path is relative to repo root, use '' for root.
  /// Returns list of {name, isDir}. Not supported on all backends.
  Future<List<LocalRepoEntry>> listDir(String repoName, String path);

  /// Read file content. Path relative to repo root. Throws if not found or not a file.
  Future<String> readFile(String repoName, String path);

  /// Write file content. Path relative to repo root. Creates or overwrites.
  Future<void> writeFile(String repoName, String path, String content);
}

/// A file or directory entry in a local repo.
class LocalRepoEntry {
  const LocalRepoEntry({required this.name, required this.isDir});
  final String name;
  final bool isDir;
}
