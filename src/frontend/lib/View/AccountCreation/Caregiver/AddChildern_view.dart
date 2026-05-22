import 'dart:async';
import 'dart:io' show SocketException;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/widgets/profile_field_validation.dart';
import 'package:bouh/dto/caregiverSignupData.dart';
import 'package:bouh/dto/caregiver_children_draft.dart';
import 'package:bouh/dto/caregiverDto.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/View/AccountCreation/verify_email_view.dart';
import 'package:bouh/services/childrenService.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:bouh/widgets/registration_flow_cache.dart';

class CaregiverAccountCreationStep2 extends StatefulWidget {
  const CaregiverAccountCreationStep2({
    super.key,
    this.signupData,
    this.initialDraft,
  });

  final CaregiverSignupData? signupData;

  /// Restored when the user returns from this screen via back navigation.
  final CaregiverChildrenDraft? initialDraft;

  @override
  State<CaregiverAccountCreationStep2> createState() =>
      _CaregiverAccountCreationStep2State();
}

class _ChildFormData {
  final TextEditingController nameController = TextEditingController();
  final FocusNode nameFocusNode = FocusNode();
  /// Same pattern as qualifications: remove listener before disposing [nameFocusNode].
  VoidCallback? _onNameBlurNormalize;

  /// Name error shows only after the user focuses or types in the name field (or on submit).
  bool nameTouched = false;

  String gender = 'female';
  String? day;
  String? month;
  String? year;

  bool get isComplete =>
      ProfileFieldValidation.childDisplayName(nameController.text) == null &&
      day != null &&
      month != null &&
      year != null;

  void dispose() {
    if (_onNameBlurNormalize != null) {
      nameFocusNode.removeListener(_onNameBlurNormalize!);
    }
    nameFocusNode.dispose();
    nameController.dispose();
  }
}

