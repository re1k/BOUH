class DoctorSummaryDto {
  final String doctorID;
  final String name;
  final String areaOfKnowledge;
  final double averageRating;
  final String? profilePhotoURL;

  DoctorSummaryDto({
    required this.doctorID,
    required this.name,
    required this.areaOfKnowledge,
    required this.averageRating,
    this.profilePhotoURL,
  });

  factory DoctorSummaryDto.fromJson(Map<String, dynamic> json) {
    return DoctorSummaryDto(
      doctorID: json['doctorID'] ?? '',
      name: json['name'] ?? '',
      areaOfKnowledge: json['areaOfKnowledge'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      profilePhotoURL: json['profilePhotoURL'],
    );
  }
}
