import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/dto/doctorSignupData.dart';
import 'package:bouh/dto/doctorDto.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/View/AccountCreation/verify_email_view.dart';

/// Step 2 of doctor account creation: work info. When [signupData] is provided
/// (from step 1), "إنشاء حساب" builds [DoctorDto] and calls
/// [AuthService.createDoctorAccount], then navigates to [VerifyEmailView].
class DoctorAccountCreationStep2 extends StatefulWidget {
  const DoctorAccountCreationStep2({super.key, this.signupData});

  /// Step-1 data (email, password, name, gender). Required when used in the
  /// doctor registration flow; account creation runs on submit.
  final DoctorSignupData? signupData;

  @override
  State<DoctorAccountCreationStep2> createState() =>
      _DoctorAccountCreationStep2State();
}

class _DoctorAccountCreationStep2State
    extends State<DoctorAccountCreationStep2> {
  final _qualificationsCtrl = TextEditingController();
  final _classificationCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();

  String? _specialty;
  String? _years;
  bool _isSubmitting = false;
  String? _submitError;

  final List<String> _specialties = const [
    'توتر وقلق',
    'خوف',
    'حزن',
    'تفاؤل',
    'غضب',
  ];
  final List<String> _yearsList = const ['1', '2', '3', '4', '+5'];

  bool get _isFormComplete =>
      _qualificationsCtrl.text.trim().isNotEmpty &&
      _classificationCtrl.text.trim().isNotEmpty &&
      _ibanCtrl.text.trim().isNotEmpty &&
      _specialty != null &&
      _years != null;

  static int _parseYears(String value) {
    if (value == '+5') return 5;
    return int.tryParse(value) ?? 0;
  }

  @override
  void dispose() {
    _qualificationsCtrl.dispose();
    _classificationCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitCreateAccount() async {
    final signupData = widget.signupData;
    if (signupData == null || !_isFormComplete || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final doctorDto = DoctorDto(
      doctorId: '',
      name: signupData.name,
      email: signupData.email,
      gender: signupData.gender,
      areaOfKnowledge: _specialty!,
      qualifications: _qualificationsCtrl.text.trim(),
      yearsOfExperience: _parseYears(_years!),
      scfhsNumber: _classificationCtrl.text.trim(),
      iban: _ibanCtrl.text.trim(),
      registrationStatus: 'PENDING',
    );

    try {
      await AuthService.instance.createDoctorAccount(
        doctorDto: doctorDto,
        password: signupData.password,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VerifyEmailView()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        final message = e is FirebaseAuthException &&
                e.code == 'email-already-in-use'
            ? 'البريد الإلكتروني مستخدم بالفعل بحساب آخر.'
            : 'تعذر إنشاء الحساب. تحقق من البيانات وحاول مرة أخرى.';
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
                  child: Column(
                    children: [
                      // ================= HEADER =================
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

                      // ================= PROGRESS =================
                      const _DoctorProgressStep2(),

                      const SizedBox(height: 18),

                      // ================= FIELDS =================
                      _LabeledTextField(
                        label: 'مؤهلات',
                        controller: _qualificationsCtrl,
                        keyboardType: TextInputType.text,
                        decoration: _inputDecoration(),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      _LabeledTextField(
                        label: 'رقم التخصص',
                        controller: _classificationCtrl,
                        keyboardType: TextInputType.text,
                        decoration: _inputDecoration(),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),

                      _LabeledTextField(
                        label: 'رقم الايبان',
                        controller: _ibanCtrl,
                        keyboardType: TextInputType.text,
                        decoration: _inputDecoration(),
                        onChanged: (_) => setState(() {}),
                      ),

                      const SizedBox(height: 14),

                      // ================= DROPDOWNS ROW =================
                      Row(
                        children: [
                          Expanded(
                            child: _LabeledDropdown(
                              label: 'التخصص',
                              hint: '',
                              value: _specialty,
                              items: _specialties,
                              onChanged: (v) => setState(() => _specialty = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LabeledDropdown(
                              label: 'سنوات الخبرة',
                              hint: '',
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
                        width: 220,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isFormComplete && !_isSubmitting
                              ? _submitCreateAccount
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
                            'إنشاء حساب',
                            style: TextStyle(
                              fontSize: 14,
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

// ================= PROGRESS WIDGET =================
class _DoctorProgressStep2 extends StatelessWidget {
  const _DoctorProgressStep2();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Text(
          'المعلومات الشخصية',
          style: TextStyle(fontSize: 12, color: BColors.darkGrey),
        ),
        SizedBox(width: 10),
        _CircleDone(),
        SizedBox(width: 10),
        _MiniDots(),
        SizedBox(width: 10),
        _CircleActive(),
        SizedBox(width: 10),
        Text(
          'معلومات العمل',
          style: TextStyle(fontSize: 12, color: BColors.darkGrey),
        ),
      ],
    );
  }
}

class _CircleDone extends StatelessWidget {
  const _CircleDone();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: BColors.primary,
      ),
      child: const Center(
        child: Icon(Icons.check, size: 11, color: Colors.white),
      ),
    );
  }
}

class _CircleActive extends StatelessWidget {
  const _CircleActive();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: BColors.primary, width: 2),
      ),
      child: const Center(
        child: CircleAvatar(radius: 3, backgroundColor: BColors.primary),
      ),
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

// ================= Labeled TextField =================
class _LabeledTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;

  const _LabeledTextField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.decoration,
    required this.onChanged,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: decoration,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          onChanged: onChanged,
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
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
        ),
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
                  style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
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
                              fontSize: 13,
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
}
