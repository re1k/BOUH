import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

/// Two-step progress indicator for doctor account creation (personal → work).
class DoctorAccountCreationStepProgress extends StatelessWidget {
  const DoctorAccountCreationStepProgress({
    super.key,
    required this.activePersonalInfo,
  });

  /// `true` on step 1 (personal info); `false` on step 2 (work info).
  final bool activePersonalInfo;

  static const String personalInfoLabel = 'المعلومات الشخصية';
  static const String workInfoLabel = 'معلومات العمل';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          personalInfoLabel,
          style: const TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
        ),
        const SizedBox(width: 10),
        _StepDot(
          state: activePersonalInfo
              ? _StepDotState.active
              : _StepDotState.completed,
        ),
        const SizedBox(width: 10),
        const _StepConnectorDots(),
        const SizedBox(width: 10),
        _StepDot(
          state: activePersonalInfo
              ? _StepDotState.inactive
              : _StepDotState.active,
        ),
        const SizedBox(width: 10),
        Text(
          workInfoLabel,
          style: const TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
        ),
      ],
    );
  }
}

enum _StepDotState { inactive, active, completed }

class _StepDot extends StatelessWidget {
  const _StepDot({required this.state});

  final _StepDotState state;

  @override
  Widget build(BuildContext context) {
    if (state == _StepDotState.completed) {
      return Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: BColors.primary,
        ),
        child: const Center(
          child: Icon(Icons.check, size: 10, color: Colors.white),
        ),
      );
    }

    final active = state == _StepDotState.active;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? BColors.primary : BColors.grey,
          width: 2,
        ),
      ),
      child: active
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

class _StepConnectorDots extends StatelessWidget {
  const _StepConnectorDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: BColors.grey,
          ),
        ),
      ),
    );
  }
}
