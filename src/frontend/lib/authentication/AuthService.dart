import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../dto/caregiverDto.dart';
import '../dto/doctorDto.dart';
import 'AuthSession.dart';

/// Auth service:
/// login / logout , reset password , create accounts, register profiles on backend
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthSession _session = AuthSession.instance;

  CaregiverDto? _pendingCaregiverProfile;
  DoctorDto? _pendingDoctorProfile;

  Future<String?> get role => _session.role;


  /// Login using Firebase, then resolve role from backend
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('No user returned');

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('Could not obtain ID token');
    }

    _session.setSession(idToken: token, userId: user.uid);

    final role = await _getRoleFromBackend(token);
    await _session.setSessionFromBackend(uid: user.uid, role: role);

    return role;
  }

  /// Logout
  Future<void> signOut() async {
    final uid = _session.userId;
    await _auth.signOut();
    await _session.clearSession(uid);
  }

  /// Send password reset email
  /// Returns null on success, or localized error message on failure
  Future<String?> sendPasswordResetEmail({
    required String email,
  }) async {
    final normalizedEmail = email.trim();

    try {
      await _auth.sendPasswordResetEmail(email: normalizedEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'صيغة البريد الإلكتروني غير صحيحة.';
        case 'user-not-found':
          return 'لا يوجد حساب مسجل بهذا البريد الإلكتروني.';
        case 'too-many-requests':
          return 'تم تجاوز عدد المحاولات. انتظر دقيقة ثم اضغط إرسال مرة أخرى.';
        default:
          return 'تعذر إرسال رابط استعادة كلمة المرور.';
      }
    } catch (_) {
      return 'لا يوجد اتصال بالإنترنت.';
    }
  }

  // Account creation (FirebaseAuth) doctor, no profile on backend yet.
  Future<User> createDoctorAccount({
    required DoctorDto doctorDto,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: doctorDto.email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user returned',
      );
    }

    _pendingDoctorProfile = doctorDto;
    await _setSessionFromUser(user);
    return user;
  }

  // Account creation (FirebaseAuth) caregiver, no profile on backend yet.
  Future<User> createCaregiverAccount({
    required CaregiverDto caregiverDto,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: caregiverDto.email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user returned',
      );
    }

    _pendingCaregiverProfile = caregiverDto;
    await _setSessionFromUser(user);
    return user;
  }

  // Pending profile registration (Backend) doctor, no profile on backend yet.
  Future<bool> createPendingDoctorProfileIfAny() async {
    final dto = _pendingDoctorProfile;
    if (dto == null) return false;

    await _registerDoctorOnBackend(dto);
    _pendingDoctorProfile = null;
    return true;
  }

  // Pending profile registration (Backend) caregiver, no profile on backend yet.
  Future<bool> createPendingCaregiverProfileIfAny() async {
    final dto = _pendingCaregiverProfile;
    if (dto == null) return false;

    await _registerCaregiverOnBackend(dto);
    _pendingCaregiverProfile = null;
    return true;
  }

  Future<void> refreshSession() async => _refreshSession();


  /// Backend: GET /api/accounts/me
  Future<String> _getRoleFromBackend(String idToken) async {
    final uri =
        Uri.parse('${ApiConfig.physicalDeviceBaseUrl}/api/accounts/me');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('UNAUTHORIZED');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend error: ${response.statusCode} ${response.body}',
      );
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final role = map['role'] as String?;
    final registrationStatus = map['registrationStatus'] as String?;

    if (role == null || (role != 'doctor' && role != 'caregiver')) {
      throw Exception('Invalid role from backend: $role');
    }

    // Doctor with PENDING registration
    if (role == 'doctor' && registrationStatus == 'PENDING') {
      return 'pending';
    }
    return role;
  }


  // Backend: POST /api/accounts/register/doctors to register doctor on backend.
  Future<void> _registerDoctorOnBackend(DoctorDto doctorDto) async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('User not verified');
    }

    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT');
    }

    final uri = Uri.parse(
      '${ApiConfig.physicalDeviceBaseUrl}/api/accounts/register/doctors',
    );

    final body = doctorDto.toJson()..['doctorId'] = user.uid;

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      await _refreshSession();
      return _registerDoctorOnBackend(doctorDto);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Create doctor failed: ${response.statusCode} ${response.body}',
      );
    }
  }


  // Backend: POST /api/accounts/register/caregivers to register caregiver on backend.
  Future<void> _registerCaregiverOnBackend(
    CaregiverDto caregiverDto,
  ) async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('User not verified');
    }

    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT');
    }

    final uri = Uri.parse(
      '${ApiConfig.physicalDeviceBaseUrl}/api/accounts/register/caregivers',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(caregiverDto.toJson()),
    );

    if (response.statusCode == 401) {
      await _refreshSession();
      return _registerCaregiverOnBackend(caregiverDto);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Create caregiver failed: ${response.statusCode} ${response.body}',
      );
    }
  }

 
  // Session helper: set session from user
  Future<void> _setSessionFromUser(User user) async {
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Could not obtain ID token');
    }

    _session.setSession(idToken: token, userId: user.uid);
  }

  // Session helper: refresh session
  Future<void> _refreshSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _setSessionFromUser(user);
  }
}