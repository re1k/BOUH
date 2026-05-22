/// Draft of doctor work-info fields when leaving step 2 during registration.
class DoctorWorkInfoDraft {
  const DoctorWorkInfoDraft({
    required this.qualifications,
    required this.scfhsNumber,
    required this.ibanSuffix,
    this.areaOfKnowledge,
    this.years,
    this.qualificationsTyped = false,
    this.scfhsNumberTyped = false,
    this.ibanTyped = false,
  });

  final List<String> qualifications;
  final String scfhsNumber;
  final String ibanSuffix;
  final String? areaOfKnowledge;
  final String? years;
  final bool qualificationsTyped;
  final bool scfhsNumberTyped;
  final bool ibanTyped;
}
