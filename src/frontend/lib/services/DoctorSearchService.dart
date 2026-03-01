import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/DoctorSearchDto.dart';
import 'package:bouh/authentication/AuthSession.dart';

class DoctorSearchService {
  final AuthSession _session = AuthSession.instance;
  Future<List<DoctorSearchDTO>> searchDoctors(String name) async {
    final token = _session.idToken;
    final url = Uri.parse("${ApiConfig.baseUrl}/api/doctors/search?name=$name");

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => DoctorSearchDTO.fromJson(json)).toList();
  }

  Future<List<DoctorSearchDTO>> getTopRatedDoctors() async {
    final token = _session.idToken;
    final url = Uri.parse("${ApiConfig.baseUrl}/api/doctors/top-rated");

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => DoctorSearchDTO.fromJson(json)).toList();
  }
}
