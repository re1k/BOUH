import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bouh/dto/payment/RefundResponseDto.dart';
import 'package:bouh/config/api_config.dart';
import 'package:bouh/authentication/AuthSession.dart';

class RefundService {
  final AuthSession _session = AuthSession.instance;
  Future<RefundResponseDto> refund({
    required String paymentIntentId,
    int? amount, // optional
  }) async {
    final token = _session.idToken;
    final url = Uri.parse("${ApiConfig.baseUrl}/api/payment/refund");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "paymentIntentId": paymentIntentId,
        if (amount != null) "amount": amount,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Refund failed (${res.statusCode}): ${res.body}");
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return RefundResponseDto.fromJson(json);
  }
}
