/// Passed from doctor account creation step 1 (personal info) to step 2 (work info)
/// so the full [DoctorDto] can be built and account creation runs after step 2.
class DoctorSignupData {
  final String email;
  final String password;
  final String name;
  final String gender;

  const DoctorSignupData({
    required this.email,
    required this.password,
    required this.name,
    required this.gender,
  });
}
