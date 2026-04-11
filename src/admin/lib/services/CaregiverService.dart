import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:bouh_admin/model/CaregiverModel.dart';
import '../services/auth_service.dart';

class CaregiverInfoService {
  CaregiverInfoService._();
  static final CaregiverInfoService instance = CaregiverInfoService._();

  Future<List<CaregiverInfoModel>> getAllCaregivers(
    BuildContext context,
  ) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return [];
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/caregivers');

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => CaregiverInfoModel.fromJson(json)).toList();
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      await AdminAuthService.handleUnauthorized(context);
      return [];
    } else {
      throw Exception('فشل تحميل البيانات');
    }
  }

  Future<void> deleteCaregiver(BuildContext context, String uid) async {
    final token = await AdminAuthService.instance.getValidToken();
    if (token == null) {
      await AdminAuthService.handleUnauthorized(context);
      return;
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/caregivers/delete/$uid',
    );

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
