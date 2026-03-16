class DoctorSearchDTO {
  final String id;
  final String name;
  final String areaOfKnowledge;
  final double averageRating;
  final String profilePhotoURL;

  DoctorSearchDTO({
    required this.id,
    required this.name,
    required this.areaOfKnowledge,
    required this.averageRating,
    required this.profilePhotoURL,
  });

  factory DoctorSearchDTO.fromJson(Map<String, dynamic> json) {
    return DoctorSearchDTO(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      areaOfKnowledge: json['areaOfKnowledge'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      profilePhotoURL: json['profilePhotoURL'] ?? '',
    );
  }
}
