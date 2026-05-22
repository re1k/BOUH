import 'dart:async';
import 'dart:io' show SocketException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/dto/doctorSignupData.dart';
import 'package:bouh/dto/doctor_work_info_draft.dart';
import 'package:bouh/dto/doctorDto.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/widgets/profile_field_validation.dart';
import 'package:bouh/View/AccountCreation/verify_email_view.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:bouh/View/AccountCreation/Doctor/doctor_account_creation_step_progress.dart';
import 'package:bouh/widgets/registration_flow_cache.dart';

class DoctorAccountCreationStep2 extends StatefulWidget {
  const DoctorAccountCreationStep2({
    super.key,
    this.signupData,
    this.initialDraft,
  });

  /// Step-1 data (email, password, name, gender, profileImage)
  final DoctorSignupData? signupData;

  /// Restored when the user returns from step 2 via back navigation.
  final DoctorWorkInfoDraft? initialDraft;

  @override
  State<DoctorAccountCreationStep2> createState() =>
      _DoctorAccountCreationStep2State();
}

class _DoctorAccountCreationStep2State
    extends State<DoctorAccountCreationStep2> {
  static const String _networkFailureMessage =
      'تأكد من أنك متصل بالإنترنت وحاول مرة أخرى.';

  static const int _minQualifications = 1;
  static const int _maxQualifications = 12;

  final _formKey = GlobalKey<FormState>();
  final _classificationFieldKey = GlobalKey<FormFieldState<String>>();
  final _ibanFieldKey = GlobalKey<FormFieldState<String>>();

  final List<TextEditingController> _qualificationCtrls = [];
  final List<FocusNode> _qualificationFocusNodes = [];
  String? _qualificationsError;

  final _classificationCtrl = TextEditingController();
  final _ibanSuffixCtrl = TextEditingController();

  final _classificationFocusNode = FocusNode();
  final _ibanFocusNode = FocusNode();

  /// Inline qualification errors only after the user starts typing in a qualification field.
  bool _qualificationsTyped = false;

  bool _scfhsNumberTyped = false;
  bool _ibanTyped = false;

  String? _specialty;
  String? _years;
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
  String? _submitError;

  void _trimQualificationsInPlace() {
    for (final c in _qualificationCtrls) {
      final normalized = ProfileFieldValidation.normalizeQualificationLine(
        c.text,
      );
      if (c.text != normalized) {
        c.value = TextEditingValue(
          text: normalized,
          selection: TextSelection.collapsed(offset: normalized.length),
        );
      }
    }
  }

  String? _qualificationFieldErrorAt(
    int index, {
    bool onlyWhenShowingErrors = true,
  }) {
    if (onlyWhenShowingErrors && !_qualificationsTyped) return null;

    final normalized = _qualificationCtrls
        .map((c) => ProfileFieldValidation.normalizeQualificationLine(c.text))
        .toList();
    final nonEmpty = normalized.where((s) => s.isNotEmpty).toList();

    if (nonEmpty.isEmpty) {
      return index == 0 ? 'يرجى إدخال مؤهل واحد على الأقل' : null;
    }

    final line = normalized[index];
    if (line.isEmpty) return null;
    return ProfileFieldValidation.qualificationLine(line);
  }

  String? _validateQualificationsList() {
    for (var i = 0; i < _qualificationCtrls.length; i++) {
      final error = _qualificationFieldErrorAt(
        i,
        onlyWhenShowingErrors: false,
      );
      if (error != null) return error;
    }
    return null;
  }

  static String? _validateSpecNumber(String? value) =>
      ProfileFieldValidation.scfhsRegistrationNumber(value);

  static String? _validateIbanSuffix(String? value) =>
      ProfileFieldValidation.ibanSuffixDigits(value);

  final List<String> _specialties = const [
    'توتر وقلق',
    'خوف',
    'حزن',
    'تفاؤل',
    'غضب',
  ];
  final List<String> _yearsList = const ['1', '2', '3', '4', '+5'];

  bool get _isFormComplete =>
      _validateQualificationsList() == null &&
      _classificationCtrl.text.trim().isNotEmpty &&
      _ibanSuffixCtrl.text.trim().length == 22 &&
      _specialty != null &&
      _years != null;

  static int _parseYears(String value) {
    if (value == '+5') return 5;
    return int.tryParse(value) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _classificationFocusNode.addListener(_onClassificationFocusChange);
    _ibanFocusNode.addListener(_onIbanFocusChange);
    final draft =
        widget.initialDraft ?? RegistrationFlowCache.doctorWorkInfo;
    if (draft != null) {
      _applyDraft(draft);
    } else {
      _addQualification(fromInitialSetup: true);
    }
  }

  DoctorWorkInfoDraft _captureDraft() {
    _trimQualificationsInPlace();
    return DoctorWorkInfoDraft(
      qualifications: _qualificationCtrls.map((c) => c.text).toList(),
      scfhsNumber: _classificationCtrl.text,
      ibanSuffix: _ibanSuffixCtrl.text,
      areaOfKnowledge: _specialty,
      years: _years,
      qualificationsTyped: _qualificationsTyped,
      scfhsNumberTyped: _scfhsNumberTyped,
      ibanTyped: _ibanTyped,
    );
  }

  void _applyDraft(DoctorWorkInfoDraft draft) {
    for (final c in _qualificationCtrls) {
      c.dispose();
    }
    for (final f in _qualificationFocusNodes) {
      f.dispose();
    }
    _qualificationCtrls.clear();
    _qualificationFocusNodes.clear();

    final lines = draft.qualifications.isEmpty ? const [''] : draft.qualifications;
    for (var i = 0; i < lines.length; i++) {
      _addQualification(fromInitialSetup: true);
      _qualificationCtrls[i].text = lines[i];
    }

    _classificationCtrl.text = draft.scfhsNumber;
    _ibanSuffixCtrl.text = draft.ibanSuffix;
    _specialty = draft.areaOfKnowledge;
    _years = draft.years;
    _qualificationsTyped = draft.qualificationsTyped;
    _scfhsNumberTyped = draft.scfhsNumberTyped;
    _ibanTyped = draft.ibanTyped;
    if (_qualificationsTyped) {
      _qualificationsError = _validateQualificationsList();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _persistDraftToCache() {
    RegistrationFlowCache.doctorWorkInfo = _captureDraft();
  }

  void _addQualification({bool fromInitialSetup = false}) {
    if (_qualificationCtrls.length >= _maxQualifications) return;
    final ctrl = TextEditingController();
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _trimQualificationsInPlace();
        if (_qualificationsTyped) {
          _qualificationsError = _validateQualificationsList();
        }
        if (mounted) setState(() {});
      }
    });
    _qualificationCtrls.add(ctrl);
    _qualificationFocusNodes.add(focusNode);
    if (!fromInitialSetup && _qualificationsTyped) {
      _qualificationsError = _validateQualificationsList();
    }
    if (mounted) setState(() {});
  }

  void _removeQualification(int index) {
    if (_qualificationCtrls.length <= _minQualifications) return;
    _qualificationCtrls[index].dispose();
    _qualificationFocusNodes[index].dispose();
    _qualificationCtrls.removeAt(index);
    _qualificationFocusNodes.removeAt(index);
    if (_qualificationsTyped) {
      _qualificationsError = _validateQualificationsList();
    }
    if (mounted) setState(() {});
  }

  void _onClassificationFocusChange() {
    if (!_classificationFocusNode.hasFocus) {
      _classificationFieldKey.currentState?.validate();
      if (mounted) setState(() {});
    }
  }

  void _onIbanFocusChange() {
    if (!_ibanFocusNode.hasFocus) {
      _ibanFieldKey.currentState?.validate();
      if (mounted) setState(() {});
    }
  }

  @override
  void deactivate() {
    if (!_submittedSuccessfully) {
      _persistDraftToCache();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    for (final c in _qualificationCtrls) c.dispose();
    for (final f in _qualificationFocusNodes) f.dispose();
    _classificationFocusNode.removeListener(_onClassificationFocusChange);
    _ibanFocusNode.removeListener(_onIbanFocusChange);
    _classificationFocusNode.dispose();
    _ibanFocusNode.dispose();
    _classificationCtrl.dispose();
    _ibanSuffixCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCreateAccount() async {
    final signupData = widget.signupData;
    print(
      '[DoctorReg Step2] _submitCreateAccount: signupData=${signupData != null ? "present" : "null"}, profileImage=${signupData?.profileImage != null ? signupData!.profileImage!.path : "null"}',
    );
    if (signupData == null || _isSubmitting) return;
    _trimQualificationsInPlace();
    setState(() {
      _qualificationsTyped = true;
      _scfhsNumberTyped = true;
      _ibanTyped = true;
      _qualificationsError = _validateQualificationsList();
    });
    if (_qualificationsError != null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final qualificationsList = _qualificationCtrls
        .map((c) => ProfileFieldValidation.normalizeQualificationLine(c.text))
        .where((s) => s.isNotEmpty)
        .toList();

    final doctorDto = DoctorDto(
      doctorId: '',
      name: signupData.name,
      email: signupData.email,
      gender: signupData.gender,
      areaOfKnowledge: _specialty!,
      qualifications: qualificationsList,
      yearsOfExperience: _parseYears(_years!),
      scfhsNumber: _classificationCtrl.text
          .trim()
          .replaceAll(RegExp(r'\s'), '')
          .toUpperCase(),
      iban: 'SA${_ibanSuffixCtrl.text.trim().replaceAll(RegExp(r'\s'), '')}',
      profilePhotoURL: signupData.profileImagePath,
      registrationStatus: 'PENDING',
    );

    try {
      print(
        '[DoctorReg Step2] _submitCreateAccount: calling AuthService.createDoctorAccount with profileImageFile=${signupData.profileImage != null ? signupData.profileImage!.path : "null"}',
      );
      await AuthService.instance.createDoctorAccount(
        doctorDto: doctorDto,
        password: signupData.password,
        profileImageFile: signupData.profileImage,
      );
      print(
        '[DoctorReg Step2] _submitCreateAccount: createDoctorAccount returned',
      );
      if (!mounted) return;
      _submittedSuccessfully = true;
      RegistrationFlowCache.clearDoctor();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VerifyEmailView()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        final String message;
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          message = 'البريد الإلكتروني مستخدم بالفعل بحساب آخر.';
        } else if (e is SocketException || e is TimeoutException) {
          message = _networkFailureMessage;
        } else {
          message = 'تعذر إنشاء الحساب. تحقق من الاتصال وحاول مرة أخرى.';
        }
        setState(() {
          _isSubmitting = false;
          _submitError = message;
        });
      }
    }
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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
        fontSize: 13,
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

  InputDecoration _inputDecorationWithCounter(
    TextEditingController ctrl,
    int maxLength,
  ) {
    return _inputDecoration().copyWith(
      counterText: '',
      counter: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${ctrl.text.length}/$maxLength',
          style: const TextStyle(fontSize: 12, color: BColors.darkGrey),
        ),
      ),
    );
  }

  InputDecoration _qualificationFieldDecoration(
    TextEditingController ctrl,
    int maxLength, {
    required bool hasError,
  }) {
    const errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: BColors.validationError),
    );
    const focusedErrorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: BColors.validationError, width: 1.5),
    );

    final base = _inputDecorationWithCounter(ctrl, maxLength);
    return base.copyWith(
      hintText: 'مثال: بكالوريوس علم نفس',
      hintStyle: const TextStyle(color: BColors.darkGrey, fontSize: 15),
      enabledBorder: hasError ? errorBorder : base.enabledBorder,
      focusedBorder: hasError ? focusedErrorBorder : base.focusedBorder,
      border: hasError ? errorBorder : base.border,
    );
  }

  Future<void> _popStep2() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final draft = _captureDraft();
    RegistrationFlowCache.doctorWorkInfo = draft;
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _popStep2();
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        backgroundColor: BColors.white,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.translucent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ================== CONTENT ==================
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      30,
                      22,
                      keyboardInset + 30,
                    ),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        children: [
                          // ================= HEADER =================
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
                                  onPressed: _popStep2,
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

                          const DoctorAccountCreationStepProgress(
                            activePersonalInfo: false,
                          ),

                          const SizedBox(height: 18),

                          // ================= FIELDS (مؤهلات: dynamic list 1–12) =================
                          Align(
                            alignment: Alignment.centerRight,
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: BColors.textDarkestBlue,
                                ),
                                children: [
                                  TextSpan(text: 'المؤهلات '),
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
                          ...List.generate(_qualificationCtrls.length, (i) {
                            final fieldError = _qualificationFieldErrorAt(i);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    textDirection: TextDirection.rtl,
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _qualificationCtrls[i],
                                          focusNode:
                                              _qualificationFocusNodes[i],
                                          keyboardType: TextInputType.text,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: BColors.textDarkestBlue,
                                          ),
                                          decoration:
                                              _qualificationFieldDecoration(
                                            _qualificationCtrls[i],
                                            70,
                                            hasError: fieldError != null,
                                          ),
                                          textAlign: TextAlign.right,
                                          textDirection: TextDirection.rtl,
                                          maxLength: 70,
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(70),
                                          ],
                                          onChanged: (_) {
                                            _qualificationsTyped = true;
                                            _qualificationsError =
                                                _validateQualificationsList();
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                      if (_qualificationCtrls.length >
                                          _minQualifications) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () =>
                                              _removeQualification(i),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: BColors.validationError,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 40,
                                            minHeight: 46,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (fieldError != null) ...[
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        fieldError,
                                        style: const TextStyle(
                                          color: BColors.validationError,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                          if (_qualificationCtrls.length < _maxQualifications)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _addQualification,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: BColors.primary,
                                  ),
                                  label: const Text(
                                    'إضافة مؤهل',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: BColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 14),

                          _LabeledFormField(
                            fieldKey: _classificationFieldKey,
                            label: 'رقم التخصص *',
                            placeholder: 'مثال: 08RM1',
                            controller: _classificationCtrl,
                            keyboardType: TextInputType.text,
                            decoration: _inputDecorationWithCounter(
                              _classificationCtrl,
                              ProfileFieldValidation.scfhsMaxLength,
                            ),
                            focusNode: _classificationFocusNode,
                            onChanged: (_) {
                              setState(() => _scfhsNumberTyped = true);
                              _classificationFieldKey.currentState?.validate();
                            },
                            validator: (v) => _scfhsNumberTyped
                                ? _validateSpecNumber(v)
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]'),
                              ),
                              LengthLimitingTextInputFormatter(
                                ProfileFieldValidation.scfhsMaxLength,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _IbanField(
                            fieldKey: _ibanFieldKey,
                            controller: _ibanSuffixCtrl,
                            decoration: _inputDecorationWithCounter(
                              _ibanSuffixCtrl,
                              22,
                            ),
                            placeholder: 'أدخل 22 رقمًا بعد SA',
                            focusNode: _ibanFocusNode,
                            onChanged: (_) {
                              setState(() => _ibanTyped = true);
                              _ibanFieldKey.currentState?.validate();
                            },
                            validator: (v) =>
                                _ibanTyped ? _validateIbanSuffix(v) : null,
                          ),

                          const SizedBox(height: 14),

                          // ================= DROPDOWNS ROW =================
                          Row(
                            children: [
                              Expanded(
                                child: _LabeledDropdown(
                                  label: 'التخصص *',
                                  hint: 'اختر التخصص',
                                  value: _specialty,
                                  items: _specialties,
                                  onChanged: (v) =>
                                      setState(() => _specialty = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _LabeledDropdown(
                                  label: 'سنوات الخبرة *',
                                  hint: 'اختر عدد السنوات',
                                  value: _years,
                                  items: _yearsList,
                                  onChanged: (v) => setState(() => _years = v),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          // ================= SUBMIT BUTTON =================
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isFormComplete && !_isSubmitting
                                  ? _submitCreateAccount
                                  : null,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: BColors.primary,
                                foregroundColor: BColors.white,
                                disabledBackgroundColor: BColors.primary
                                    .withOpacity(0.4),
                                disabledForegroundColor: BColors.white
                                    .withOpacity(0.7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'إنشاء حساب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          if (_submitError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _submitError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: BColors.validationError,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isSubmitting) BouhLoadingOverlay(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

// ================= Labeled Form Field (with validator) =================
class _LabeledFormField extends StatelessWidget {
  final Key? fieldKey;
  final String label;
  final String? placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final InputDecoration decoration;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _LabeledFormField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.decoration,
    required this.onChanged,
    this.placeholder,
    this.fieldKey,
    this.focusNode,
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
          style: const TextStyle(
            fontSize: 16,
            color: BColors.textDarkestBlue,
          ),
          decoration: decoration.copyWith(
            hintText: placeholder,
            hintStyle: const TextStyle(color: BColors.darkGrey, fontSize: 15),
          ),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          onChanged: onChanged,
          validator: validator,
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
        style: const TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
      );
    }
    final base = trimmed.substring(0, trimmed.length - 1).trimRight();
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
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

// ================= IBAN field: "SA" fixed prefix + 22 digits =================
class _IbanField extends StatelessWidget {
  final Key? fieldKey;
  final TextEditingController controller;
  final InputDecoration decoration;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String> onChanged;
  final String? Function(String?)? validator;

  const _IbanField({
    required this.controller,
    required this.decoration,
    required this.onChanged,
    required this.validator,
    this.placeholder,
    this.fieldKey,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
            children: [
              TextSpan(text: 'رقم الايبان '),
              TextSpan(
                text: '*',
                style: TextStyle(color: BColors.validationError),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: TextFormField(
                key: fieldKey,
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 16,
                  color: BColors.textDarkestBlue,
                ),
                decoration: decoration.copyWith(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    color: BColors.darkGrey,
                    fontSize: 15,
                  ),
                ),
                textAlign: TextAlign.right,
                onChanged: onChanged,
                validator: validator,
                maxLength: 22,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(22),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BColors.grey),
                color: BColors.grey.withOpacity(0.2),
              ),
              child: const Text(
                'SA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BColors.textDarkestBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ================= Labeled Dropdown =================
class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: 8),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BColors.grey),
            color: BColors.white,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: BColors.white,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: BColors.accent),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                dropdownColor: BColors.white,
                iconEnabledColor: BColors.textDarkestBlue,
                hint: Text(
                  hint,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 14, color: BColors.darkGrey),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                items: items
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            e,
                            style: const TextStyle(
                              fontSize: 16,
                              color: BColors.textDarkestBlue,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
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
        style: const TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
      );
    }
    final base = trimmed.substring(0, trimmed.length - 1).trimRight();
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: BColors.textDarkestBlue),
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