class _CaregiverAccountCreationStep2State
    extends State<CaregiverAccountCreationStep2> {
  static const int _maxChildren = 5;

  final List<_ChildFormData> _childrenForms = [_ChildFormData()];
  bool _isSubmitting = false;
  bool _submittedSuccessfully = false;
  String? _submitError;

  /// Number of days in the given month/year (leap-year aware).
  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Day options 1..maxDay for the given month/year. If month or year is missing, returns 1..31.
  List<String> _daysFor(int? month, int? year) {
    if (month == null || year == null) {
      return List.generate(31, (i) => '${i + 1}');
    }
    final n = _daysInMonth(year, month);
    return List.generate(n, (i) => '${i + 1}');
  }

  /// Clears the selected day when month/year change makes it invalid for the calendar.
  void _clearDayIfInvalidForMonthYear(_ChildFormData child) {
    final m = child.month != null ? int.tryParse(child.month!) : null;
    final y = child.year != null ? int.tryParse(child.year!) : null;
    if (m == null || y == null || child.day == null) return;
    final maxDay = _daysInMonth(y, m);
    final d = int.tryParse(child.day!);
    if (d == null || d < 1 || d > maxDay) {
      child.day = null;
    }
  }

  /// Birth date from dropdowns: real calendar check + age 6–13 (same rule as [ChildrenManagementView]).
  /// Year/month/day lists already constrain ranges; we skip duplicate bound messages.
  String? _validateChildDateOfBirth(_ChildFormData child) {
    final ys = child.year;
    final ms = child.month;
    final ds = child.day;
    if (ys == null || ms == null || ds == null) return null;

    final y = int.tryParse(ys);
    final m = int.tryParse(ms);
    final d = int.tryParse(ds);
    if (y == null || m == null || d == null) {
      return 'تاريخ الميلاد يجب أن يكون أرقامًا';
    }

    final dob =
        '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';

    final birthDate = DateTime.tryParse('${dob}T00:00:00');
    if (birthDate == null ||
        birthDate.year != y ||
        birthDate.month != m ||
        birthDate.day != d) {
      return 'تاريخ الميلاد غير صحيح';
    }

    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    if (age < 6 || age > 13) {
      return 'يجب أن يكون عمر الطفل بين 6 و 13 سنة';
    }

    return null;
  }

  List<String> get _months => List.generate(12, (i) => '${i + 1}');
  List<String> get _years {
    final now = DateTime.now().year;
    final minYear = now - 13;
    final maxYear = now - 6;

    return List.generate(maxYear - minYear + 1, (i) => '${maxYear - i}');
  }

  /// Like qualifications: normalize child name in the field when focus leaves.
  void _attachChildNameBlurNormalize(_ChildFormData c) {
    void listener() {
      if (!c.nameFocusNode.hasFocus) {
        c.nameTouched = true;
        ProfileFieldValidation.syncTextControllerToNormalizedPersonName(
          c.nameController,
        );
        if (mounted) setState(() {});
      }
    }

    c._onNameBlurNormalize = listener;
    c.nameFocusNode.addListener(listener);
  }

  @override
  void initState() {
    super.initState();
    final draft =
        widget.initialDraft ?? RegistrationFlowCache.caregiverChildren;
    if (draft != null && draft.children.isNotEmpty) {
      _applyDraft(draft);
    } else {
      _attachChildNameBlurNormalize(_childrenForms.first);
    }
  }

  CaregiverChildrenDraft _captureDraft() {
    return CaregiverChildrenDraft(
      children: _childrenForms
          .map(
            (c) => CaregiverChildDraft(
              name: c.nameController.text,
              gender: c.gender,
              day: c.day,
              month: c.month,
              year: c.year,
              nameTouched: c.nameTouched,
            ),
          )
          .toList(),
    );
  }

  void _applyDraft(CaregiverChildrenDraft draft) {
    for (final f in _childrenForms) {
      f.dispose();
    }
    _childrenForms.clear();

    for (final child in draft.children) {
      final form = _ChildFormData();
      form.nameController.text = child.name;
      form.gender = child.gender;
      form.day = child.day;
      form.month = child.month;
      form.year = child.year;
      form.nameTouched = child.nameTouched;
      _attachChildNameBlurNormalize(form);
      _childrenForms.add(form);
    }

    if (_childrenForms.isEmpty) {
      final form = _ChildFormData();
      _attachChildNameBlurNormalize(form);
      _childrenForms.add(form);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _persistDraftToCache() {
    RegistrationFlowCache.caregiverChildren = _captureDraft();
  }

  Future<void> _popStep2() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final draft = _captureDraft();
    RegistrationFlowCache.caregiverChildren = draft;
    Navigator.of(context).pop(draft);
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
    for (final f in _childrenForms) {
      f.dispose();
    }
    super.dispose();
  }

  bool _allChildrenComplete() {
    return _childrenForms.isNotEmpty &&
        _childrenForms.every((c) => c.isComplete);
  }

  bool _canShowAddButton() {
    final last = _childrenForms.last;
    return last.isComplete && _childrenForms.length < _maxChildren;
  }

  void _addAnotherChild() {
    if (!_canShowAddButton()) return;
    final next = _ChildFormData();
    _attachChildNameBlurNormalize(next);
    setState(() => _childrenForms.add(next));
  }

  void _removeChild(int index) {
    if (_childrenForms.length == 1) return;
    final removed = _childrenForms.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _submitAll() async {
    if (!_allChildrenComplete()) return;

    final signupData = widget.signupData;
    if (signupData == null) return;

    setState(() {
      for (final c in _childrenForms) {
        c.nameTouched = true;
      }
    });

    for (final c in _childrenForms) {
      ProfileFieldValidation.syncTextControllerToNormalizedPersonName(
        c.nameController,
      );
      final nameErr = ProfileFieldValidation.childDisplayName(
        c.nameController.text,
      );
      if (nameErr != null) {
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(nameErr)),
          );
        }
        return;
      }
      final dateErr = _validateChildDateOfBirth(c);
      if (dateErr != null) {
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(dateErr)),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isSubmitting = true;
        _submitError = null;
      });
    }

    try {
      // 1) Firebase account creation (sets AuthSession.idToken + userId internally)
      final caregiverDto = CaregiverDto(
        caregiverId: '',
        name: signupData.caregiverName,
        email: signupData.email,
        children: const [], // children NOT sent here anymore
      );

      final user = await AuthService.instance.createCaregiverAccount(
        caregiverDto: caregiverDto,
        password: signupData.password,
      );

      // 2) Save children via Backend APIs (requires Bearer token موجود في AuthSession)
      final childrenService = ChildrenService();
      final caregiverId = user.uid;

      for (final c in _childrenForms) {
        final day = (c.day ?? '').padLeft(2, '0');
        final month = (c.month ?? '').padLeft(2, '0');
        final year = c.year ?? '';
        final dateOfBirth = '$year-$month-$day';

        await childrenService.addChild(
          caregiverId: caregiverId,
          name: ProfileFieldValidation.normalizePersonName(
            c.nameController.text,
          ),
          dateOfBirth: dateOfBirth,
          gender: c.gender,
        );
      }

      // 3) Go to verify email screen
      if (mounted) {
        _submittedSuccessfully = true;
        RegistrationFlowCache.clearCaregiver();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const VerifyEmailView()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      final String message;
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم بالفعل بحساب آخر.';
      } else if (e is SocketException || e is TimeoutException) {
        message =
            'الخادم لا يستجيب أو لا يوجد اتصال. تحقق من الإنترنت وحاول مرة أخرى.';
      } else {
        message =
            'تعذر إنشاء الحساب أو حفظ بيانات الأطفال، تأكد من أنك متصل بالشبكة وحاول مرة أخرى.';
      }

      setState(() => _submitError = message);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreateEnabled = _allChildrenComplete() && !_isSubmitting;

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
          body: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 30, 22, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              onPressed: _popStep2,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                ' أضف طفلًا واحدًا للمتابعة',
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

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: BColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'لتجربة ممتعة داخل بوح، يجب تسجيل طفل واحد كحدّ أدنى.\n'
                          'الحد الأدنى لعمر الطفل هو 6 سنوات، و الحد الأقصى للطفل 13 سنة، ويمكنك إضافة حتى 5 أطفال.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: BColors.textDarkestBlue
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _childrenForms.length,
                        itemBuilder: (context, index) {
                          final child = _childrenForms[index];
                          final canDelete = _childrenForms.length > 1;
                          final nameError = child.nameTouched
                              ? ProfileFieldValidation.childDisplayName(
                                  child.nameController.text,
                                )
                              : null;
                          final dateOfBirthError =
                              _validateChildDateOfBirth(child);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (canDelete)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: IconButton(
                                      tooltip: 'حذف الطفل',
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: BColors.darkGrey,
                                        size: 22,
                                      ),
                                      onPressed: () => _removeChild(index),
                                    ),
                                  ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _requiredFieldLabel('اسم الطفل'),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: child.nameController,
                                  focusNode: child.nameFocusNode,
                                  keyboardType: TextInputType.name,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: BColors.textDarkestBlue,
                                  ),
                                  decoration: _inputDecoration(),
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(
                                      ProfileFieldValidation
                                          .childDisplayNameMaxLength,
                                    ),
                                  ],
                                  onChanged: (_) => setState(() {
                                    child.nameTouched = true;
                                  }),
                                ),
                                if (nameError != null) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      nameError,
                                      style: const TextStyle(
                                        color: BColors.validationError,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _requiredFieldLabel('جنس الطفل'),
                                ),
                                const SizedBox(height: 8),
                                _GenderSegment(
                                  value: child.gender,
                                  onChanged: (v) =>
                                      setState(() => child.gender = v),
                                ),
                                const SizedBox(height: 14),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _requiredFieldLabel('تاريخ الميلاد'),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _DropdownBox(
                                        hint: 'يوم',
                                        value: child.day,
                                        items: _daysFor(
                                          child.month != null
                                              ? int.tryParse(child.month!)
                                              : null,
                                          child.year != null
                                              ? int.tryParse(child.year!)
                                              : null,
                                        ),
                                        onChanged: (v) =>
                                            setState(() => child.day = v),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _DropdownBox(
                                        hint: 'شهر',
                                        value: child.month,
                                        items: _months,
                                        onChanged: (v) {
                                          setState(() {
                                            child.month = v;
                                            _clearDayIfInvalidForMonthYear(
                                              child,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _DropdownBox(
                                        hint: 'سنة',
                                        value: child.year,
                                        items: _years,
                                        onChanged: (v) {
                                          setState(() {
                                            child.year = v;
                                            _clearDayIfInvalidForMonthYear(
                                              child,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (dateOfBirthError != null) ...[
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      dateOfBirthError,
                                      style: const TextStyle(
                                        color: BColors.validationError,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],

                                if (index != _childrenForms.length - 1) ...[
                                  const SizedBox(height: 18),
                                  const Divider(
                                    thickness: 1,
                                    color: BColors.grey,
                                  ),
                                  const SizedBox(height: 18),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      if (_canShowAddButton()) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _addAnotherChild,
                            icon: const Icon(
                              Icons.add_circle_outline_rounded,
                              color: BColors.primary,
                            ),
                            label: const Text(
                              'إضافة طفل آخر',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: BColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isCreateEnabled ? _submitAll : null,
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

              if (_isSubmitting) const BouhLoadingOverlay(),
            ],
          ),
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

Widget _requiredFieldLabel(String label) {
  return RichText(
    text: TextSpan(
      style: const TextStyle(
        fontSize: 14,
        color: BColors.textDarkestBlue,
      ),
      children: [
        TextSpan(text: label),
        const TextSpan(
          text: ' *',
          style: TextStyle(color: BColors.validationError),
        ),
      ],
    ),
  );
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : BColors.darkGrey,
          ),
        ),
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownBox({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
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
    );
  }
}
