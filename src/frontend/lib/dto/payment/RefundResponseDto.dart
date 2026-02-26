class RefundResponseDto {
  final String refundId;
  final String status;
  final int amount;
  final String currency;

  RefundResponseDto({
    required this.refundId,
    required this.status,
    required this.amount,
    required this.currency,
  });

  factory RefundResponseDto.fromJson(Map<String, dynamic> json) {
    return RefundResponseDto(
      refundId: (json["refundId"] ?? "").toString(),
      status: (json["status"] ?? "").toString(),
      amount: (json["amount"] as num).toInt(),
      currency: (json["currency"] ?? "").toString(),
    );
  }
}
