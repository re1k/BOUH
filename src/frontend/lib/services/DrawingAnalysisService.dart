import 'dart:convert';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/DrawingAnalysis/HistoryPageDto.dart';
import 'package:bouh/dto/DrawingAnalysis/AnalysisResultDto.dart';
import 'package:http/http.dart' as http;

class DrawingAnalysisService {
  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _authHeaders({bool json = false}) {
    final token = AuthSession.instance.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT. User not logged in.');
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Fetches one page of drawing history for a child.
  // cursor = null  → first page
  // cursor = value → page starting after that drawingId
  // nextCursor = null in response → no more pages, stop
  Future<HistoryPageDto> getHistory({
    required String childId,
    String? cursor,
    int limit = 10,
  }) async {
    final queryParams = {
      'limit': '$limit',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };

    final uri = _url(
      '/api/drawingAnalysis/history/$childId',
    ).replace(queryParameters: queryParams);

    final res = await http.get(uri, headers: _authHeaders());

    if (res.statusCode != 200) {
      throw Exception('Failed to load history: ${res.statusCode} ${res.body}');
    }

    return HistoryPageDto.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  // Sends a drawing for analysis.
  Future<AnalysisResult> analyze({
    required String imagePath,
    required String imageURL,
    required String childId,
  }) async {
    final res = await http.post(
      _url('/api/drawingAnalysis/analyze'),
      headers: _authHeaders(json: true),
      body: jsonEncode({
        'imagePath': imagePath,
        'imageURL': imageURL,
        'childId': childId,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('Analysis failed: ${res.statusCode} ${res.body}');
    }

    return AnalysisResult.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }
}
