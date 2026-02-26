import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bouh/dto/payment/RefundResponseDto.dart';
import 'package:bouh/config/api_config.dart';

class RefundService {
  Future<RefundResponseDto> refund({
    required String paymentIntentId,
    int? amount, // optional
  }) async {
    final url = Uri.parse("${ApiConfig.baseUrl}/api/payment/refund");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
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
