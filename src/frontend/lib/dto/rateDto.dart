//Rating DTO for submitting a doctor's rating (1–5).
class RateDto {
  const RateDto({
    required this.doctorId,
    required this.rating,
    required this.appointmentId,
  });

  //Doctor UID used in POST /api/rate/add/{doctorId}.
  final String doctorId;

  //Rating value 1–5.
  final int rating;

  //Appointment ID used in POST /api/rate/add/{doctorId}.
  final String appointmentId;

  Map<String, dynamic> toJson() => {
        'doctorId': doctorId,
        'rating': rating,
        'appointmentId': appointmentId,
      };
}

