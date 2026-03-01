import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bouh/config/api_config.dart';
import 'package:bouh/dto/payment/payment_request_dto.dart';
import 'package:bouh/dto/payment/payment_response_dto.dart';
import 'package:bouh/authentication/AuthSession.dart';

class PaymentService {
  final AuthSession _session = AuthSession.instance;
  Future<PaymentResponseDto> createPaymentIntent(
    PaymentRequestDto request,
  ) async {
    final token = _session.idToken;
    final url = Uri.parse("${ApiConfig.baseUrl}/api/payment/intent");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(request.toJson()),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return PaymentResponseDto.fromJson(data);
  }
}
