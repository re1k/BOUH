import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:bouh_admin/model/DoctorModel.dart';
import 'package:bouh_admin/model/DoctorStatsModel.dart';
import '../services/auth_service.dart';

class DoctorService {
  DoctorService._();
  static final DoctorService instance = DoctorService._();

  Future<List<DoctorModel>> getPendingDoctors(BuildContext context) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return [];
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/pending');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DoctorModel.fromJson(json)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
      return [];
    } else {
      throw Exception('فشل تحميل البيانات');
    }
  }

  Future<List<DoctorModel>> getApprovedDoctors(BuildContext context) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return [];
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/approved');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DoctorModel.fromJson(json)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
      return [];
    } else {
      throw Exception('فشل تحميل البيانات');
    }
  }

  Future<DoctorStatsModel?> getStats(BuildContext context) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return null;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/stats');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return DoctorStatsModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
      return null;
    } else {
      throw Exception('فشل تحميل الإحصائيات');
    }
  }

  Future<void> acceptDoctor(BuildContext context, String uid) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/$uid/accept');

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
    } else if (response.statusCode != 200) {
      throw Exception('فشل قبول الطلب');
    }
  }

  Future<void> rejectDoctor(BuildContext context, String uid) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/$uid/reject');

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
    } else if (response.statusCode != 200) {
      throw Exception('فشل رفض الطلب');
    }
  }

  Future<void> deleteDoctor(BuildContext context, String uid) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return;
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/doctors/delete/$uid');

    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
      return;
    } else if (response.statusCode != 200) {
      throw Exception('فشل حذف الحساب، يرجى المحاولة مجددًا');
    }

    final body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'فشل حذف الحساب');
    }
  }
}
