import 'package:flutter_test/flutter_test.dart';

/// Repo name sanitization logic used by create_site and create_code_repo screens.
String sanitizeRepoName(String input) {
  return input.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9\-_]'), '-');
}

void main() {
  group('sanitizeRepoName', () {
    test('lowercases input', () {
      expect(sanitizeRepoName('My-Site'), 'my-site');
    });
    test('trims whitespace', () {
      expect(sanitizeRepoName('  my-site  '), 'my-site');
    });
    test('replaces invalid chars with dash', () {
      expect(sanitizeRepoName('my site'), 'my-site');
    });
    test('allows letters numbers dash underscore', () {
      expect(sanitizeRepoName('my_repo-123'), 'my_repo-123');
    });
    test('strips special chars', () {
      expect(sanitizeRepoName('my@repo!'), 'my-repo-');
    });
    test('empty string stays empty', () {
      expect(sanitizeRepoName(''), '');
    });
    test('multiple spaces become dashes', () {
      expect(sanitizeRepoName('a b c'), 'a-b-c');
    });
  });
}
