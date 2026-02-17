class PaymentResponseDto {
  final String paymentIntentId;
  final String clientSecret;

  PaymentResponseDto({
    required this.paymentIntentId,
    required this.clientSecret,
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) {
    return PaymentResponseDto(
      paymentIntentId: json["paymentIntentId"],
      clientSecret: json["clientSecret"],
    );
  }
}
