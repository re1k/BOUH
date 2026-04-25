import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bouh/dto/doctorSignupData.dart';
import 'package:bouh/View/AccountCreation/Doctor/doctor_account_creation_work_info.dart';
import 'package:bouh/widgets/password_strength_widget.dart';

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
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String _gender = 'female';
  File? _profileImage;
  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();

  bool get _isFormComplete {
    final nameTrimmed = _nameCtrl.text.trim();
    final nameUserPart = nameTrimmed.length > _namePrefix.length
        ? nameTrimmed.substring(_namePrefix.length).trim()
        : '';
    return _emailCtrl.text.trim().isNotEmpty &&
        _passCtrl.text.isNotEmpty &&
        _confirmCtrl.text.isNotEmpty &&
        nameUserPart.isNotEmpty;
  }

  bool get _isFormValidForNext {
    if (!_isFormComplete) return false;
    final emailOk = _validateEmail(_emailCtrl.text) == null;
    final passOk = _validatePassword(_passCtrl.text) == null;
    final confirmOk = _validateConfirmPassword(_confirmCtrl.text) == null;
    final nameOk = _validateName(_nameCtrl.text) == null;
    return emailOk && passOk && confirmOk && nameOk;
  }

  static const String _namePrefix = 'د. ';

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = _namePrefix;
    _nameCtrl.selection = TextSelection.collapsed(offset: _namePrefix.length);
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
      'gmail.com',
      'outlook.com',
      'hotmail.com',
      'yahoo.com',
      'icloud.com',
      'live.com',
    };
    final parts = trimmed.split('@');
    if (parts.length != 2) return 'يرجى إدخال بريد إلكتروني صحيح';

    final domain = parts.last.toLowerCase();
    final domainParts = domain.split('.');
    if (domainParts.length < 2) return 'يرجى إدخال بريد إلكتروني صحيح';

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

  String? _validatePassword(String? value) => validateStrongPassword(value);

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى تأكيد كلمة المرور';
    if (value != _passCtrl.text) return 'كلمة المرور غير متطابقة';
    return null;
  }

  /// Validates only the user-entered part of the name (after the "د. " prefix).
  String? _validateName(String? value) {
    if (value == null || value.trim().length <= _namePrefix.length) {
      return 'يرجى إدخال الاسم';
    }
    final userEntered = value.trim().substring(_namePrefix.length).trim();
    if (userEntered.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    final arabicOnly = RegExp(
      r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s]+$',
    );
    if (!arabicOnly.hasMatch(userEntered)) {
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
    print('[DoctorReg Step1] _pickImage: started');
    if (widget.onPickImage != null) {
      print('[DoctorReg Step1] _pickImage: using widget.onPickImage callback');
      final file = await widget.onPickImage!();
      if (file == null) {
        print('[DoctorReg Step1] _pickImage: callback returned null, user cancelled');
        return;
      }
      print('[DoctorReg Step1] _pickImage: callback returned file path=${file.path}');
      final purePath = _toPurePath(file.path);
      setState(() {
        _profileImagePath = purePath;
        _profileImage = File(purePath);
      });
      print('[DoctorReg Step1] _pickImage: _profileImage set from callback');
      return;
    }
    print('[DoctorReg Step1] _pickImage: picking from gallery');
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x == null) {
      print('[DoctorReg Step1] _pickImage: user cancelled gallery pick');
      return;
    }
    print('[DoctorReg Step1] _pickImage: picked path=${x.path}');
    final purePath = _toPurePath(x.path);
    setState(() {
      _profileImagePath = purePath;
      _profileImage = File(purePath);
    });
    print('[DoctorReg Step1] _pickImage: _profileImage set from gallery');
  }

  String _toPurePath(String rawPath) {
    final trimmed = rawPath.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('file://')) {
      return Uri.parse(trimmed).toFilePath();
    }
    return trimmed.replaceAll('\\', '/');
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
      profileImage: _profileImage,
      profileImagePath: _profileImagePath,
    );
    print('[DoctorReg Step1] _handleNext: signupData created with profileImage=${_profileImage != null ? _profileImage!.path : "null"}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorAccountCreationStep2(signupData: signupData),
      ),
    );
    print('[DoctorReg Step1] _handleNext: pushed to Step2 with signupData');
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
        borderSide: const BorderSide(
          color: BColors.validationError,
          width: 1.5,
        ),
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
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 30),
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
                        const SizedBox(height: 14),

                        const _StepProgress(
                          rightLabel: 'المعلومات الشخصية',
                          leftLabel: 'معلومات العمل',
                          activeRight: true,
                        ),
                        const SizedBox(height: 18),

                        _LabeledFormField(
                          label: 'الاسم *',
                          placeholder: 'مثال: د. أحمد القحطاني',
                          controller: _nameCtrl,
                          keyboardType: TextInputType.name,
                          obscure: false,
                          decoration: _inputDecoration(),
                          focusNode: _nameFocusNode,
                          fieldKey: _nameFieldKey,
                          validator: (v) =>
                              _nameTouched ? _validateName(v) : null,
                          onChanged: (_) => setState(() {}),
                          inputFormatters: [
                            _DoctorNamePrefixFormatter(prefix: _namePrefix),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _LabeledFormField(
                          label: 'البريد الإلكتروني *',
                          placeholder: 'example@gmail.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          obscure: false,
                          decoration: _inputDecoration(),
                          focusNode: _emailFocusNode,
                          fieldKey: _emailFieldKey,
                          validator: (v) =>
                              _emailTouched ? _validateEmail(v) : null,
                          onChanged: (_) {
                            if (_confirmCtrl.text.isNotEmpty) {
                              _confirmTouched = true;
                            }
                            if (_passwordTouched) {
                              _passwordFieldKey.currentState?.validate();
                            }
                            if (_confirmTouched) {
                              _confirmPasswordFieldKey.currentState?.validate();
                            }
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 14),

                        _LabeledFormField(
                          label: 'كلمة المرور *',
                          placeholder: '••••••••',
                          controller: _passCtrl,
                          keyboardType: TextInputType.text,
                          obscure: !_showPassword,
                          decoration: _inputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: BColors.darkGrey,
                              ),
                            ),
                          ),
                          focusNode: _passwordFocusNode,
                          fieldKey: _passwordFieldKey,
                          validator: (v) =>
                              _passwordTouched ? _validatePassword(v) : null,
                          onChanged: (_) {
                            if (_confirmCtrl.text.isNotEmpty) {
                              _confirmTouched = true;
                            }
                            if (_confirmTouched) {
                              _confirmPasswordFieldKey.currentState?.validate();
                            }
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 8),
                        PasswordStrengthWidget(password: _passCtrl.text),
                        const SizedBox(height: 14),

                        _LabeledFormField(
                          label: 'تأكيد كلمة المرور *',
                          placeholder: '••••••••',
                          controller: _confirmCtrl,
                          keyboardType: TextInputType.text,
                          obscure: !_showConfirmPassword,
                          decoration: _inputDecoration(
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
                          ),
                          focusNode: _confirmFocusNode,
                          fieldKey: _confirmPasswordFieldKey,
                          validator: (v) => _confirmTouched
                              ? _validateConfirmPassword(v)
                              : null,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: BColors.darkGrey,
                              ),
                              children: [
                                TextSpan(text: 'الجنس '),
                                TextSpan(
                                  text: '*',
                                  style: TextStyle(
                                    color: BColors.validationError,
                                  ),
                                ),
                              ],
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
                                icon: Icon(
                                  _profileImage != null
                                      ? Icons.edit_rounded
                                      : Icons.download_rounded,
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
                            onPressed: _isFormValidForNext
                                ? () => _handleNext()
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
            color: selected ? BColors.white : BColors.darkGrey,
          ),
        ),
      ),
    );
  }
}

/// Ensures the name field always starts with "د. " and the prefix cannot be deleted.
class _DoctorNamePrefixFormatter extends TextInputFormatter {
  _DoctorNamePrefixFormatter({required this.prefix});
  final String prefix;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length < prefix.length) {
      return TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }
    if (!text.startsWith(prefix)) {
      final newText = prefix + text;
      final newOffset = (prefix.length + newValue.selection.baseOffset)
          .clamp(prefix.length, newText.length);
      return TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
    return newValue;
  }
}

class _LabeledFormField extends StatelessWidget {
  final String label;
  final String? placeholder;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final InputDecoration decoration;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final String? Function(String?)? validator;
  final ValueChanged<String> onChanged;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledFormField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.obscure,
    required this.decoration,
    required this.onChanged,
    this.placeholder,
    this.focusNode,
    this.fieldKey,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: decoration.copyWith(
            hintText: placeholder,
            hintStyle: const TextStyle(
              color: BColors.darkGrey,
              fontSize: 13,
            ),
          ),
          validator: validator,
          textAlign: TextAlign.right,
          onChanged: onChanged,
          inputFormatters: inputFormatters,
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
