import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'auth_state.dart';

/// Callback when device flow is used: (userCode, verificationUri).
/// The app should display [userCode] so the user can enter it in the browser.
typedef DeviceCodeCallback = void Function(
    String userCode, String verificationUri);

/// GitHub OAuth client ID and secret.
/// Create a GitHub OAuth App at https://github.com/settings/developers
/// and set redirect URL to: http://localhost:8080/callback
const String _clientId = String.fromEnvironment(
  'GITHUB_CLIENT_ID',
  defaultValue: '',
);
const String _clientSecret = String.fromEnvironment(
  'GITHUB_CLIENT_SECRET',
  defaultValue: '',
);

const _redirectPort = 8080;
const _redirectPath = 'callback';
final _redirectUri = Uri.parse(
  'http://localhost:$_redirectPort/$_redirectPath',
);

const _authorizationEndpoint = 'https://github.com/login/oauth/authorize';
const _tokenEndpoint = 'https://github.com/login/oauth/access_token';
const _deviceCodeEndpoint = 'https://github.com/login/device/code';
const _scope = 'read:user user:email repo';

const _prefsToken = 'github_token';
const _prefsUsername = 'github_username';
const _prefsAvatarUrl = 'github_avatar_url';
const _prefsAnonymous = 'is_anonymous';

class GitHubAuthService {
  GitHubAuthService._();
  static final GitHubAuthService instance = GitHubAuthService._();

  /// Load saved auth state into [AuthState]. Call from main() before runApp.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_prefsToken);
    final username = prefs.getString(_prefsUsername);
    final avatarUrl = prefs.getString(_prefsAvatarUrl);
    final isAnonymous = prefs.getBool(_prefsAnonymous) ?? false;

