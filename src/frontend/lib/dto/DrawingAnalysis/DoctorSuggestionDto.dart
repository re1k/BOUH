/// Represents one suggested doctor embedded in a drawing analysis record.
/// Maps to DoctorSuggestionDTO.java on the backend.
/// Separate from DoctorDto.dart since that is the full doctor profile.
/// This is only the minimal data embedded inside a drawing analysis document.
class DoctorSuggestionDto {
  final String id;
  final String name;
  final String? profilePhotoURL; // null when doctor has no photo

  const DoctorSuggestionDto({
    required this.id,
    required this.name,
    this.profilePhotoURL,
  });

  factory DoctorSuggestionDto.fromJson(Map<String, dynamic> json) {
    return DoctorSuggestionDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      // Backend stores empty string when null (convert back to null)
      profilePhotoURL: (json['profilePhotoURL'] as String?)?.isEmpty == true
          ? null
          : json['profilePhotoURL']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'profilePhotoURL': profilePhotoURL};
  }
}
