class PaymentRequestDto {
  final String name;
  final int amount;
  final String currency;

  PaymentRequestDto({
    required this.name,
    required this.amount,
    required this.currency,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "amount": amount,
    "currency": currency,
  };
}
