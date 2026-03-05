import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/childDto.dart';

class ChildrenService {
  static const String baseUrl = "http://10.0.2.2:8080/api";

  Future<List<ChildDto>> getChildren(String caregiverId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/caregiver/$caregiverId/children"),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to load children: ${res.statusCode} ${res.body}");
    }

    final List data = jsonDecode(res.body) as List;
    return data
        .map((e) => ChildDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addChild({
    required String caregiverId,
    required String name,
    required String dateOfBirth, // YYYY-MM-DD
    required String gender,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/caregiver/$caregiverId/children"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "dateOfBirth": dateOfBirth,
        "gender": gender,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(res.body.isNotEmpty ? res.body : "Failed to add child");
    }
  }

  Future<void> deleteChild({
    required String caregiverId,
    required String childId,
  }) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/caregiver/$caregiverId/children/$childId"),
    );

    if (res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty ? res.body : "Failed to delete child",
      );
    }
  }

  Future<void> updateChild({
    required String caregiverId,
    required String childId,
    required String name,
    required String dateOfBirth,
    required String gender,
  }) async {
    final res = await http.put(
      Uri.parse("$baseUrl/caregiver/$caregiverId/children/$childId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "dateOfBirth": dateOfBirth,
        "gender": gender,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty ? res.body : "Failed to update child",
      );
    }
  }
}
