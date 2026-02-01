/// Synchronous auth state for router and initial location.
/// Updated when token is saved/cleared and on app init.
class AuthState {
  AuthState._();

  static String? _token;
  static bool _isAnonymous = false;
  static String? _username;
  static String? _avatarUrl;

  static String? get token => _token;
  static bool get isAnonymous => _isAnonymous;
  static String? get username => _username;
  static String? get avatarUrl => _avatarUrl;

  /// True if user has a GitHub token (signed in with GitHub).
  static bool get hasToken => _token != null && _token!.isNotEmpty;

  /// True if user can use the app (signed in with GitHub or proceeded without).
  static bool get isAuthenticated => hasToken || _isAnonymous;

  static void setToken(String? token) {
    _token = token;
  }

  static void setAnonymous(bool value) {
    _isAnonymous = value;
  }

  static void setUser({String? username, String? avatarUrl}) {
    _username = username;
    _avatarUrl = avatarUrl;
  }

  static void clear() {
    _token = null;
    _isAnonymous = false;
    _username = null;
    _avatarUrl = null;
  }
}
