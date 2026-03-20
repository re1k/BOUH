import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

/// Strong password rules: min length, uppercase, lowercase, digit, special char.
const int kMinPasswordLength = 8;

/// Validates password against strong rules. Returns null if valid, error message in Arabic otherwise.
String? validateStrongPassword(String? value) {
  if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
  if (value.length < kMinPasswordLength) {
    return 'كلمة المرور يجب أن تكون $kMinPasswordLength أحرف على الأقل';
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    return 'يجب أن تحتوي كلمة المرور على حرف إنجليزي كبير واحد على الأقل';
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    return 'يجب أن تحتوي كلمة المرور على حرف إنجليزي صغير واحد على الأقل';
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    return 'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل';
  }
  final specialChar = RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:",./<>?`~\\]');
  if (!value.contains(specialChar)) {
    return 'يجب أن تحتوي كلمة المرور على رمز خاص واحد على الأقل (مثل !@#\$%)';
  }
  return null;
}

final _specialCharRegExp = RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:",./<>?`~\\]');

/// Returns a value 0.0..1.0 for progress bar. 1.0 when all rules met.
double passwordStrength(String value) {
  if (value.isEmpty) return 0.0;
  int count = 0;
  if (value.length >= kMinPasswordLength) count++;
  if (value.contains(RegExp(r'[A-Z]'))) count++;
  if (value.contains(RegExp(r'[a-z]'))) count++;
  if (value.contains(RegExp(r'[0-9]'))) count++;
  if (value.contains(_specialCharRegExp)) count++;
  return count / 5;
}

bool isPasswordStrong(String value) => passwordStrength(value) >= 1.0;

/// Bar color by strength: red (weak) → orange → amber → green (strong).
Color _strengthBarColor(double strength) {
  if (strength >= 1.0) return const Color(0xFF2E7D32); // green
  if (strength >= 0.6) return const Color(0xFFF9A825);   // amber
  if (strength >= 0.4) return const Color(0xFFFF9800); // orange
  if (strength >= 0.2) return const Color(0xFFE65100);  // deep orange
  return BColors.validationError;                      // red (weak)
}

/// شروط كلمة المرور تُعرض قبل حقل الإدخال.
class PasswordRequirementsText extends StatelessWidget {
  const PasswordRequirementsText({super.key});

  static const String text =
      'شروط كلمة المرور: 8 أحرف على الأقل، حرف إنجليزي كبير، حرف صغير، رقم، رمز خاص (مثل !@#\$%)';

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      color: BColors.darkGrey,
    );
    return const Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: style,
      ),
    );
  }
}

/// شريطة قوة كلمة المرور (ألوان: أحمر ضعيف → برتقالي → كهرماني → أخضر قوي).
class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = passwordStrength(password);
    final color = _strengthBarColor(strength);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: strength,
        minHeight: 6,
        backgroundColor: BColors.grey,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

/// النص + الشريطة معاً (تحت حقل كلمة المرور).
class PasswordStrengthWidget extends StatelessWidget {
  const PasswordStrengthWidget({
    super.key,
    required this.password,
  });

  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PasswordRequirementsText(),
        const SizedBox(height: 8),
        PasswordStrengthBar(password: password),
      ],
    );
  }
}
