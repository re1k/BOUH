import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/dto/doctorDto.dart';
import 'package:bouh/dto/doctorSummaryDto.dart';
import 'package:bouh/dto/doctorBarInfoDto.dart';

class DoctorsService {
  static Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  static Map<String, String> _authHeaders() {
    final token = AuthSession.instance.idToken;

    if (token == null || token.isEmpty) {
      throw StateError('No JWT (idToken). User not logged in.');
    }

    return {"Accept": "application/json", "Authorization": "Bearer $token"};
  }

  static Future<List<DoctorSummaryDto>> getDoctorsForCaregiver() async {
    final uri = _url('/api/caregiver/doctors');
    final headers = _authHeaders();

    final res = await http.get(uri, headers: headers);

    if (res.statusCode != 200) {
      throw Exception("Failed: ${res.statusCode} ${res.body}");
    }

    final decoded = jsonDecode(res.body);
    print("RAW doctors response: ${res.body}");

    if (decoded is! List) {
      throw Exception("Unexpected response shape: ${res.body}");
    }

    return decoded
        .map((e) => DoctorSummaryDto.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<DoctorDto> getDoctorDetails(String doctorId) async {
    final uri = _url('/api/caregiver/doctors/$doctorId');
    final headers = _authHeaders();

    print("Calling details API: $uri");

    final res = await http.get(uri, headers: headers);

    print("Details status code: ${res.statusCode}");
    print("RAW doctor details response: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed: ${res.statusCode} ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception("Unexpected response shape: ${res.body}");
    }

    return DoctorDto.fromJson(decoded);
  }

  //Header bar info endpoint (used mainly for average rating refresh).
  //Backend: GET /api/doctors/{doctorId}/barInfo
  static Future<DoctorBarInfoDto> getDoctorBarInfo({
    required String doctorId,
  }) async {
    final res = await http.get(
      _url('/api/doctors/$doctorId/barInfo'),
      headers: _authHeaders(),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        res.body.isNotEmpty ? res.body : 'Failed to load doctor bar info',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response: ${res.body}');
    }

    return DoctorBarInfoDto.fromJson(decoded);
  }

  //Polling stream for bar-info changes (primarily rating in current UI usage).
  //Emits only when payload changes and keeps stream alive on transient failures.
  static Stream<DoctorBarInfoDto> streamDoctorBarInfo({
    required String doctorId,
    Duration interval = const Duration(seconds: 60),
  }) {
    DoctorBarInfoDto? last;

    Future<DoctorBarInfoDto?> fetchIfChanged() async {
      try {
        final current = await getDoctorBarInfo(doctorId: doctorId);
        final changed =
            last == null ||
            last!.name != current.name ||
            last!.averageRating != current.averageRating;
        if (!changed) return null;
        last = current;
        return current;
      } catch (_) {
        // Keep stream alive on transient backend/network failures.
        return null;
      }
    }

    return (() async* {
      final first = await fetchIfChanged();
      if (first != null) yield first;

      await for (final _ in Stream.periodic(interval)) {
        final next = await fetchIfChanged();
        if (next != null) yield next;
      }
    })();
  }
}
