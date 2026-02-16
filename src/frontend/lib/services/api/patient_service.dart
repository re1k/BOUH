import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../dto/patient_dto.dart';

class PatientService {
  final http.Client _client;
  PatientService({http.Client? client}) : _client = client ?? http.Client();

  static const String _basePath = "/api/v1/patients";

  Future<List<PatientDto>> getAllPatients() async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$_basePath");
    final res = await _client.get(uri, headers: {"Accept": "application/json"});

    if (res.statusCode != 200) {
      throw Exception("GET patients failed: ${res.statusCode} ${res.body}");
    }

    final decoded = jsonDecode(res.body);

    // If backend returns List:
    // return (decoded as List).map((e) => PatientDto.fromJson(e)).toList();

    // If backend returns { data: [ ... ] } change here accordingly:
    if (decoded is List) {
      return decoded.map((e) => PatientDto.fromJson(e)).toList();
    } else if (decoded is Map && decoded["data"] is List) {
      return (decoded["data"] as List)
          .map((e) => PatientDto.fromJson(e))
          .toList();
    } else {
      throw Exception("Unexpected response shape: ${res.body}");
    }
  }

  Future<PatientDto> createPatient(PatientDto patient) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$_basePath");
    final res = await _client.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(patient.toJson()),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("POST patient failed: ${res.statusCode} ${res.body}");
    }

    return PatientDto.fromJson(jsonDecode(res.body));
  }
}
