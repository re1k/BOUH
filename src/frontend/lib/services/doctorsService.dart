import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/doctorSummaryDto.dart';

class DoctorsService {
  static const String baseUrl = "http://10.0.2.2:8080";

  static Future<List<DoctorSummaryDto>> getDoctorsForCaregiver() async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/caregiver/doctors"),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load doctors");
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => DoctorSummaryDto.fromJson(e)).toList();
  }
}
