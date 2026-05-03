import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';


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
    this.singleButton = false,
    this.useDarkMessageText = false,
  });

  final String? title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final bool singleButton;
  final bool useDarkMessageText;

  //Shows the confirmation dialog. Returns a [Future] that completes with
  static Future<bool> show(
    BuildContext context, {
    String? title,
    required String message,
    String confirmText = 'تأكيد',
    String cancelText = 'إلغاء',
    bool isDestructive = false,
    bool singleButton = false,
    bool useDarkMessageText = false,
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
        singleButton: singleButton,
        useDarkMessageText: useDarkMessageText,
        onConfirm: () {},
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 340,
            maxHeight: screenHeight * 0.5,
          ),
          child: AlertDialog(
            backgroundColor: BColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
        title: title != null
            ? Center(
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: BColors.textDarkestBlue,
                  ),
                ),
              )
            : null,
        content: SingleChildScrollView(
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: useDarkMessageText
                    ? BColors.textDarkestBlue
                    : BColors.darkGrey,
                height: 1.4,
              ),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (!singleButton)
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
              backgroundColor: isDestructive ? BColors.destructiveError : BColors.primary,
              foregroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
