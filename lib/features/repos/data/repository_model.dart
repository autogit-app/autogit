class RepoData {
  final String name;
  final String url;
  final int fileCount;
  final int commitCount;
  final DateTime? lastUpdated;

  RepoData({
    required this.name,
    required this.url,
    required this.fileCount,
    required this.commitCount,
    this.lastUpdated,
  });
}