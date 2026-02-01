import 'package:autogit/core/utils/string_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('humanize', () {
    test('returns empty string for empty input', () {
      expect(humanize(''), '');
    });

    test('capitalizes single word', () {
      expect(humanize('starter'), 'Starter');
    });

    test('converts kebab-case to title', () {
      expect(humanize('starter-astro-blog'), 'Starter Astro Blog');
    });

    test('converts snake_case to title', () {
      expect(humanize('starter_astro_blog'), 'Starter Astro Blog');
    });

    test('converts mixed separators', () {
      expect(humanize('node-app_env'), 'Node App Env');
    });

    test('handles spaces', () {
      expect(humanize('hello world'), 'Hello World');
    });

    test('lowercases rest of word after first letter', () {
      expect(humanize('NODE-APP'), 'Node App');
    });

    test('handles single character', () {
      expect(humanize('a'), 'A');
    });

    test('handles multiple dashes', () {
      expect(humanize('a--b--c'), 'A B C');
    });

    test('handles leading/trailing separators', () {
      expect(humanize('-starter-'), 'Starter');
    });

    test('handles underscore only', () {
      expect(humanize('flutter_app'), 'Flutter App');
    });

    test('handles numbers in name', () {
      expect(humanize('app-v2'), 'App V2');
    });

    test('docs template name', () {
      expect(humanize('docs'), 'Docs');
    });

    test('resume template name', () {
      expect(humanize('resume'), 'Resume');
    });

    test('readme template name', () {
      expect(humanize('readme'), 'Readme');
    });

    test('mern stack app', () {
      expect(humanize('mern-stack-app'), 'Mern Stack App');
    });
  });
}
