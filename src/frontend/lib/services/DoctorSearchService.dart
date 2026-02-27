import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/DoctorSearchDto.dart';

class DoctorSearchService {
  Future<List<DoctorSearchDTO>> searchDoctors(String name) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/doctors/search?name=$name");

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => DoctorSearchDTO.fromJson(json)).toList();
  }

  Future<List<DoctorSearchDTO>> getTopRatedDoctors() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/doctors/top-rated");

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((json) => DoctorSearchDTO.fromJson(json)).toList();
  }
}
