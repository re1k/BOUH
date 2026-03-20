import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../dto/caregiverDto.dart';
import '../dto/doctorDto.dart';
import 'AuthSession.dart';

//Auth service: login / logout , reset password , create accounts, register profiles on backend, FCM helpers
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthSession _session = AuthSession.instance;

  CaregiverDto? _pendingCaregiverProfile;
  DoctorDto? _pendingDoctorProfile;
  File? _pendingDoctorProfileImage;

  Future<String?> get role => _session.role;

  //Get the current device FCM token (used when first creating an account).
  Future<String?> getFcmToken() async {
    final messaging = FirebaseMessaging.instance;

    return messaging.getToken();
  }

  //Login using Firebase, then resolve role from backend
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

    final (role, name) = await _getMeFromBackend(token);
    await _session.setSessionFromBackend(uid: user.uid, role: role, name: name);

    // Send the device FCM token to the backend now that we have a valid session.
    final fcmToken = await getFcmToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      try {
        await updateFcmTokenOnBackend(fcmToken);
      } catch (_) {}
    }

    return role;
  }

  //Logout
  Future<void> signOut() async {
    final uid = _session.userId;
    await _auth.signOut();
    await _session.clearSession(uid);
  }

  //Send password reset email
  Future<String?> sendPasswordResetEmail({required String email}) async {
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

  //Account creation (FirebaseAuth) doctor, no profile on backend yet.
  Future<User> createDoctorAccount({
    required DoctorDto doctorDto,
    required String password,
    File? profileImageFile,
  }) async {
    print(
      '[AuthService] createDoctorAccount: profileImageFile=${profileImageFile != null ? profileImageFile.path : "null"}',
    );
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

    //Get the current device FCM token and set it in the doctorDto.
    final fcmToken = await getFcmToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      doctorDto.fcmToken = fcmToken;
    }

    _pendingDoctorProfile = doctorDto;
    _pendingDoctorProfileImage = profileImageFile;
    await _setSessionFromUser(user);
    return user;
  }

  //Account creation (FirebaseAuth) caregiver, no profile on backend yet.
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

    //Get the current device FCM token and set it in the caregiverDto.
    final fcmToken = await getFcmToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      caregiverDto.fcmToken = fcmToken;
    }

    _pendingCaregiverProfile = caregiverDto;
    await _setSessionFromUser(user);
    return user;
  }

  //Pending profile registration (Backend) doctor, no profile on backend yet.
  Future<bool> createPendingDoctorProfileIfAny() async {
    final dto = _pendingDoctorProfile;
    if (dto == null) {
      return false;
    }

    if (_pendingDoctorProfileImage != null) {
      final storagePath = await _uploadDoctorProfileImageToFirebaseStorage(
        _pendingDoctorProfileImage!,
      );
      print(
        '[AuthService] createPendingDoctorProfileIfAny: upload result storagePath=${storagePath.isEmpty ? "(empty)" : storagePath}',
      );
      if (storagePath.isNotEmpty) {
        // Keep existing DTO field name; value is path (not download URL).
        dto.profilePhotoURL = storagePath;
      }
      _pendingDoctorProfileImage = null;
    }

    await _registerDoctorOnBackend(dto);
    _pendingDoctorProfile = null;
    print(
      '[AuthService] createPendingDoctorProfileIfAny: done, doctor registered on backend',
    );
    return true;
  }

  //Pending profile registration (Backend) caregiver, no profile on backend yet.
  Future<bool> createPendingCaregiverProfileIfAny() async {
    final dto = _pendingCaregiverProfile;
    if (dto == null) return false;

    await _registerCaregiverOnBackend(dto);
    _pendingCaregiverProfile = null;
    return true;
  }

  Future<void> refreshSession() async => _refreshSession();

  //Backend: GET /api/accounts/me ,returns role and name
  Future<(String role, String? name)> _getMeFromBackend(String idToken) async {
    print('logging in. . .');
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/accounts/me');

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
      throw Exception('Backend error: ${response.statusCode} ${response.body}');
    }

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final role = map['role'] as String?;
    final registrationStatus = map['registrationStatus'] as String?;
    final name = map['name'] as String?;

    print('role: $role');
    print('name: $name');
    
    if (role == null || (role != 'doctor' && role != 'caregiver')) {
      throw Exception('Invalid role from backend: $role');
    }

    //Doctor with PENDING registration
    final resolvedRole =
        (role == 'doctor' && registrationStatus == 'PENDING') ? 'pending' : role;
    return (resolvedRole, name);
  }

  //Uploads doctor profile image to Firebase Storage and returns object fullPath.
  Future<String> _uploadDoctorProfileImageToFirebaseStorage(File file) async {
    print(
      '[AuthService] _uploadDoctorProfileImageToFirebaseStorage: file=${file.path}',
    );
    final user = _auth.currentUser;
    if (user == null) {
      return '';
    }
    final ref = FirebaseStorage.instance
        .ref()
        .child('doctorProfileImages')
        .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.fullPath;
  }

  //Backend: POST /api/accounts/register/doctors to register doctor on backend.
  Future<void> _registerDoctorOnBackend(DoctorDto doctorDto) async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('User not verified');
    }

    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/accounts/register/doctors');

    final body = doctorDto.toJson()..['doctorId'] = user.uid;
    final storagePath = (doctorDto.profilePhotoURL ?? '').trim();
    if (storagePath.isNotEmpty) {
      // Backend compatibility: keep expected image field name(s), value is path.
      body['imageUrl'] = storagePath;
      body['ImgaeUrl'] = storagePath;
    }

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

  //Backend: POST /api/accounts/register/caregivers to register caregiver on backend.
  Future<void> _registerCaregiverOnBackend(CaregiverDto caregiverDto) async {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      throw StateError('User not verified');
    }

    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/accounts/register/caregivers',
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

  //Backend: PUT /api/accounts/fcmToken to update FCM token on backend.
  Future<void> updateFcmTokenOnBackend(String fcmToken) async {
    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/accounts/fcmToken');

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );

    if (response.statusCode == 401) {
      await _refreshSession();
      return updateFcmTokenOnBackend(fcmToken);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Update FCM token failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  //Backend: DELETE /api/accounts/delete to delete account on backend.
  Future<String?> deleteAccountOnBackend() async {
    print(
      '[AuthService] deleteAccountOnBackend: started for user ${_auth.currentUser?.uid} with token ${_session.idToken}',
    );

    final token = _session.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT');
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not found');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/accounts/delete');
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('response.statusCode: ${response.statusCode}');
    if (response.statusCode == 200) {
      return '';
    } else if (response.statusCode == 409) {
      throw jsonDecode(response.body)['message'];
    } else {
      throw jsonDecode(response.body)['message'];
    }
  }

  //Session helper: set session from user
  Future<void> _setSessionFromUser(User user) async {
    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw StateError('Could not obtain ID token');
    }

    _session.setSession(idToken: token, userId: user.uid);
  }

  //Session helper: refresh session
  Future<void> _refreshSession() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _setSessionFromUser(user);
  }
}
