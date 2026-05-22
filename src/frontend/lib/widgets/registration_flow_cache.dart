import 'package:bouh/dto/caregiver_children_draft.dart';
import 'package:bouh/dto/doctor_work_info_draft.dart';

/// In-memory registration drafts when navigating back between signup steps.
/// Not sent to the backend; cleared after successful account creation.
class RegistrationFlowCache {
  RegistrationFlowCache._();

  static DoctorWorkInfoDraft? doctorWorkInfo;
  static CaregiverChildrenDraft? caregiverChildren;

  static void clearDoctor() => doctorWorkInfo = null;

  static void clearCaregiver() => caregiverChildren = null;

  static void clearAll() {
    doctorWorkInfo = null;
    caregiverChildren = null;
  }
}
