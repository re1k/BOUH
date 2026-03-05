import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/scheduleDto.dart';

class ScheduleService {
  static const String baseUrl = "http://10.0.2.2:8080";

  static Future<ScheduleDto> getDoctorScheduleByDate({
    required String doctorId,
    required String date, // "YYYY-MM-DD"
  }) async {
    final url = Uri.parse("$baseUrl/api/doctors/$doctorId/schedule?date=$date");

    final response = await http.get(
      url,
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load schedule: ${response.body}");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return ScheduleDto.fromJson(data);
  }
}
