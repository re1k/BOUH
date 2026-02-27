import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';

/// Service that calls backend appointment endpoints.
/// Caller: BookedAppointmentsUpcoming page. Builds URL from ApiConfig.baseUrl + path.
class AppointmentsService {
  /// GET /api/appointments/upcoming/{caregiverId}. On 2xx parses JSON list to [UpcomingAppointmentDto].
  /// On non-2xx throws [Exception] with status code and body.
  Future<List<UpcomingAppointmentDto>> getUpcomingAppointments(
    String caregiverId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/upcoming/$caregiverId',
    );
    final res = await http.get(url);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UpcomingAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/appointments/previous/{caregiverId}. Same DTO as upcoming; parses to [UpcomingAppointmentDto].
  Future<List<UpcomingAppointmentDto>> getPreviousAppointments(
    String caregiverId,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/previous/$caregiverId',
    );
    final res = await http.get(url);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }

    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => UpcomingAppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelAppointment({required String appointmentId}) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/appointments/$appointmentId',
    );
    final res = await http.delete(url);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Backend error ${res.statusCode}: ${res.body}');
    }
  }
}
