class BookAppointmentRequestDto {
  final String doctorId;
  final String childId;
  final String date;
  final int slotIndex;
  final String paymentIntentId;
  final int amount;

  BookAppointmentRequestDto({
    required this.doctorId,
    required this.childId,
    required this.date,
    required this.slotIndex,
    required this.paymentIntentId,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'doctorId': doctorId,
    'childId': childId,
    'date': date,
    'slotIndex': slotIndex,
    'paymentIntentId': paymentIntentId,
    'amount': amount,
  };
}
