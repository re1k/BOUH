class DoctorSearchDTO {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String profilePhotoURL;

  DoctorSearchDTO({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.profilePhotoURL,
  });

  factory DoctorSearchDTO.fromJson(Map<String, dynamic> json) {
    return DoctorSearchDTO(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      profilePhotoURL: json['profilePhoto'] ?? '',
    );
  }
}
