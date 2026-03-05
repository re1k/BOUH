import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/dto/doctorSummaryDto.dart';

class DoctorsService {
  static const String baseUrl = "http://10.0.2.2:8080";

  static Future<List<DoctorSummaryDto>> getDoctorsForCaregiver() async {
    final uri = Uri.parse("$baseUrl/api/caregiver/doctors");

    final res = await http.get(uri, headers: {"Accept": "application/json"});

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
}
