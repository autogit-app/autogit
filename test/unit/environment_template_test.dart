import 'package:autogit/core/providers/github_environments_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvironmentTemplate', () {
    test('holds required fields', () {
      final t = EnvironmentTemplate(
        id: 'node-app',
        name: 'Node App',
        description: 'Node.js app',
        templateOwner: 'autogit-app',
        templateRepo: 'environments',
        folderPath: 'node-app',
      );
      expect(t.id, 'node-app');
      expect(t.name, 'Node App');
      expect(t.templateOwner, 'autogit-app');
      expect(t.templateRepo, 'environments');
      expect(t.folderPath, 'node-app');
    });
    test('description can be null', () {
      final t = EnvironmentTemplate(
        id: 'x',
        name: 'X',
        templateOwner: 'o',
        templateRepo: 'r',
      );
      expect(t.description, isNull);
      expect(t.folderPath, isNull);
    });
    test('flutter-app template', () {
      final t = EnvironmentTemplate(
        id: 'flutter-app',
        name: 'Flutter App',
        templateOwner: 'autogit-app',
        templateRepo: 'environments',
        folderPath: 'flutter-app',
      );
      expect(t.id, 'flutter-app');
    });
    test('next-app template', () {
      final t = EnvironmentTemplate(
        id: 'next-app',
        name: 'Next App',
        templateOwner: 'autogit-app',
        templateRepo: 'environments',
        folderPath: 'next-app',
      );
      expect(t.name, 'Next App');
    });
    test('mern-stack-app template', () {
      final t = EnvironmentTemplate(
        id: 'mern-stack-app',
        name: 'Mern Stack App',
        templateOwner: 'autogit-app',
        templateRepo: 'environments',
        folderPath: 'mern-stack-app',
      );
      expect(t.folderPath, 'mern-stack-app');
    });
    test('python-web-app template', () {
      final t = EnvironmentTemplate(
        id: 'python-web-app',
        name: 'Python Web App',
        templateOwner: 'autogit-app',
        templateRepo: 'environments',
        folderPath: 'python-web-app',
      );
      expect(t.templateRepo, 'environments');
    });
  });
}
