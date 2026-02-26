import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

/// Reusable confirmation popup: shows a [message] and optional [title].
/// User can confirm or cancel. On confirm, [onConfirm] is called (and the dialog closes).
/// Use [confirmText] / [cancelText] to customize button labels (defaults: تأكيد / إلغاء).
/// Set [isDestructive] to true to style the confirm button as danger (e.g. for delete).
class ConfirmationPopup extends StatelessWidget {
  const ConfirmationPopup({
    super.key,
    this.title,
    required this.message,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  final String? title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  /// Shows the confirmation dialog. Returns a [Future] that completes with
  /// `true` if the user confirmed, `false` if cancelled.
  static Future<bool> show(
    BuildContext context, {
    String? title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfirmationPopup(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: BColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: BColors.textDarkestBlue,
                ),
              )
            : null,
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            color: BColors.darkGrey,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              onCancel?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(
              cancelText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BColors.darkGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? BColors.validationError : BColors.primary,
              foregroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
