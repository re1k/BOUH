import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/rateDto.dart';
import 'package:bouh/authentication/AuthSession.dart';

class RateService {

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

  //POST /api/rate/add
  Future<void> rateDoctor({required RateDto rateDto}) async {

    final res = await http.post(
      _url('/api/rate/add'),
      headers: _authHeaders(json: true),
      body: jsonEncode(rateDto.toJson()),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        res.body.isNotEmpty ? res.body : "Failed to submit rating",
      );
    }
  }
}