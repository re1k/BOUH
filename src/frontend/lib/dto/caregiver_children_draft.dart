/// Draft of one child row on caregiver add-children step during registration.
class CaregiverChildDraft {
  const CaregiverChildDraft({
    required this.name,
    required this.gender,
    this.day,
    this.month,
    this.year,
    this.nameTouched = false,
  });

  final String name;
  final String gender;
  final String? day;
  final String? month;
  final String? year;
  final bool nameTouched;
}

/// Draft of all children entered on step 2 before account creation.
class CaregiverChildrenDraft {
  const CaregiverChildrenDraft({required this.children});

  final List<CaregiverChildDraft> children;
}
