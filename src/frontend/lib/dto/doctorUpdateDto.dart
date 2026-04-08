class DoctorUpdateDto {
  final String? name;
  final String? gender;
  final List<String>? qualifications;
  final int? yearsOfExperience;
  final String? profilePhotoURL;
  final String? iban;

  DoctorUpdateDto({
    this.name,
    this.gender,
    this.qualifications,
    this.yearsOfExperience,
    this.profilePhotoURL,
    this.iban,
  });

  //Omits null entries so the backend only applies sent fields.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (gender != null) map['gender'] = gender;
    if (qualifications != null) {
      map['qualifications'] = qualifications!
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty)
          .toList(growable: false);
    }
    if (yearsOfExperience != null) map['yearsOfExperience'] = yearsOfExperience;
    if (profilePhotoURL != null) map['profilePhotoURL'] = profilePhotoURL;
    if (iban != null) map['iban'] = iban;
    return map;
  }
}
