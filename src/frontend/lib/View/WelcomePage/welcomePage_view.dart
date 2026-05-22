import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/View/AccountCreation/Caregiver/caregiverAccountCreation_view.dart';
import 'package:bouh/View/AccountCreation/Doctor/doctor_account_creation_personal_info.dart';

class AccountTypeView extends StatelessWidget {
  const AccountTypeView({
    super.key,
    this.onSelectCaregiver,
    this.onSelectDoctor,
    this.onGoToLogin,
  });

  /// Selection hook for caregiver registration flow.
  /// Override to inject navigation or registration logic.
  final VoidCallback? onSelectCaregiver;

  /// Selection hook for doctor registration flow.
  /// Override to inject navigation or registration logic.
  final VoidCallback? onSelectDoctor;

  /// Navigation hook to the login screen.
  /// Override to replace default navigation behavior.
  final VoidCallback? onGoToLogin;
  void _handleCaregiverSelection(BuildContext context) {
    if (onSelectCaregiver != null) {
      onSelectCaregiver!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CaregiverSignupView()),
    );
  }

  void _handleDoctorSelection(BuildContext context) {
    if (onSelectDoctor != null) {
      onSelectDoctor!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorAccountCreationStep1(),
      ),
    );
  }

  void _handleGoToLogin(BuildContext context) {
    if (onGoToLogin != null) {
      onGoToLogin!();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// Decorative top wave (visual only).
              Positioned(
                top: -223,
                left: 20,
                child: Transform.rotate(
                  angle: 360 * math.pi / 180,
                  child: Image.asset(
                    'assets/images/wave.jpg',
                    width: w + 250,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              /// Main content.
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 160),

                      /// App logo.
                      Image.asset(
                        'assets/images/bouh_logo.png',
                        width: 250,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),

                      /// Title.
                      const Text(
                        'أهلًا بك!',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: BColors.textDarkestBlue,
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// Caregiver account selection.
                      /// Connect caregiver registration navigation here.
                      _TypeButton(
                        text: 'مقدم رعاية',
                        onPressed: () => _handleCaregiverSelection(context),
                      ),
                      const SizedBox(height: 22),

                      /// Doctor account selection.
                      /// Connect doctor registration navigation here.
                      _TypeButton(
                        text: 'طبيب',
                        onPressed: () => _handleDoctorSelection(context),
                      ),
                      const SizedBox(height: 8),

                      /// Existing account navigation.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'هل لديك حساب؟',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: BColors.darkGrey,
                            ),
                          ),
                          const SizedBox(width: 1),
                          TextButton(
                            onPressed: () => _handleGoToLogin(context),
                            child: const Text(
                              'تسجيل دخول',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: BColors.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: BColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _TypeButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: BColors.secondary,
          foregroundColor: BColors.textDarkestBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
