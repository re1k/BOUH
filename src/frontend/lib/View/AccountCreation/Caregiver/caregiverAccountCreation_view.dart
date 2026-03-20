import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/dto/caregiverSignupData.dart';
import 'package:bouh/View/AccountCreation/Caregiver/AddChildern_view.dart';
import 'package:bouh/widgets/password_strength_widget.dart';

// ---------------------------------------------------------------------------
// Caregiver signup step 1: email, password, confirm password, name.
// Validation is enforced on each field; on success we pass [CaregiverSignupData]
// to step 2 (Add Children) where the full caregiver DTO is built and sent.
// ---------------------------------------------------------------------------
class CaregiverSignupView extends StatefulWidget {
  const CaregiverSignupView({super.key, this.onNext, this.onSubmitCredentials});

  /// Navigation hook for the next step.
  /// Override to replace default navigation behavior.
  final VoidCallback? onNext;

  /// Submission hook for credentials (API/Firebase/etc.).
  /// Override to perform signup/auth before proceeding.
  final Future<void> Function({
    required String email,
    required String password,
    required String confirmPassword,
    required String caregiverName,
  })?
  onSubmitCredentials;

  @override
  State<CaregiverSignupView> createState() => _CaregiverSignupViewState();
}

class _CaregiverSignupViewState extends State<CaregiverSignupView> {
  /// Form key for validation and submission control.
  final _formKey = GlobalKey<FormState>();

  /// Keys for each field so we can validate a single field when it loses focus.
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();

