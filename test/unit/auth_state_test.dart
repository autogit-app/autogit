import 'package:autogit/features/auth/data/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AuthState.clear();
  });
  tearDown(() {
    AuthState.clear();
  });

  group('AuthState', () {
    test('token is null initially', () {
      expect(AuthState.token, isNull);
    });
    test('username is null initially', () {
      expect(AuthState.username, isNull);
    });
    test('avatarUrl is null initially', () {
      expect(AuthState.avatarUrl, isNull);
    });
    test('isAnonymous is false initially', () {
      expect(AuthState.isAnonymous, isFalse);
    });
    test('hasToken is false when token is null', () {
      expect(AuthState.hasToken, isFalse);
    });
    test('hasToken is false when token is empty', () {
      AuthState.setToken('');
      expect(AuthState.hasToken, isFalse);
    });
    test('hasToken is true when token is set', () {
      AuthState.setToken('gho_abc123');
      expect(AuthState.hasToken, isTrue);
    });
    test('isAuthenticated is false when no token and not anonymous', () {
      expect(AuthState.isAuthenticated, isFalse);
    });
    test('isAuthenticated is true when has token', () {
      AuthState.setToken('gho_xyz');
      expect(AuthState.isAuthenticated, isTrue);
    });
    test('isAuthenticated is true when anonymous', () {
      AuthState.setAnonymous(true);
      expect(AuthState.isAuthenticated, isTrue);
    });
    test('setUser updates username and avatarUrl', () {
      AuthState.setUser(username: 'jane', avatarUrl: 'https://avatar.url');
      expect(AuthState.username, 'jane');
      expect(AuthState.avatarUrl, 'https://avatar.url');
    });
    test('clear resets all state', () {
      AuthState.setToken('token');
      AuthState.setAnonymous(true);
      AuthState.setUser(username: 'u', avatarUrl: 'a');
      AuthState.clear();
      expect(AuthState.token, isNull);
      expect(AuthState.isAnonymous, isFalse);
      expect(AuthState.username, isNull);
      expect(AuthState.avatarUrl, isNull);
      expect(AuthState.hasToken, isFalse);
      expect(AuthState.isAuthenticated, isFalse);
    });
  });
}
