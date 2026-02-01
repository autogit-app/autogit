import 'package:autogit/features/repos/data/repository_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepoData', () {
    test('holds name url fileCount commitCount', () {
      final r = RepoData(
        name: 'my-repo',
        url: 'https://github.com/u/my-repo',
        fileCount: 10,
        commitCount: 5,
      );
      expect(r.name, 'my-repo');
      expect(r.url, 'https://github.com/u/my-repo');
      expect(r.fileCount, 10);
      expect(r.commitCount, 5);
      expect(r.lastUpdated, isNull);
    });
    test('lastUpdated can be set', () {
      final dt = DateTime(2024, 1, 1);
      final r = RepoData(
        name: 'r',
        url: 'u',
        fileCount: 0,
        commitCount: 0,
        lastUpdated: dt,
      );
      expect(r.lastUpdated, dt);
    });
  });
}
