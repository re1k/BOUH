import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/DoctorSearchDto.dart';
import 'package:bouh/dto/doctorSummaryDto.dart';
import 'package:bouh/authentication/AuthSession.dart';

class DoctorSearchService {
  final AuthSession _session = AuthSession.instance;

  // ── mapper ──────────────────────────────────────────────────────────────────
  DoctorSummaryDto _toSummary(DoctorSearchDTO dto) => DoctorSummaryDto(
    doctorId: dto.id,
    name: dto.name,
    areaOfKnowledge: dto.areaOfKnowledge,
    rating: dto.averageRating,
    profilePhotoURL: dto.profilePhotoURL,
  );

  // ── auth header ─────────────────────────────────────────────────────────────
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Authorization": "Bearer ${_session.idToken}",
  };

  // ── 10.2.31  search by name ─────────────────────────────────────────────────
  Future<List<DoctorSummaryDto>> searchDoctors(String name) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/doctors/search?name=${Uri.encodeComponent(name)}",
    );

    final res = await http.get(url, headers: _headers);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((json) => _toSummary(DoctorSearchDTO.fromJson(json)))
        .toList();
  }

  // ── 10.2.32  filter by area of knowledge ────────────────────────────────────
  Future<List<DoctorSummaryDto>> filterDoctors(String areaOfKnowledge) async {
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/doctors/filter?areaOfKnowledge=${Uri.encodeComponent(areaOfKnowledge)}",
    );

    final res = await http.get(url, headers: _headers);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data
        .map((json) => _toSummary(DoctorSearchDTO.fromJson(json)))
        .toList();
  }

  // ── initial load + pagination ────────────────────────────────────────────────
  Future<(List<DoctorSummaryDto>, bool)> getTopRatedDoctors({
    String? lastDoctorId,
  }) async {
    String url = "${ApiConfig.baseUrl}/api/doctors/top-rated";
    if (lastDoctorId != null) url += "?lastDoctorId=$lastDoctorId";

    print("📡 URL: $url");
    print("📡 Token: ${_session.idToken}");

    print("📡 URL: $url");
    print("📡 Token: ${_session.idToken}");

    final res = await http.get(Uri.parse(url), headers: _headers);

    print("📡 Status: ${res.statusCode}");
    print("📡 Body: ${res.body}");

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final Map<String, dynamic> data = jsonDecode(res.body);
    final List<DoctorSummaryDto> doctors = (data['doctors'] as List)
        .map((json) => _toSummary(DoctorSearchDTO.fromJson(json)))
        .toList();
    final bool hasMore = data['hasMore'] ?? false;

    return (doctors, hasMore);
  }
}