  /// Controllers used to retrieve user input for signup/auth integration.
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  /// Focus nodes: when a field loses focus we mark it "touched" and validate only that field.
  /// Initialized here (not in initState) so they exist after hot reload, when initState is not re-run.
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  /// "Touched" per field: error shows only after user has left that field (or on submit).
  /// Prevents all fields going red when the user taps the first field.
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;
  bool _nameTouched = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    // When a field loses focus: mark it touched and validate only that field (so error appears if empty/invalid).
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    _confirmPasswordFocusNode.addListener(_onConfirmPasswordFocusChange);
    _nameFocusNode.addListener(_onNameFocusChange);
  }

  void _onEmailFocusChange() {
    if (!_emailFocusNode.hasFocus) {
      _emailTouched = true;
      _emailFieldKey.currentState?.validate();
      if (mounted) setState(() {});
    }
  }

  void _onPasswordFocusChange() {
    if (!_passwordFocusNode.hasFocus) {
      _passwordTouched = true;
      _passwordFieldKey.currentState?.validate();
      if (mounted) setState(() {});
    }
  }

  void _onConfirmPasswordFocusChange() {
    if (!_confirmPasswordFocusNode.hasFocus) {
      _confirmPasswordTouched = true;
      _confirmPasswordFieldKey.currentState?.validate();
      if (mounted) setState(() {});
    }
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      _nameTouched = true;
      _nameFieldKey.currentState?.validate();
      if (mounted) setState(() {});
    }
  }

  /// Enables the "Next" button when all fields are filled (validation still runs on submit).
  bool get _isFormComplete =>
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      _confirmPasswordCtrl.text.isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty;

  // -------------------------------------------------------------------------
  // Pure validators (format, length, match, Arabic name). Used only when the
  // corresponding _*Touched flag is true (after user leaves field or on Next).
  // -------------------------------------------------------------------------

  /// Validates email format (basic pattern) and allowed provider domains.
  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    // Provider/domain enforcement: accept only a known set of email providers.
    // Adjust this list if your product allows additional domains.
    const allowedDomains = <String>{
      'gmail.com',
      'outlook.com',
      'hotmail.com',
      'yahoo.com',
      'icloud.com',
      'live.com',
    };

    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    final domain = parts.last.toLowerCase();
    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    // Validate top-level domain to avoid fake endings like ".vrgt.ff".
    const allowedTlds = <String>{
      'com',
      'net',
      'org',
      'edu',
      'gov',
      'sa',
    };
    final tld = domainParts.last;
    final tldRegex = RegExp(r'^[a-zA-Z]{2,}$');
    if (!tldRegex.hasMatch(tld) || !allowedTlds.contains(tld)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    if (!allowedDomains.contains(domain)) {
      return 'يرجى استخدام بريد من مزوّد معتمد (مثل Gmail / Outlook)';
    }
    return null;
  }

  /// Validates password length and strength (uppercase, lowercase, digit, special char).
  String? _validatePassword(String? value) => validateStrongPassword(value);

  /// Validates confirm password matches password (uses current password from controller in context).
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى تأكيد كلمة المرور';
    }
    if (value != _passwordCtrl.text) {
      return 'كلمة المرور غير متطابقة';
    }
    return null;
  }

  /// Validates caregiver name: not empty, letters (Arabic or English) and spaces only.
  static String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال اسم مقدم الرعاية';
    }
    // Arabic + English letters and spaces.
    final nameRegex = RegExp(
      r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FFa-zA-Z\s]+$',
    );
    if (!nameRegex.hasMatch(value.trim())) {
      return 'يرجى إدخال الاسم  ';
    }
    return null;
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _confirmPasswordFocusNode.removeListener(_onConfirmPasswordFocusChange);
    _nameFocusNode.removeListener(_onNameFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _nameFocusNode.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Handles the "Next" action: mark all fields touched, run full form validation,
  /// then build step-1 data and navigate to Add Children view.
  Future<void> _handleNext(BuildContext context) async {
    // Mark every field as touched so all errors show on submit (not only the one that was left empty).
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _confirmPasswordTouched = true;
      _nameTouched = true;
    });
    // Run all validators; if any fail, stay on this screen.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final caregiverName = _nameCtrl.text.trim();

    // Optional hook for custom submit (e.g. analytics) before navigating.
    if (widget.onSubmitCredentials != null) {
      await widget.onSubmitCredentials!(
        email: email,
        password: password,
        confirmPassword: _confirmPasswordCtrl.text,
        caregiverName: caregiverName,
      );
    }

    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }

    // Build step-1 data and pass to Add Children view; account creation runs there.
    final signupData = CaregiverSignupData(
      email: email,
      password: password,
      caregiverName: caregiverName,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaregiverAccountCreationStep2(signupData: signupData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// Scrollable container to support small screens and keyboard overlap.
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 240),
                  child: Form(
                    key: _formKey,
                    // Disabled: we validate only when a field loses focus (single field) or on Next (all fields).
                    // Avoids all fields going red as soon as the user taps the first one.
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        /// Header area (branding + guidance text).
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: BColors.textDarkestBlue,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: Text(
                                  'دقائق ويكتمل إنشاء الحساب',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: BColors.textDarkestBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 35),
                              Image.asset(
                                'assets/images/login_header.png',
                                width: 60,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        /// Name: first field in the form.
                        _LabeledField(
                          label: 'اسم مقدم الرعاية *',
                          placeholder: 'سارة احمد',
                          keyboardType: TextInputType.name,
                          obscure: false,
                          controller: _nameCtrl,
                          focusNode: _nameFocusNode,
                          fieldKey: _nameFieldKey,
                          validator: (v) =>
                              _nameTouched ? _validateName(v) : null,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        /// Email: error only after user leaves this field empty/invalid (or on Next).
                        _LabeledField(
                          label: 'البريد الإلكتروني * ',
                          placeholder: 'example@gmail.com',
                          keyboardType: TextInputType.emailAddress,
                          obscure: false,
                          controller: _emailCtrl,
                          focusNode: _emailFocusNode,
                          fieldKey: _emailFieldKey,
                          validator: (v) =>
                              _emailTouched ? _validateEmail(v) : null,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        /// Password: error only after user leaves this field (or on Next).
                        _LabeledField(
                          label: 'كلمة المرور *',
                          placeholder: '••••••••',
                          keyboardType: TextInputType.text,
                          obscure: !_showPassword,
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: BColors.darkGrey,
                            ),
                          ),
                          controller: _passwordCtrl,
                          focusNode: _passwordFocusNode,
                          fieldKey: _passwordFieldKey,
                          validator: (v) =>
                              _passwordTouched ? _validatePassword(v) : null,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        PasswordStrengthWidget(password: _passwordCtrl.text),
                        const SizedBox(height: 14),

                        /// Confirm password: error only after user leaves this field (or on Next).
                        _LabeledField(
                          label: 'تأكيد كلمة المرور *',
                          placeholder: '••••••••',
                          keyboardType: TextInputType.text,
                          obscure: !_showConfirmPassword,
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                              () => _showConfirmPassword =
                                  !_showConfirmPassword,
                            ),
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: BColors.darkGrey,
                            ),
                          ),
                          controller: _confirmPasswordCtrl,
                          focusNode: _confirmPasswordFocusNode,
                          fieldKey: _confirmPasswordFieldKey,
                          validator: (v) => _confirmPasswordTouched
                              ? _validateConfirmPassword(v)
                              : null,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        const SizedBox(height: 30),

                        /// Next button.
                        /// Disabled until all fields are filled.
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isFormComplete
                                ? () => _handleNext(context)
                                : null,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: BColors.secondary,
                              foregroundColor: BColors.textDarkestBlue,
                              disabledBackgroundColor: BColors.secondary
                                  .withOpacity(0.4),
                              disabledForegroundColor: BColors.textDarkestBlue
                                  .withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'التالي',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// Decorative bottom wave (visual only).
              if (MediaQuery.of(context).viewInsets.bottom == 0)
                Positioned(
                  left: -400,
                  bottom: -290,
                  child: Transform.rotate(
                    alignment: Alignment.bottomLeft,
                    angle: 11 * math.pi / 180,
                    child: SizedBox(
                      height: 520,
                      child: Image.asset(
                        'assets/images/wave_login.jpg',
                        fit: BoxFit.cover,
                      ),
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

/// Reusable labeled form field. Optional [focusNode] and [fieldKey] let the parent
/// validate this field when it loses focus (so error shows only after user leaves the field).
class _LabeledField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final bool obscure;
  final TextInputType keyboardType;

  /// Controller injected from parent for data access and validation.
  final TextEditingController controller;

  /// Optional: used to detect when this field loses focus (mark touched + validate).
  final FocusNode? focusNode;

  /// Optional: key for this FormField so parent can call validate() on this field only.
  final Key? fieldKey;

  /// Validator for this field (e.g. email format, password length). Parent often wraps with "touched" check.
  final String? Function(String?)? validator;

  /// Enables keyboard navigation between fields.
  final TextInputAction? textInputAction;

  /// Keeps button state in sync with typing without changing UI.
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  const _LabeledField({
    required this.label,
    required this.keyboardType,
    required this.obscure,
    required this.controller,
    required this.onChanged,
    this.placeholder,
    this.focusNode,
    this.fieldKey,
    this.validator,
    this.textInputAction,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),

        /// TextFormField: [fieldKey] allows parent to validate this field on unfocus; [focusNode] tracks focus.
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscure,
          textAlign: TextAlign.right,
          validator: validator,
          textInputAction: textInputAction,
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: BColors.darkGrey,
              fontSize: 13,
            ),
            filled: true,
            fillColor: BColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BColors.primary.withOpacity(0.6)),
            ),
            // Error text at bottom of field in deep red.
            errorStyle: const TextStyle(
              color: BColors.validationError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BColors.validationError),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: BColors.validationError,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel() {
    final trimmed = label.trim();
    final hasRequiredStar = trimmed.endsWith('*');
    if (!hasRequiredStar) {
      return Text(
        label,
        style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
      );
    }

    final base = trimmed.substring(0, trimmed.length - 1).trimRight();
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
        children: [
          TextSpan(text: '$base '),
          const TextSpan(
            text: '*',
            style: TextStyle(color: BColors.validationError),
          ),
        ],
      ),
    );
  }
}
