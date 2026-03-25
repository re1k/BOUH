class DoctorSummaryDto {
  final String name;
  final String areaOfKnowledge;
  final double rating;
  final String? doctorId;
  final String? profilePhotoURL;

  DoctorSummaryDto({
    required this.name,
    required this.areaOfKnowledge,
    required this.rating,
    this.doctorId,
    this.profilePhotoURL,
  });

  factory DoctorSummaryDto.fromJson(Map<String, dynamic> json) {
    final raw = json['rating'] ?? json['averageRating'];

    final double parsed = (raw is num)
        ? raw.toDouble()
        : (raw is String)
        ? (double.tryParse(raw) ?? 0.0)
        : 0.0;

    return DoctorSummaryDto(
      doctorId: (json['doctorId'] ?? json['doctorID'])?.toString(),
      name: (json['name'] ?? '').toString(),
      areaOfKnowledge: (json['areaOfKnowledge'] ?? '').toString(),
      rating: parsed,
      profilePhotoURL: json['profilePhotoURL'],
    );
  }
}
