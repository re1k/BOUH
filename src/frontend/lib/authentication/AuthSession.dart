import 'package:shared_preferences/shared_preferences.dart';

//Auth state: userId and role set from backend login response. Persisted for startup.
class AuthSession {
  AuthSession._();
  static final AuthSession _instance = AuthSession._();
  static AuthSession get instance => _instance;

  static const String _roleKeyPrefix = 'userRole_';
  static const String _lastUserIdKey = 'lastUserId';
  static const String _legacyRoleKey = 'userRole';

  String? _idToken;
  String? _userId;
  String? _role;

  String? get idToken => _idToken;
  String? get userId => _userId;

  //Role from backend login. Loads from memory or prefs (lastUserId + userRole_uid).
  Future<String?> get role async {
    if (_userId != null && _role != null) return _role;
    final prefs = await SharedPreferences.getInstance();
    final lastUid = prefs.getString(_lastUserIdKey);
    if (lastUid == null) {
      _userId = null;
      _role = null;
      return null;
    }
    _userId = lastUid;
    _role = prefs.getString(_roleKeyPrefix + lastUid);
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

  //Backend login: set session from response { uid, role }. Only place role is set. Keeps existing idToken if set (e.g. after Firebase login).
  // role: 'doctor' | 'caregiver' | 'pending' (pending = doctor with registrationStatus PENDING).
  Future<void> setSessionFromBackend({required String uid, required String role}) async {
    if (role != 'doctor' && role != 'caregiver' && role != 'pending') return;
    _userId = uid;
    _role = role;
    //keep _idToken so API calls can still use Bearer token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, uid);
    await prefs.setString(_roleKeyPrefix + uid, role);
    await prefs.remove(_legacyRoleKey);
  }

  //Clears in-memory and all persisted session so next login is set fresh from backend.
  Future<void> clearSession([String? uid]) async {
    _idToken = null;
    _userId = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUserIdKey);
    await prefs.remove(_legacyRoleKey);
    if (uid != null) {
      await prefs.remove(_roleKeyPrefix + uid);
    }
  }
}
