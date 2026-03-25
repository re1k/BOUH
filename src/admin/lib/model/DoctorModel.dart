class DoctorModel {
  final String uid;
  final String name;
  final String email;
  final String areaOfKnowledge;
  final List<String> qualifications;
  final int yearsOfExperience;
  final String iban;
  final String scfhsNumber;
  final String? profilePhotoURL;

  const DoctorModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.areaOfKnowledge,
    required this.qualifications,
    required this.yearsOfExperience,
    required this.iban,
    required this.scfhsNumber,
    this.profilePhotoURL,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      areaOfKnowledge: json['areaOfKnowledge'] ?? '',
      qualifications: List<String>.from(json['qualifications'] ?? []),
      yearsOfExperience: json['yearsOfExperience'] ?? 0,
      iban: json['iban'] ?? '',
      scfhsNumber: json['scfhsNumber'] ?? '',
      profilePhotoURL: json['profilePhotoURL'],
    );
  }

  String get initials {
    final parts = name.replaceAll('د. ', '').trim().split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }

  String get qualificationsDisplay => qualifications.join(' - ');
}
