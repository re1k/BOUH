import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../views/login_page.dart';

class AdminAuthService {
  AdminAuthService._();

  static final AdminAuthService instance = AdminAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _idToken;

  User? get currentUser => _auth.currentUser;

  /// Always fetches a fresh token from Firebase (auto-refreshes if expired after 1h).
  Future<String?> getValidToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    _idToken = await user.getIdToken(false);
    return _idToken;
  }

  /// Call this after any API response with status 401 or 403.
  /// Logs out and redirects to login. no need to repeat this logic in every page.
  static Future<void> handleUnauthorized(BuildContext context) async {
    await instance.logout();
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  /// Login: Firebase sign-in -> get JWT -> verify admin via backend.
  Future<void> login({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user == null) throw Exception('لم يتم العثور على المستخدم');

    final token = await user.getIdToken(true);
    if (token == null || token.isEmpty) {
      throw Exception('تعذر الحصول على رمز الدخول');
    }

    _idToken = token;

    // Verify this user is actually an admin
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/me');
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await _auth.signOut();
      _idToken = null;
      throw Exception('UNAUTHORIZED');
    }
  }

  /// Logout
  Future<void> logout() async {
    await _auth.signOut();
    _idToken = null;
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/forgot-password');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );
    } catch (_) {
      // silently ignore
    }
  }
}
