import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

/// Reusable popup for the user to enter an email (e.g. for reset password).
/// On submit, [onSubmit] is called with the trimmed email. Returns null on success,
/// or an error message string to show. The dialog closes only when [onSubmit] returns null.
class EmailResetPopup extends StatefulWidget {
  const EmailResetPopup({
    super.key,
    this.title = 'استعادة كلمة المرور',
    this.hint = 'البريد الإلكتروني',
    this.submitText = 'إرسال',
    this.cancelText = 'إلغاء',
    required this.onSubmit,
  });

  final String title;
  final String hint;
  final String submitText;
  final String cancelText;
  /// Returns null on success, or error message to display (popup stays open so user can resend).
  final Future<String?> Function(String email) onSubmit;

  /// Shows the email reset dialog. [onSubmit] is called with the entered email when the user taps submit.
  /// Returns `true` if submitted successfully, `false` if cancelled.
  static Future<bool> show(
    BuildContext context, {
    String title = 'استعادة كلمة المرور',
    String hint = 'البريد الإلكتروني',
    String submitText = 'إرسال',
    String cancelText = 'إلغاء',
    required Future<String?> Function(String email) onSubmit,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EmailResetPopup(
        title: title,
        hint: hint,
        submitText: submitText,
        cancelText: cancelText,
        onSubmit: onSubmit,
      ),
    );
    return result ?? false;
  }

  @override
  State<EmailResetPopup> createState() => _EmailResetPopupState();
}

class _EmailResetPopupState extends State<EmailResetPopup> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'يرجى إدخال بريد إلكتروني صحيح';
    return null;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final email = _emailCtrl.text.trim();
    final result = await widget.onSubmit(email);

    if (!mounted) return;

    setState(() {
      _loading = false;
      _errorMessage = result;
    });

    if (result == null) {
      Navigator.of(context).pop(true); // success
    }
    // else: keep dialog open, show _errorMessage so user can fix and resend
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: BColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: BColors.textDarkestBlue,
          ),
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: BColors.primary,
                  ),
                  filled: true,
                  fillColor: BColors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: BColors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: BColors.primary.withOpacity(0.6)),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: BColors.validationError),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: BColors.validationError, width: 1.5),
                  ),
                  errorStyle: const TextStyle(
                    color: BColors.validationError,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: _validateEmail,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BColors.validationError,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(false),
            child: Text(
              widget.cancelText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BColors.darkGrey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.primary,
              foregroundColor: BColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BColors.white),
                  )
                : Text(widget.submitText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
