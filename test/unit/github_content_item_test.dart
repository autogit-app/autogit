import 'package:autogit/features/repos/data/github_contents_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GitHubContentItem', () {
    test('holds name path type', () {
      final item = GitHubContentItem(
        name: 'README.md',
        path: 'README.md',
        type: 'file',
      );
      expect(item.name, 'README.md');
      expect(item.path, 'README.md');
      expect(item.type, 'file');
    });

    test('type can be dir', () {
      final item = GitHubContentItem(name: 'src', path: 'src', type: 'dir');
      expect(item.type, 'dir');
    });

    test('path can be nested', () {
      final item = GitHubContentItem(
        name: 'index.html',
        path: 'starter-astro-blog/index.html',
        type: 'file',
      );
      expect(item.path, 'starter-astro-blog/index.html');
    });

    test('empty name allowed', () {
      final item = GitHubContentItem(name: '', path: '', type: 'file');
      expect(item.name, '');
    });

    test('multiple items differ by path', () {
      final a = GitHubContentItem(name: 'a', path: 'a', type: 'file');
      final b = GitHubContentItem(name: 'b', path: 'b', type: 'file');
      expect(a.path, isNot(b.path));
    });
  });

  group('GitHubFileContent', () {
    test('holds sha content path', () {
      final f = GitHubFileContent(
        sha: 'abc123',
        content: 'Hello world',
        path: 'readme.md',
      );
      expect(f.sha, 'abc123');
      expect(f.content, 'Hello world');
      expect(f.path, 'readme.md');
    });

    test('content can be empty', () {
      final f = GitHubFileContent(sha: 'x', content: '', path: 'empty.txt');
      expect(f.content, '');
    });
  });
}
