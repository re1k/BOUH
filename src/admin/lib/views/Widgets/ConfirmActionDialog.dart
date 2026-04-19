import 'package:flutter/material.dart';
import 'package:bouh_admin/theme/colors.dart';

class ConfirmActionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmText;
  final Color confirmColor;
  final Future<void> Function() onConfirm;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  State<ConfirmActionDialog> createState() => _ConfirmActionDialogState();
}

class _ConfirmActionDialogState extends State<ConfirmActionDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.center,
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BColors.textDarkestBlue,
          ),
        ),
        content: Text(
          widget.message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: BColors.darkerGrey,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    await widget.onConfirm();
                    if (mounted) {
                      setState(() => _loading = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.confirmColor,
              foregroundColor: BColors.white,
              disabledBackgroundColor: widget.confirmColor,
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
                  child: Text(widget.confirmText),
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
