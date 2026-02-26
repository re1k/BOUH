//Passed from caregiver signup view to Add Children view so account
//creation happens there with the full caregiver DTO (including children)
class CaregiverSignupData {
  final String email;
  final String password;
  final String caregiverName;

  const CaregiverSignupData({
    required this.email,
    required this.password,
    required this.caregiverName,
  });
}
