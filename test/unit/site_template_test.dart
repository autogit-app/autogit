import 'package:autogit/core/providers/github_templates_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SiteTemplate', () {
    test('holds required fields', () {
      final t = SiteTemplate(
        id: 'starter-blog',
        name: 'Starter Blog',
        description: 'A blog template',
        templateOwner: 'autogit-app',
        templateRepo: 'templates',
        folderPath: 'starter-blog',
      );
      expect(t.id, 'starter-blog');
      expect(t.name, 'Starter Blog');
      expect(t.description, 'A blog template');
      expect(t.templateOwner, 'autogit-app');
      expect(t.templateRepo, 'templates');
      expect(t.folderPath, 'starter-blog');
    });
    test('description can be null', () {
      final t = SiteTemplate(
        id: 'x',
        name: 'X',
        templateOwner: 'o',
        templateRepo: 'r',
      );
      expect(t.description, isNull);
      expect(t.folderPath, isNull);
    });
    test('folderPath null means full template repo', () {
      final t = SiteTemplate(
        id: 'default',
        name: 'Default',
        templateOwner: 'autogit-app',
        templateRepo: 'templates',
        folderPath: null,
      );
      expect(t.folderPath, isNull);
    });
    test('equality by value', () {
      final a = SiteTemplate(
        id: 'a',
        name: 'A',
        templateOwner: 'o',
        templateRepo: 'r',
        folderPath: 'a',
      );
      final b = SiteTemplate(
        id: 'a',
        name: 'A',
        templateOwner: 'o',
        templateRepo: 'r',
        folderPath: 'a',
      );
      expect(a.id, b.id);
      expect(a.name, b.name);
    });
    test('docs-like template', () {
      final t = SiteTemplate(
        id: 'docs',
        name: 'Docs',
        templateOwner: 'autogit-app',
        templateRepo: 'templates',
        folderPath: 'docs',
      );
      expect(t.id, 'docs');
      expect(t.folderPath, 'docs');
    });
    test('personal-site-like template', () {
      final t = SiteTemplate(
        id: 'personal-site',
        name: 'Personal Site',
        templateOwner: 'autogit-app',
        templateRepo: 'templates',
        folderPath: 'personal-site',
      );
      expect(t.name, 'Personal Site');
    });
  });
}