    AuthState.setToken(token);
    AuthState.setAnonymous(isAnonymous);
    AuthState.setUser(username: username, avatarUrl: avatarUrl);
  }

  /// Start GitHub OAuth flow. Uses device flow (no client secret) when secret
  /// is not set (e.g. open-source builds); otherwise uses web flow.
  /// When using device flow, [onDeviceCodeReady] is called with the code to show in the app.
  /// Returns null on success; returns error message on failure.
  Future<String?> login({DeviceCodeCallback? onDeviceCodeReady}) async {
    if (_clientId.isEmpty) {
      return 'GitHub OAuth is not configured. Set GITHUB_CLIENT_ID (e.g. via '
          '--dart-define). Create an OAuth App at '
          'https://github.com/settings/developers. For device flow (no secret), '
          'enable "Device flow" in the app settings.';
    }

    if (_clientSecret.isNotEmpty) {
      return _loginWebFlow();
    }
    return _loginDeviceFlow(onDeviceCodeReady: onDeviceCodeReady);
  }

  /// Web application flow: browser + local callback server. Requires client secret.
  Future<String?> _loginWebFlow() async {
    final authUrl = Uri.parse(_authorizationEndpoint).replace(
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': _redirectUri.toString(),
        'scope': _scope,
      },
    );

    String? code;
    HttpServer? server;
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _redirectPort,
      );
      final completer = Completer<String?>();

      server.listen((request) async {
        if (request.uri.path != '/$_redirectPath' || request.method != 'GET') {
          request.response
            ..statusCode = 404
            ..write('Not found')
            ..close();
          return;
        }
        code = request.uri.queryParameters['code'];
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(_successHtml)
          ..close();
        if (!completer.isCompleted) completer.complete(code);
      });

      if (!await launchUrlString(authUrl.toString())) {
        await server.close();
        return 'Could not open browser. Please open this URL manually:\n$authUrl';
      }

      code = await completer.future;
      await server.close();
    } catch (e) {
      await server?.close(force: true);
      return 'Failed to start callback server: $e';
    }

    if (code == null || code!.isEmpty) {
      return 'No authorization code received. You may have cancelled the login.';
    }

    final token = await _exchangeCodeForToken(code!);
    if (token == null || token.isEmpty) {
      return 'Failed to get access token from GitHub.';
    }
    return _saveUserAndComplete(token);
  }

  /// Device flow: no client secret. User enters code at github.com/login/device.
  /// Use for open-source / published builds where secret cannot be embedded.
  Future<String?> _loginDeviceFlow(
      {DeviceCodeCallback? onDeviceCodeReady}) async {
    final device = await _requestDeviceCode();
    if (device == null) {
      return 'Failed to start device flow. Ensure "Device flow" is enabled for '
          'your OAuth app at https://github.com/settings/developers.';
    }

    final verificationUri = device['verification_uri'] as String? ??
        'https://github.com/login/device';
    final userCode = device['user_code'] as String? ?? '';
    final interval = (device['interval'] as num?)?.toInt() ?? 5;
    final expiresIn = (device['expires_in'] as num?)?.toInt() ?? 900;
    final deviceCode = device['device_code'] as String? ?? '';

    // Show the code in the app so the user can enter it in the browser.
    onDeviceCodeReady?.call(userCode, verificationUri);

    if (!await launchUrlString('$verificationUri?user_code=$userCode')) {
      return 'Open $verificationUri and enter code: $userCode';
    }

    final token = await _pollDeviceToken(
      deviceCode: deviceCode,
      intervalSeconds: interval,
      expiresInSeconds: expiresIn,
    );
    if (token == null || token.isEmpty) {
      return 'Authorization expired or was cancelled. Try again.';
    }
    return _saveUserAndComplete(token);
  }

  static Future<Map<String, dynamic>?> _requestDeviceCode() async {
    final response = await http.post(
      Uri.parse(_deviceCodeEndpoint),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'client_id': _clientId, 'scope': _scope},
    );
    if (response.statusCode != 200) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>?;
    if (json != null && json.containsKey('error')) return null;
    return json;
  }

  static Future<String?> _pollDeviceToken({
    required String deviceCode,
    required int intervalSeconds,
    required int expiresInSeconds,
  }) async {
    final stopAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    var interval = intervalSeconds;

    while (DateTime.now().isBefore(stopAt)) {
      await Future<void>.delayed(Duration(seconds: interval));

      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'client_id': _clientId,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200) {
        final token = json?['access_token'] as String?;
        if (token != null && token.isNotEmpty) return token;
        final error = json?['error'] as String?;
        if (error == 'authorization_pending') continue;
        if (error == 'slow_down') {
          interval = (json?['interval'] as num?)?.toInt() ?? interval + 5;
          continue;
        }
        if (error == 'expired_token' || error == 'access_denied') return null;
      }
      return null;
    }
    return null;
  }

  Future<String?> _saveUserAndComplete(String token) async {
    try {
      final user = await _fetchCurrentUser(token);
      if (user == null) {
        return 'Failed to fetch user from GitHub.';
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsToken, token);
      await prefs.setString(_prefsUsername, user['login'] as String);
      await prefs.setString(
        _prefsAvatarUrl,
        user['avatar_url'] as String? ?? '',
      );
      await prefs.setBool(_prefsAnonymous, false);

      AuthState.setToken(token);
      AuthState.setAnonymous(false);
      AuthState.setUser(
        username: user['login'] as String,
        avatarUrl: user['avatar_url'] as String?,
      );
      return null;
    } catch (e) {
      return 'Authorization failed: $e';
    }
  }

  /// Mark user as anonymous (proceed without sign in). No token stored.
  Future<void> proceedWithoutSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsAnonymous, true);
    AuthState.setAnonymous(true);
    AuthState.setToken(null);
    AuthState.setUser(username: null, avatarUrl: null);
  }

  /// Clear token and user; redirect to auth is handled by caller.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsToken);
    await prefs.remove(_prefsUsername);
    await prefs.remove(_prefsAvatarUrl);
    await prefs.setBool(_prefsAnonymous, false);
    AuthState.clear();
  }

  /// Exchange authorization code for access token. GitHub returns form-urlencoded
  /// by default; we request JSON via Accept header.
  static Future<String?> _exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'redirect_uri': _redirectUri.toString(),
      },
    );
    if (response.statusCode != 200) {
      return null;
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>?;
    return json?['access_token'] as String?;
  }

  static Future<Map<String, dynamic>?> _fetchCurrentUser(String token) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.https('api.github.com', 'user'));
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      request.headers.set('User-Agent', 'AutoGit');
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>?;
      return json;
    } finally {
      client.close();
    }
  }
}

const String _successHtml = '''
<!DOCTYPE html>
<html>
<head><title>AutoGit - Login successful</title></head>
<body>
  <p style="font-family: sans-serif; margin: 2rem;">You are signed in. You can close this window and return to the app.</p>
</body>
</html>
''';
