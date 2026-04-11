import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';

class ConfirmDeleteDialog extends StatefulWidget {
  final String name;
  final Future<void> Function() onConfirm;

  const ConfirmDeleteDialog({
    super.key,
    required this.name,
    required this.onConfirm,
  });

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool _loading = false;

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
          'هل أنت متأكد أنك تريد حذف حساب ${widget.name}؟ لا يمكن التراجع عن هذا الإجراء.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: BColors.darkerGrey,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _loading ? null : () async {
              setState(() => _loading = true);
              await widget.onConfirm();
              if (mounted) setState(() => _loading = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.validationError,
              foregroundColor: BColors.white,
              disabledBackgroundColor: BColors.validationError,
              disabledForegroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: _loading ? 0.0 : 1.0,
                  child: const Text('نعم'),
                ),
                if (_loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BColors.white,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
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
