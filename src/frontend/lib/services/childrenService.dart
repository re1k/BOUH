import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/authentication/AuthSession.dart';
import '../dto/childDto.dart';

class ChildrenService {
  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _authHeaders({bool json = false}) {
    final token = AuthSession.instance.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT (idToken). User not logged in.');
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<ChildDto>> getChildren(String caregiverId) async {
    final res = await http.get(
      _url('/api/caregiver/$caregiverId/children'),
      headers: _authHeaders(),
    );
    print('GET children raw: ${res.body}');
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
      _url('/api/caregiver/$caregiverId/children'),
      headers: _authHeaders(json: true),
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
      _url('/api/caregiver/$caregiverId/children/$childId'),
      headers: _authHeaders(),
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
      _url('/api/caregiver/$caregiverId/children/$childId'),
      headers: _authHeaders(json: true),
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

  // Returns only {id, name} pairs — exactly what the dropdowns need.
  // Reuses getChildren() internally so no extra API call is made.
  Future<List<({String id, String name})>> getChildrenNames(
    String caregiverId,
  ) async {
    final children = await getChildren(caregiverId);
    return children.map((c) => (id: c.childId, name: c.name)).toList();
  }
}
