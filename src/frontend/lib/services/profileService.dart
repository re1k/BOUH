import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/doctorProfileResponseDto.dart';
import 'package:bouh/dto/doctorUpdateDto.dart';

class AccountUpdateResult {
  final bool success;
  final String? code;
  final String? message;

  AccountUpdateResult({
    required this.success,
    this.code,
    this.message,
  });

  factory AccountUpdateResult.fromJson(Map<String, dynamic> json) {
    return AccountUpdateResult(
      success: json['success'] == true,
      code: json['code']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

// GET /api/accounts/profile
// PATCH /api/accounts/doctor/update
class ProfileService {
  static const String _networkErrorMessage =
      'حدث خطأ، تأكد أنك متصل بالشبكة وحاول مرة أخرى';
  static const Duration _requestTimeout = Duration(seconds: 15);

  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _authHeaders({bool json = false}) {
    final token = AuthSession.instance.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT (idToken). User not logged in.');
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // GET /api/accounts/profile
  Future<DoctorProfileResponseDto> fetchDoctorProfile() async {
    http.Response res;
    try {
      res = await http
          .get(
            _url('/api/accounts/profile'),
            headers: _authHeaders(json: true),
          )
          .timeout(_requestTimeout);
    } on SocketException {
      throw Exception(_networkErrorMessage);
    } on TimeoutException {
      throw Exception(_networkErrorMessage);
    } on http.ClientException {
      throw Exception(_networkErrorMessage);
    }

    if (res.statusCode == 401) {
      await AuthService.instance.refreshSession();
      try {
        res = await http
            .get(
              _url('/api/accounts/profile'),
              headers: _authHeaders(json: true),
            )
            .timeout(_requestTimeout);
      } on SocketException {
        throw Exception(_networkErrorMessage);
      } on TimeoutException {
        throw Exception(_networkErrorMessage);
      } on http.ClientException {
        throw Exception(_networkErrorMessage);
      }
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHORIZED');
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        res.body.isNotEmpty ? res.body : 'Failed to load profile',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final keys = map.keys.toSet();
    if (keys.length == 2 &&
        keys.contains('name') &&
        keys.contains('email')) {
      throw Exception('NOT_DOCTOR_PROFILE');
    }

    return DoctorProfileResponseDto.fromJson(map);
  }

  // GET /api/accounts/profile for caregiver view (name, email).
  Future<Map<String, dynamic>> fetchCaregiverProfile() async {
    var res = await http.get(
      _url('/api/accounts/profile'),
      headers: _authHeaders(json: true),
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshSession();
      res = await http.get(
        _url('/api/accounts/profile'),
        headers: _authHeaders(json: true),
      );
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHORIZED');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        res.body.isNotEmpty ? res.body : 'Failed to load caregiver profile',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('INVALID_PROFILE_PAYLOAD');
    }
    return decoded;
  }

  //PATCH /api/accounts/caregiver/update (name only).
  Future<void> updateCaregiverName(String name) async {
    var res = await http.patch(
      _url('/api/accounts/caregiver/update'),
      headers: _authHeaders(json: true),
      body: jsonEncode({'name': name}),
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshSession();
      res = await http.patch(
        _url('/api/accounts/caregiver/update'),
        headers: _authHeaders(json: true),
        body: jsonEncode({'name': name}),
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        res.body.isNotEmpty ? res.body : 'Failed to update caregiver profile',
      );
    }
  }

  // Uploads doctor profile image to Firebase Storage and returns storage path.
  Future<String> uploadDoctorProfilePhotoToStorage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final ref = FirebaseStorage.instance
        .ref()
        .child('doctorProfileImages')
        .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.fullPath;
  }

  // PATCH /api/accounts/doctor/update
  Future<AccountUpdateResult> updateDoctor(DoctorUpdateDto dto) async {
    final body = dto.toJson();
    if (body.isEmpty) {
      throw StateError('No fields to update');
    }

    var res = await http.patch(
      _url('/api/accounts/doctor/update'),
      headers: _authHeaders(json: true),
      body: jsonEncode(body),
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshSession();
      res = await http.patch(
        _url('/api/accounts/doctor/update'),
        headers: _authHeaders(json: true),
        body: jsonEncode(body),
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        res.body.isNotEmpty ? res.body : 'Failed to update profile',
      );
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return AccountUpdateResult.fromJson(map);
  }
}
