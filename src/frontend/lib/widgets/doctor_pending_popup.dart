import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

class DoctorPendingPopup extends StatelessWidget {
  const DoctorPendingPopup({
    super.key,
    this.onOk,
  });

  final VoidCallback? onOk;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: BColors.white,
        actionsAlignment: MainAxisAlignment.center,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'لا يمكنك تسجيل الدخول حالياً',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BColors.textDarkestBlue,
          ),
        ),
        content: const Text(
          'حسابك كطبيب لا يزال قيد المراجعة، وسيتم إشعارك عبر البريد الإلكتروني عند الموافقة.',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: BColors.textDarkestBlue,
          ),
          textAlign: TextAlign.right,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (onOk != null) {
                onOk!();
              } else {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.primary,
              foregroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'حسنًا',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
