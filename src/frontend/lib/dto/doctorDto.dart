import 'scheduleDto.dart';

class DoctorDto {
  final String doctorId;
  final String name;
  final String email;
  final String gender;
  final double? averageRating;
  final String areaOfKnowledge;
  final String qualifications;
  final int yearsOfExperience;
  final String scfhsNumber;
  final String iban;
  final String? profilePhotoURL;
  final String? fcmToken;
  final String registrationStatus;
  final List<ScheduleDto>? schedule;

  DoctorDto({
    required this.doctorId,
    required this.name,
    required this.email,
    required this.gender,
    this.averageRating,
    required this.areaOfKnowledge,
    required this.qualifications,
    required this.yearsOfExperience,
    required this.scfhsNumber,
    required this.iban,
    this.profilePhotoURL,
    this.fcmToken,
    required this.registrationStatus,
    this.schedule,
  });

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'name': name,
      'email': email,
      'gender': gender,
      'averageRating': averageRating,
      'areaOfKnowledge': areaOfKnowledge,
      'qualifications': qualifications,
      'yearsOfExperience': yearsOfExperience,
      'scfhsNumber': scfhsNumber,
      'iban': iban,
      'profilePhotoURL': profilePhotoURL,
      'fcmToken': fcmToken,
      'registrationStatus': registrationStatus,
      'schedule': schedule?.map((s) => s.toJson()).toList(),
    };
  }
}
