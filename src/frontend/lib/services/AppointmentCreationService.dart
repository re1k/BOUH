import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/appointmentCreationDto.dart';

class AppointmentCreationService {
  Future<String> createAppointment(AppointmentDto request) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/appointments");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Backend error ${response.statusCode}: ${response.body}");
    }

    return response.body;
  }
}
