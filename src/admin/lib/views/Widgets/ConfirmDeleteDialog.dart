import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    required this.name,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text(
          'تأكيد الحذف',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BColors.textDarkestBlue,
          ),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف حساب $name؟ لا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: BColors.darkerGrey,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.validationError,
              foregroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('نعم، حذف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: BColors.darkGrey),
            ),
          ),
        ],
      ),
    );
  }
}
