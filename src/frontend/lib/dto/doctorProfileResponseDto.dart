/// Shape of doctor account from `GET /api/accounts/profile` (not the caregiver `{ name, email }` variant).
class DoctorProfileResponseDto {
  final String? name;
  final String? gender;
  final List<String> qualifications;
  final int? yearsOfExperience;
  final String? profilePhotoURL;
  final String? iban;
  final String? email;
  final String? scfhsNumber;
  final String? areaOfKnowledge;

  DoctorProfileResponseDto({
    this.name,
    this.gender,
    this.qualifications = const [],
    this.yearsOfExperience,
    this.profilePhotoURL,
    this.iban,
    this.email,
    this.scfhsNumber,
    this.areaOfKnowledge,
  });

  factory DoctorProfileResponseDto.fromJson(Map<String, dynamic> json) {
    final rawQual = json['qualifications'];
    List<String> quals = [];
    if (rawQual is List) {
      quals = rawQual.map((e) => e.toString()).toList();
    }

    final rawYears = json['yearsOfExperience'];
    int? years;
    if (rawYears is num) {
      years = rawYears.toInt();
    } else if (rawYears != null) {
      years = int.tryParse(rawYears.toString());
    }

    return DoctorProfileResponseDto(
      name: json['name']?.toString(),
      gender: json['gender']?.toString(),
      qualifications: quals,
      yearsOfExperience: years,
      profilePhotoURL: json['profilePhotoURL']?.toString(),
      iban: json['iban']?.toString(),
      email: json['email']?.toString(),
      scfhsNumber: json['scfhsNumber']?.toString(),
      areaOfKnowledge: json['areaOfKnowledge']?.toString(),
    );
  }
}
