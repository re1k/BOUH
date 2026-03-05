/// DTO matching backend GET /api/appointments/upcoming/{caregiverId} response item.

class UpcomingAppointmentDto {
  final String appointmentId;
  final String date;
  final String? startTime;
  final String? endTime;
  final String? doctorName;
  final String? doctorAreaOfKnowledge;
  final String? doctorProfilePhotoURL;
  /// Caregiver display name; set when response is for doctor view.
  final String? caregiverName;
  final String? childName;

  /// 0 = لم يتم الحضور, 1 = تم الحضور. Integer only.
  final int? status;
  final String? meetingLink;
  final String? paymentIntentId;

  UpcomingAppointmentDto({
    required this.appointmentId,
    required this.date,
    this.startTime,
    this.endTime,
    this.doctorName,
    this.doctorAreaOfKnowledge,
    this.doctorProfilePhotoURL,
    this.caregiverName,
    this.childName,
    this.status,
    this.meetingLink,
    this.paymentIntentId,
  });

  /// Parse one list element from backend JSON (raw response is List<Map>).
  factory UpcomingAppointmentDto.fromJson(Map<String, dynamic> json) {
    return UpcomingAppointmentDto(
      appointmentId: json['appointmentId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      doctorName: json['doctorName'] as String?,
      doctorAreaOfKnowledge: json['doctorAreaOfKnowledge'] as String?,
      doctorProfilePhotoURL: json['doctorProfilePhotoURL'] as String?,
      caregiverName: json['caregiverName'] as String?,
      childName: json['childName'] as String?,
      status: (json['status'] is num) ? (json['status'] as num).toInt() : null,
      meetingLink: json['meetingLink'] as String?,
      paymentIntentId: json['paymentIntentId'] as String?,
    );
  }
}
