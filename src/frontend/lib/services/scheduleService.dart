import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/authentication/AuthSession.dart';
import '../dto/scheduleDto.dart';

class ScheduleService {
  static Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Map<String, String> _authHeaders() {
    final token = AuthSession.instance.idToken;

    if (token == null || token.isEmpty) {
      throw StateError('No JWT (idToken). User not logged in.');
    }

    return {"Accept": "application/json", "Authorization": "Bearer $token"};
  }

  static Future<ScheduleDto> getDoctorScheduleByDate({
    required String doctorId,
    required String date,
  }) async {
    final url = _url('/api/caregiver/doctors/$doctorId/schedule?date=$date');

    final response = await http.get(url, headers: _authHeaders());

    print("Schedule status code: ${response.statusCode}");
    print("RAW schedule response: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to load schedule: ${response.body}");
    }

    if (response.body.trim().isEmpty) {
      return ScheduleDto(date: date, timeSlots: []);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ScheduleDto.fromJson(data);
  }

  static Future<Map<String, bool>> getDoctorMonthAvailability({
    required String doctorId,
    required int year,
    required int month,
  }) async {
    final url = _url(
      '/api/caregiver/doctors/$doctorId/schedule/month-availability?year=$year&month=$month',
    );

    final response = await http.get(url, headers: _authHeaders());

    print("Month availability status code: ${response.statusCode}");
    print("RAW month availability response: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Failed to load month availability: ${response.body}");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data.map((key, value) => MapEntry(key, value == true));
  }
}
