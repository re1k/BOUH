import 'dart:io';

import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bouh/dto/doctorSignupData.dart';
import 'package:bouh/View/AccountCreation/Doctor/doctor_account_creation_work_info.dart';
import 'package:bouh/widgets/password_strength_widget.dart';

/// Step 1 of doctor account creation: email, password, name, gender.
/// On success passes [DoctorSignupData] to step 2 (work info) where [DoctorDto] is built and account is created.
class DoctorAccountCreationStep1 extends StatefulWidget {
  const DoctorAccountCreationStep1({super.key, this.onNext, this.onPickImage});

  final VoidCallback? onNext;
  final Future<File?> Function()? onPickImage;

  @override
  State<DoctorAccountCreationStep1> createState() =>
      _DoctorAccountCreationStep1State();
}

class _DoctorAccountCreationStep1State
    extends State<DoctorAccountCreationStep1> {
  final _formKey = GlobalKey<FormState>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmPasswordFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmTouched = false;
  bool _nameTouched = false;

  String _gender = 'female';
  File? _profileImage;

  final ImagePicker _picker = ImagePicker();

  bool get _isFormComplete =>
      _emailCtrl.text.trim().isNotEmpty &&
      _passCtrl.text.isNotEmpty &&
      _confirmCtrl.text.isNotEmpty &&
      _nameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    _confirmFocusNode.addListener(_onConfirmFocusChange);
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

  void _onConfirmFocusChange() {
    if (!_confirmFocusNode.hasFocus) {
      _confirmTouched = true;
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
    const allowedDomains = <String>{
      'gmail.com', 'outlook.com', 'hotmail.com', 'yahoo.com', 'icloud.com', 'live.com',
    };
    final parts = trimmed.split('@');
    if (parts.length != 2) return 'يرجى إدخال بريد إلكتروني صحيح';
    if (!allowedDomains.contains(parts.last.toLowerCase())) {
      return 'يرجى استخدام بريد من مزوّد معتمد (مثل Gmail / Outlook)';
    }
    return null;
  }

  String? _validatePassword(String? value) =>
      validateStrongPassword(value);

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (value != _passCtrl.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  static String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    final arabicOnly = RegExp(r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s]+$');
    if (!arabicOnly.hasMatch(value.trim())) {
      return 'يرجى إدخال الاسم باللغة العربية فقط';
    }
    return null;
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _confirmFocusNode.removeListener(_onConfirmFocusChange);
    _nameFocusNode.removeListener(_onNameFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _nameFocusNode.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (widget.onPickImage != null) {
      final file = await widget.onPickImage!();
      if (file == null) return;
      setState(() => _profileImage = file);
      return;
    }
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    setState(() => _profileImage = File(x.path));
  }

  void _handleNext() {
    if (!_isFormComplete) return;
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _confirmTouched = true;
      _nameTouched = true;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (widget.onNext != null) {
      widget.onNext!();
      return;
    }

    final signupData = DoctorSignupData(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      name: _nameCtrl.text.trim(),
      gender: _gender,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorAccountCreationStep2(signupData: signupData),
      ),
    );
  }

  InputDecoration _inputDecoration({Widget? suffixIcon}) {
    return InputDecoration(
      suffixIcon: suffixIcon,
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
        borderSide: const BorderSide(color: BColors.validationError, width: 1.5),
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
              // ================== CONTENT ==================
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/login_header.png',
                                width: 56,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 18),
                              const Expanded(
                                child: Text(
                                  'دقائق قليلة ويكتمل إنشاء الحساب',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: BColors.textDarkestBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        const _StepProgress(
                          rightLabel: 'المعلومات الشخصية',
                          leftLabel: 'معلومات العمل',
                          activeRight: true,
                        ),
                        const SizedBox(height: 18),

                        _LabeledFormField(
                          label: 'البريد الإلكتروني',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          obscure: false,
                          decoration: _inputDecoration(),
                          focusNode: _emailFocusNode,
                          fieldKey: _emailFieldKey,
                          validator: (v) => _emailTouched ? _validateEmail(v) : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        _LabeledFormField(
                          label: 'كلمة المرور',
                          controller: _passCtrl,
                          keyboardType: TextInputType.text,
                          obscure: true,
                          decoration: _inputDecoration(),
                          focusNode: _passwordFocusNode,
                          fieldKey: _passwordFieldKey,
                          validator: (v) => _passwordTouched ? _validatePassword(v) : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        PasswordStrengthWidget(password: _passCtrl.text),
                        const SizedBox(height: 14),

                        _LabeledFormField(
                          label: 'تأكيد كلمة المرور',
                          controller: _confirmCtrl,
                          keyboardType: TextInputType.text,
                          obscure: true,
                          decoration: _inputDecoration(),
                          focusNode: _confirmFocusNode,
                          fieldKey: _confirmPasswordFieldKey,
                          validator: (v) => _confirmTouched ? _validateConfirmPassword(v) : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        _LabeledFormField(
                          label: 'الاسم',
                          controller: _nameCtrl,
                          keyboardType: TextInputType.name,
                          obscure: false,
                          decoration: _inputDecoration(),
                          focusNode: _nameFocusNode,
                          fieldKey: _nameFieldKey,
                          validator: (v) => _nameTouched ? _validateName(v) : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'الجنس',
                          style: TextStyle(
                            fontSize: 13,
                            color: BColors.darkGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      _GenderSegment(
                        value: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerRight,
                        child: const Text(
                          'صورة شخصية',
                          style: TextStyle(
                            fontSize: 13,
                            color: BColors.darkGrey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        height: 46,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: BColors.grey),
                          color: BColors.white,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(
                                Icons.download_rounded,
                                color: BColors.primary,
                              ),
                            ),
                            const Spacer(),
                            if (_profileImage != null)
                              const Text(
                                'تم اختيار صورة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: BColors.darkGrey,
                                ),
                              ),
                            const Spacer(),
                          ],
                        ),
                      ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isFormComplete ? () => _handleNext() : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: BColors.secondary,
                            foregroundColor: BColors.textDarkestBlue,
                            disabledBackgroundColor: BColors.secondary
                                .withOpacity(0.4),
                            disabledForegroundColor: BColors.textDarkestBlue
                                .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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

              // ================== BACK ARROW (ON TOP) ==================
              Positioned(
                top: -10,
                right: 30,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: BColors.textDarkestBlue,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  final String rightLabel;
  final String leftLabel;
  final bool activeRight;

  const _StepProgress({
    required this.rightLabel,
    required this.leftLabel,
    required this.activeRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          rightLabel,
          style: const TextStyle(fontSize: 12, color: BColors.darkGrey),
        ),
        const SizedBox(width: 10),
        _Dot(active: activeRight),
        const SizedBox(width: 10),
        const _MiniDots(),
        const SizedBox(width: 10),
        _Dot(active: !activeRight),
        const SizedBox(width: 10),
        Text(
          leftLabel,
          style: const TextStyle(fontSize: 12, color: BColors.darkGrey),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? BColors.primary : BColors.grey,
          width: 2,
        ),
      ),
      child: active
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BColors.primary,
                ),
              ),
            )
          : null,
    );
  }
}

class _MiniDots extends StatelessWidget {
  const _MiniDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (i) => Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: BColors.grey,
          ),
        ),
      ),
    );
  }
}

class _GenderSegment extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GenderSegment({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isFemale = value == 'female';

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BColors.grey),
        color: BColors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegButton(
              text: 'أنثى',
              selected: isFemale,
              onTap: () => onChanged('female'),
            ),
          ),
          Expanded(
            child: _SegButton(
              text: 'ذكر',
              selected: !isFemale,
              onTap: () => onChanged('male'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SegButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? BColors.accent : Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? BColors.textDarkestBlue : BColors.darkGrey,
          ),
        ),
      ),
    );
  }
}

class _LabeledFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final InputDecoration decoration;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;

  const _LabeledFormField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.obscure,
    required this.decoration,
    required this.onChanged,
    this.focusNode,
    this.fieldKey,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: decoration,
          validator: validator,
          textAlign: TextAlign.right,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
