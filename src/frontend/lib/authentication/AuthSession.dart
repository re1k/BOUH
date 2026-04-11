import 'package:shared_preferences/shared_preferences.dart';

//Auth state: userId and role set from backend login response. Persisted for startup.
class AuthSession {
  AuthSession._();
  static final AuthSession _instance = AuthSession._();
  static AuthSession get instance => _instance;

  static const String _roleKeyPrefix = 'userRole_';
  static const String _userNameKeyPrefix = 'userName_';
  static const String _lastUserIdKey = 'lastUserId';
  static const String _legacyRoleKey = 'userRole';

  String? _idToken;
  String? _userId;
  String? _role;
  String? _userName;

  String? get idToken => _idToken;
  String? get userId => _userId;
  String? get userName => _userName;

  //Role from backend login. Loads from memory or prefs (lastUserId + userRole_uid). Also loads userName.
  Future<String?> get role async {
    if (_userId != null && _role != null) return _role;
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(_lastUserIdKey);
    if (lastUid == null) {
      _userId = null;
      _role = null;
      _userName = null;
      return null;
    }
    _userId = lastUid;
    _role = prefs.getString(_roleKeyPrefix + lastUid);
    _userName = prefs.getString(_userNameKeyPrefix + lastUid);
    return _role;
  }

  bool get isLoggedIn => _userId != null;
  String? get authorizationHeader =>
      _idToken != null ? 'Bearer $_idToken' : null;

  //Firebase signup flow: JWT + uid. Used when creating/verifying account.
  void setSession({required String idToken, required String userId}) {
    _idToken = idToken;
    _userId = userId;
  }

  //Backend login: set session from response { uid, role, name }. Only place role/name are set. Keeps existing idToken if set
  Future<void> setSessionFromBackend({
    required String uid,
    required String role,
    String? name,
  }) async {
    if (role != 'doctor' && role != 'caregiver' && role != 'pending') return;
    _userId = uid;
    _role = role;
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, uid);
    await prefs.setString(_roleKeyPrefix + uid, role);
    if (name != null && name.isNotEmpty) {
      await prefs.setString(_userNameKeyPrefix + uid, name);
    } else {
      await prefs.remove(_userNameKeyPrefix + uid);
    }
    await prefs.remove(_legacyRoleKey);
  }

  //Updates display name after profile edit
  Future<void> updateCachedUserName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    _userName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKeyPrefix + uid, trimmed);
  }

  //Clears in-memory and all persisted session so next login is set fresh from backend.
  Future<void> clearSession([String? uid]) async {
    _idToken = null;
    _userId = null;
    _role = null;
    _userName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);
    await prefs.remove(_legacyRoleKey);
    if (uid != null) {
      await prefs.remove(_roleKeyPrefix + uid);
      await prefs.remove(_userNameKeyPrefix + uid);
    }
  }
}
