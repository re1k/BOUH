/// Body for `POST /api/rate/add` (caregiver rates a doctor after an appointment).
class RateDto {
  const RateDto({
    required this.doctorId,
    required this.rating,
    required this.appointmentId,
  });

  final String doctorId;
  final int rating;
  final String appointmentId;

  Map<String, dynamic> toJson() => {
        'doctorId': doctorId,
        'rating': rating,
        'appointmentId': appointmentId,
      };
}
