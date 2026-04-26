import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/HomePage/widgets/doctorBottomNav.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:bouh/services/profileService.dart';
import 'package:bouh/dto/doctorUpdateDto.dart';

const TextStyle _kProfileFieldValueStyle = TextStyle(
  fontFamily: 'Markazi Text',
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: BColors.textDarkestBlue,
);

class DoctorProfileView extends StatefulWidget {
  const DoctorProfileView({
    super.key,
    this.initialEmail,
    this.initialName,
    this.initialIban,
    this.initialSpecNo,
    this.initialExperience,
    this.initialSpecialty,
    this.initialQualificationsText,
    this.initialGender,
    this.defaultAvatarAsset,
    this.onSave,
    this.onLogout,
    this.onProfileChanged,
    this.currentIndex = 2,
    this.onTap,
  });

  final String? initialEmail;
  final String? initialName;
  final String? initialIban;
  final String? initialSpecNo;
  final String? initialExperience;
  final String? initialSpecialty;
  final String? initialQualificationsText;
  final String? initialGender;

  final String? defaultAvatarAsset;

  final int currentIndex;
  final ValueChanged<int>? onTap;

  final Future<void> Function({
    required String email,
    required String name,
    required String iban,
    required String specNo,
    required String experience,
    required String specialty,
    required List<String> qualifications,
    required String gender,
    File? pickedImage,
  })?
  onSave;

  final Future<void> Function()? onLogout;
  final void Function({String? name, String? photoUrl})? onProfileChanged;

  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  final ProfileService _profileService = ProfileService();

  String? _deleteError;
  bool _isDeletingAccount = false;
  Timer? _deleteErrorTimer;

  bool _loadingProfile = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  String? _photoUrl;
  int? _yearsOfExperience;

  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _specNoCtrl;
  late final TextEditingController _areaCtrl;

  final List<TextEditingController> _qualificationCtrls = [];
  final List<FocusNode> _qualificationFocusNodes = [];
  String? _qualificationsError;
  bool _qualificationsTouched = false;

  late String _gender;

  File? _pickedImageFile;
  late final String _defaultAvatarAsset;

  final ImagePicker _picker = ImagePicker();

  static const List<String> _experienceYearDropdownLabels = [
    '1',
    '2',
    '3',
    '4',
    '+5',
  ];

  static const int _minQualifications = 1;
  static const int _maxQualifications = 12;
  static const int _qualMaxLength = 70;

  static const double _kSaveButtonsLeftPadding = 15;
  static const double _kAppBarEditTrailingPadding = 15;

  static final RegExp _qualificationsTextRegex = RegExp(
    r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF0-9\s]+$',
  );

  static const String _doctorNameHonorificPrefix = 'د. ';

  static final RegExp _arabicNameOnlyRegex = RegExp(
    r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s]+$',
  );

  static String _nameWithoutHonorificPrefix(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.startsWith(_doctorNameHonorificPrefix)) {
      return trimmed.substring(_doctorNameHonorificPrefix.length).trim();
    }
    return trimmed;
  }

  static String _ibanSuffixFromStored(String? iban) {
    if (iban == null || iban.trim().isEmpty) return '';
    var s = iban.trim().replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (s.startsWith('SA')) s = s.substring(2);
    return s.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _fullIbanFromSuffix(String suffixDigits) {
    final d = suffixDigits.trim().replaceAll(RegExp(r'\s'), '');
    return 'SA$d';
  }

  static String? _normalizePhotoUrl(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return null;
    return v;
  }

  static int? _parseExperienceYearsLabel(String? v) {
    if (v == null) return null;
    if (v == '+5') return 5;
    return int.tryParse(v);
  }

  static String? _experienceYearsToDropdownValue(int? y) {
    if (y == null || y < 1) return null;
    if (y <= 4) return '$y';
    if (y == 5) return '+5';
    return null;
  }

  static String _formatExperienceYearsReadOnly(int? y) {
    if (y == null || y < 1) return '';
    if (y <= 4) return '$y';
    if (y == 5) return '+5';
    return '$y';
  }

  static bool _isAllowedProfileYearsOfExperience(int? y) =>
      y != null && y >= 1 && y <= 5;

  String _userFriendlyError(Object error) {
    final raw = error.toString().trim();
    const prefixes = <String>[
      'Exception:',
      'StateError:',
      'FormatException:',
    ];
    for (final prefix in prefixes) {
      if (raw.startsWith(prefix)) {
        return raw.substring(prefix.length).trim();
      }
    }
    return raw;
  }

  String? _validateDoctorNameLikeRegistration(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    final userPart = trimmed.startsWith(_doctorNameHonorificPrefix)
        ? trimmed.substring(_doctorNameHonorificPrefix.length).trim()
        : trimmed;
    if (userPart.isEmpty) {
      return 'يرجى إدخال الاسم';
    }
    if (!_arabicNameOnlyRegex.hasMatch(userPart)) {
      return 'يرجى إدخال الاسم باللغة العربية فقط';
    }
    return null;
  }

  String? _validateIbanSuffix(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'يرجى إدخال صيغة آيبان صحيحة';
    }
    final digits = raw.trim().replaceAll(RegExp(r'\s'), '');
    if (digits.length != 22 || !RegExp(r'^[0-9]{22}$').hasMatch(digits)) {
      return 'يجب إدخال صيغة آيبان صحيحة';
    }
    return null;
  }

  String _ibanReadOnlyDisplay() {
    final d = _ibanCtrl.text.trim();
    if (d.isEmpty) return '';
    return _fullIbanFromSuffix(d);
  }

  @override
  void initState() {
    super.initState();

    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _nameCtrl = TextEditingController(
      text: _nameWithoutHonorificPrefix(widget.initialName),
    );
    _ibanCtrl = TextEditingController(
      text: _ibanSuffixFromStored(widget.initialIban),
    );
    _specNoCtrl = TextEditingController(text: widget.initialSpecNo ?? '');
    _areaCtrl = TextEditingController(text: widget.initialSpecialty ?? '');

    final initialQ = widget.initialQualificationsText
            ?.split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    _replaceQualificationEditors(initialQ);

    _gender = widget.initialGender ?? 'male';
    _defaultAvatarAsset =
        (widget.defaultAvatarAsset ?? 'assets/images/default_ProfileImage.png')
            .trim();

    final exp = int.tryParse(widget.initialExperience ?? '');
    if (exp != null) {
      _yearsOfExperience = exp;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  @override
  void dispose() {
    _deleteErrorTimer?.cancel();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    _specNoCtrl.dispose();
    _areaCtrl.dispose();
    _disposeQualificationEditors();
    super.dispose();
  }

  void _disposeQualificationEditors() {
    for (final c in _qualificationCtrls) {
      c.dispose();
    }
    for (final f in _qualificationFocusNodes) {
      f.dispose();
    }
    _qualificationCtrls.clear();
    _qualificationFocusNodes.clear();
  }

  void _appendQualificationEditor(String initialText) {
    final ctrl = TextEditingController(text: initialText);
    final focusNode = FocusNode();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _qualificationsTouched = true;
        _qualificationsError = _validateQualificationsList();
        if (mounted) setState(() {});
      }
    });
    _qualificationCtrls.add(ctrl);
    _qualificationFocusNodes.add(focusNode);
  }

  void _replaceQualificationEditors(List<String> qualifications) {
    _disposeQualificationEditors();
    _qualificationsError = null;
    _qualificationsTouched = false;
    final trimmed =
        qualifications.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (trimmed.isEmpty) {
      _appendQualificationEditor('');
    } else {
      for (final q in trimmed) {
        _appendQualificationEditor(q);
      }
    }
  }

  void _addQualificationRow() {
    if (_qualificationCtrls.length >= _maxQualifications) return;
    setState(() {
      _appendQualificationEditor('');
      _qualificationsError = _validateQualificationsList();
    });
  }

  void _removeQualificationRow(int index) {
    if (_qualificationCtrls.length <= _minQualifications) return;
    setState(() {
      _qualificationCtrls[index].dispose();
      _qualificationFocusNodes[index].dispose();
      _qualificationCtrls.removeAt(index);
      _qualificationFocusNodes.removeAt(index);
      _qualificationsError = _validateQualificationsList();
    });
  }

  String? _validateQualificationsList() {
    final nonEmpty = _qualificationCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (nonEmpty.isEmpty) {
      return 'يرجى إدخال مؤهل واحد على الأقل';
    }
    for (final s in nonEmpty) {
      if (!_qualificationsTextRegex.hasMatch(s)) {
        return 'يرجى إدخال المؤهلات باللغة العربية';
      }
    }
    return null;
  }

  List<String> _qualificationsForSubmit() {
    return _qualificationCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  InputDecoration _qualificationsInputDecoration() {
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
        borderSide: const BorderSide(
          color: BColors.validationError,
          width: 1.5,
        ),
      ),
    );
  }

  InputDecoration _qualificationsDecorationWithCounter(
    TextEditingController ctrl,
  ) {
    return _qualificationsInputDecoration().copyWith(
      counterText: '',
      counter: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '${ctrl.text.length}/$_qualMaxLength',
          style: const TextStyle(
            fontSize: 12,
            color: BColors.darkGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildQualificationsEditor({VoidCallback? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(_qualificationCtrls.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: TextField(
                    controller: _qualificationCtrls[i],
                    focusNode: _qualificationFocusNodes[i],
                    style: _kProfileFieldValueStyle,
                    keyboardType: TextInputType.text,
                    spellCheckConfiguration:
                        SpellCheckConfiguration.disabled(),
                    decoration: _qualificationsDecorationWithCounter(
                      _qualificationCtrls[i],
                    ).copyWith(
                      hintText: 'مثال: بكالوريوس علم نفس',
                      hintStyle: const TextStyle(
                        color: BColors.darkGrey,
                        fontSize: 13,
                      ),
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    maxLength: _qualMaxLength,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_qualMaxLength),
                    ],
                    onChanged: (_) {
                      if (_qualificationsTouched) {
                        _qualificationsError = _validateQualificationsList();
                      }
                      setState(() {});
                      onChanged?.call();
                    },
                  ),
                ),
                if (_qualificationCtrls.length > _minQualifications) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      _removeQualificationRow(i);
                      onChanged?.call();
                    },
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
          );
        }),
        if (_qualificationCtrls.length < _maxQualifications)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  _addQualificationRow();
                  onChanged?.call();
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 20,
                  color: BColors.primary,
                ),
                label: const Text(
                  'إضافة مؤهل',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BColors.primary,
                  ),
                ),
              ),
            ),
          ),
        if (_qualificationsError != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _qualificationsError!,
              style: const TextStyle(
                color: BColors.validationError,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _loadProfile({
    bool silent = false,
    bool updateAvatar = true,
  }) async {
    if (!silent) {
      setState(() {
        _loadingProfile = true;
        _loadError = null;
      });
    }
    try {
      final p = await _profileService.fetchDoctorProfile();
      if (!mounted) return false;
      _replaceQualificationEditors(p.qualifications);
      setState(() {
        _emailCtrl.text = p.email ?? '';
        _nameCtrl.text = _nameWithoutHonorificPrefix(p.name);
        _ibanCtrl.text = _ibanSuffixFromStored(p.iban);
        _specNoCtrl.text = p.scfhsNumber ?? '';
        _areaCtrl.text = p.areaOfKnowledge ?? '';
        final g = (p.gender ?? '').toLowerCase();
        _gender = (g == 'female' || g == 'f' || g == 'أنثى') ? 'female' : 'male';
        _yearsOfExperience = p.yearsOfExperience;
        if (updateAvatar) {
          _photoUrl = _normalizePhotoUrl(p.profilePhotoURL);
        }
        if (!silent) _pickedImageFile = null;
        if (!silent) _loadingProfile = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        if (!silent) {
          _loadingProfile = false;
          _loadError = _userFriendlyError(e);
        }
      });
      return false;
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await ConfirmationPopup.show(
      context,
      title: 'حذف الحساب',
      message: 'هل أنت متأكد أنك تريد حذف الحساب؟ لا يمكن التراجع عن هذا.',
      confirmText: 'حذف الحساب',
      cancelText: 'إلغاء',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _deleteError = null);
    setState(() => _isDeletingAccount = true);

    try {
      await AuthService.instance.deleteAccountOnBackend();
      if(!mounted) return;
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _deleteErrorTimer?.cancel();
      setState(() {
        _isDeletingAccount = false;
        _deleteError = e as String;
      });
      // Auto-dismiss error so it does not persist.
      // Auto-dismiss error so it does not persist.
      _deleteErrorTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _deleteError = null);
        _deleteErrorTimer = null;
      });
    }
  }

  Future<void> _confirmAndLogout() async {
    final confirmed = await ConfirmationPopup.show(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      confirmText: 'تسجيل الخروج',
      cancelText: 'إلغاء',
      isDestructive: true,
    );
    if (!confirmed) return;

    if (widget.onLogout != null) {
      await widget.onLogout!();
      return;
    }
    await _handleLogout();
  }

  Future<void> _invokeOnSaveCallback() async {
    if (widget.onSave == null) return;
    setState(() {
      _qualificationsTouched = true;
      _qualificationsError = _validateQualificationsList();
    });
    if (_qualificationsError != null) return;

    final nameErr = _validateDoctorNameLikeRegistration(_nameCtrl.text);
    if (nameErr != null) {
      setState(() => _saveError = nameErr);
      return;
    }
    final ibanErr = _validateIbanSuffix(_ibanCtrl.text);
    if (ibanErr != null) {
      setState(() => _saveError = ibanErr);
      return;
    }
    if (!_isAllowedProfileYearsOfExperience(_yearsOfExperience)) {
      setState(
        () => _saveError = 'يرجى اختيار سنوات الخبرة',
      );
      return;
    }

    await widget.onSave!(
      email: _emailCtrl.text.trim(),
      name: '$_doctorNameHonorificPrefix${_nameCtrl.text.trim()}',
      iban: _fullIbanFromSuffix(_ibanCtrl.text),
      specNo: _specNoCtrl.text.trim(),
      experience: _yearsOfExperience?.toString() ?? '',
      specialty: _areaCtrl.text.trim(),
      qualifications: _qualificationsForSubmit(),
      gender: _gender,
      pickedImage: _pickedImageFile,
    );
  }

  Future<void> _savePersonal({
    required String originalName,
    required String originalIban,
    required String originalGender,
  }) async {
    if (widget.onSave != null) {
      await _invokeOnSaveCallback();
      return;
    }

    final nameBody = _nameCtrl.text.trim();
    final name = '$_doctorNameHonorificPrefix$nameBody';
    final currentIban = _ibanReadOnlyDisplay().trim();
    final currentGender = _gender;
    final hasPersonalChanges =
        name != originalName ||
        currentIban != originalIban ||
        currentGender.trim().toLowerCase() != originalGender;
    final nameErr = _validateDoctorNameLikeRegistration(name);
    if (nameErr != null) {
      setState(() => _saveError = nameErr);
      return;
    }
    final ibanErr = _validateIbanSuffix(_ibanCtrl.text);
    if (ibanErr != null) {
      setState(() => _saveError = ibanErr);
      return;
    }

    if (!hasPersonalChanges) return;

    setState(() {
      _saveError = null;
      _saving = true;
    });

    try {
      final dto = DoctorUpdateDto(
        name: name != originalName ? name : null,
        gender: currentGender.trim().toLowerCase() != originalGender
            ? currentGender
            : null,
        iban: currentIban != originalIban ? currentIban : null,
      );
      final result = await _profileService.updateDoctor(dto);
      if (!result.success) {
        throw Exception(result.message ?? 'فشل تحديث الملف الشخصي');
      }
      final refreshed = await _loadProfile(silent: true);
      if (!refreshed) {
        throw Exception('تعذر مزامنة البيانات مع الخادم، حاول مرة أخرى');
      }
      widget.onProfileChanged?.call(
        name: '$_doctorNameHonorificPrefix${_nameCtrl.text.trim()}',
        photoUrl: _photoUrl ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = _userFriendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfessional({
    required String originalQualsJoined,
    required int? originalYears,
  }) async {
    if (widget.onSave != null) {
      await _invokeOnSaveCallback();
      return;
    }

    setState(() {
      _qualificationsTouched = true;
      _qualificationsError = _validateQualificationsList();
      _saveError = null;
    });
    if (_qualificationsError != null) return;

    if (!_isAllowedProfileYearsOfExperience(_yearsOfExperience)) {
      setState(() => _saveError = 'يرجى اختيار سنوات الخبرة');
      return;
    }

    final currentQuals = _qualificationsForSubmit();
    final currentYears = _yearsOfExperience;
    final qualsChanged = currentQuals.join('\n') != originalQualsJoined;
    final yearsChanged = currentYears != originalYears;
    if (!qualsChanged && !yearsChanged) return;

    setState(() => _saving = true);

    try {
      final dto = DoctorUpdateDto(
        qualifications: qualsChanged ? currentQuals : null,
        yearsOfExperience: yearsChanged ? currentYears : null,
      );
      final result = await _profileService.updateDoctor(dto);
      if (!result.success) {
        throw Exception(result.message ?? 'فشل تحديث الملف الشخصي');
      }
      await _loadProfile(silent: true);
      widget.onProfileChanged?.call(
        name: '$_doctorNameHonorificPrefix${_nameCtrl.text.trim()}',
        photoUrl: _photoUrl ?? '',
      );
      if (qualsChanged) {
        await _showQualificationsReviewPopup();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = _userFriendlyError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showQualificationsReviewPopup() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: BColors.white,
          actionsAlignment: MainAxisAlignment.center,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: const Text(
            'تم إرسال طلب تعديل المؤهلات للمراجعة. سيتم إشعارك عند الموافقة وسيتم تحديث بياناتك تلقائيًا.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: BColors.darkGrey,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: BColors.primary,
                foregroundColor: BColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPersonalInfoPage() async {
    setState(() => _saveError = null);
    var pageGender = _gender;
    var personalEditing = false;
    var baselineNameBody = _nameCtrl.text.trim();
    var baselineIbanSuffix = _ibanCtrl.text.trim();
    var baselineGender = _gender.trim().toLowerCase();
    var personalSaved = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeCtx) {
          return StatefulBuilder(
            builder: (context, setPage) {
              final nameError = personalEditing
                  ? _validateDoctorNameLikeRegistration(
                      '$_doctorNameHonorificPrefix${_nameCtrl.text}',
                    )
                  : null;
              final ibanError = personalEditing
                  ? _validateIbanSuffix(_ibanCtrl.text)
                  : null;
              final canSavePersonal =
                  personalEditing &&
                  !_saving &&
                  !_loadingProfile &&
                  nameError == null &&
                  ibanError == null &&
                  (_nameCtrl.text.trim() != baselineNameBody ||
                      _ibanCtrl.text.trim() != baselineIbanSuffix ||
                      pageGender.trim().toLowerCase() != baselineGender);
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor: BColors.white,
                  appBar: AppBar(
                    backgroundColor: BColors.white,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: BColors.textDarkestBlue,
                      ),
                      onPressed: () => Navigator.of(routeCtx).pop(),
                    ),
                    title: const Text(
                      'المعلومات الشخصية',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: BColors.textDarkestBlue,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: _kAppBarEditTrailingPadding,
                        ),
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                personalEditing = !personalEditing;
                                setPage(() {});
                              },
                              child: _circularEditIcon(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _label('البريد الإلكتروني'),
                            _viewFieldGrey(_emailCtrl.text),
                            _label('الاسم'),
                            personalEditing
                                ? _editField(
                                    _nameCtrl,
                                    prefixText: _doctorNameHonorificPrefix,
                                    onChanged: (_) => setPage(() {}),
                                  )
                                : _readOnlyPlainField(
                                    '$_doctorNameHonorificPrefix${_nameCtrl.text.trim()}',
                                  ),
                            if (personalEditing && nameError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                nameError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BColors.validationError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            _label('الجنس'),
                            const SizedBox(height: 8),
                            personalEditing
                                ? _genderEditable(
                                    selected: pageGender,
                                    onChanged: (v) {
                                      pageGender = v;
                                      setPage(() {});
                                    },
                                  )
                                : _genderReadOnly(selected: pageGender),
                            _label('رقم الايبان'),
                            personalEditing
                                ? _buildIbanEditField(
                                    onChanged: (_) => setPage(() {}),
                                  )
                                : _readOnlyPlainField(_ibanReadOnlyDisplay()),
                            if (personalEditing && ibanError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                ibanError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BColors.validationError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_saveError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _saveError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BColors.validationError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (personalEditing) ...[
                              const SizedBox(height: 36),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: _kSaveButtonsLeftPadding,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    textDirection: TextDirection.ltr,
                                    children: [
                                      SizedBox(
                                        width: 168,
                                        height: 46,
                                        child: ElevatedButton(
                                          onPressed: !canSavePersonal
                                              ? null
                                              : () async {
                                                  setPage(() {});
                                                  setState(
                                                    () =>
                                                        _gender = pageGender,
                                                  );
                                                  await _savePersonal(
                                                    originalName:
                                                        '$_doctorNameHonorificPrefix$baselineNameBody',
                                                    originalIban:
                                                        _fullIbanFromSuffix(
                                                          baselineIbanSuffix,
                                                        ),
                                                    originalGender:
                                                        baselineGender,
                                                  );
                                                  if (_saveError == null) {
                                                    baselineNameBody = _nameCtrl
                                                        .text
                                                        .trim();
                                                    baselineIbanSuffix = _ibanCtrl
                                                        .text
                                                        .trim();
                                                    baselineGender = _gender
                                                        .trim()
                                                        .toLowerCase();
                                                    personalSaved = true;
                                                    personalEditing = false;
                                                  }
                                                  setPage(() {});
                                                },
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor: BColors.secondary,
                                            foregroundColor:
                                                BColors.textDarkestBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _saving
                                              ? const SizedBox(
                                                  width: 34,
                                                  height: 24,
                                                  child:
                                                      BouhOvalLoadingIndicator(
                                                    width: 30,
                                                    height: 20,
                                                    strokeWidth: 2.6,
                                                  ),
                                                )
                                              : const Text(
                                                  'حفظ التعديلات',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 112,
                                        height: 46,
                                        child: OutlinedButton(
                                          onPressed: _saving || _loadingProfile
                                              ? null
                                              : () async {
                                                  setState(() {
                                                    _saveError = null;
                                                    _nameCtrl.text =
                                                        baselineNameBody;
                                                    _ibanCtrl.text =
                                                        baselineIbanSuffix;
                                                    _gender = baselineGender;
                                                  });
                                                  pageGender = _gender;
                                                  personalEditing = false;
                                                  setPage(() {});
                                                },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                BColors.textDarkestBlue,
                                            side: const BorderSide(
                                              color: BColors.grey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            'إلغاء',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _isDeletingAccount
                            ? null
                            : () => _handleDeleteAccount(),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: BColors.destructiveError,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'حذف الحساب',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    if (!mounted) return;
    if (!personalSaved) {
      setState(() {
        _saveError = null;
        _nameCtrl.text = baselineNameBody;
        _ibanCtrl.text = baselineIbanSuffix;
        _gender = baselineGender;
      });
    }
  }

  Future<void> _openProfessionalInfoPage() async {
    // Always refresh from backend before opening this page so qualifications
    // reflect persisted DB state (not unsaved local edits).
    await _loadProfile(silent: true);
    if (!mounted) return;
    setState(() => _saveError = null);
    var professionalEditing = false;
    var baselineQualsList = List<String>.from(_qualificationsForSubmit());
    var baselineQuals = baselineQualsList.join('\n');
    var baselineYears = _yearsOfExperience;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeCtx) {
          return StatefulBuilder(
            builder: (context, setPage) {
              final yearsDropdownValue =
                  _experienceYearsToDropdownValue(_yearsOfExperience);
              final qualificationsError = professionalEditing
                  ? _validateQualificationsList()
                  : null;
              final yearsError =
                  professionalEditing &&
                      !_isAllowedProfileYearsOfExperience(_yearsOfExperience)
                  ? 'يرجى اختيار سنوات الخبرة'
                  : null;
              final canSaveProfessional =
                  professionalEditing &&
                  !_saving &&
                  !_loadingProfile &&
                  qualificationsError == null &&
                  yearsError == null &&
                  (_qualificationsForSubmit().join('\n') != baselineQuals ||
                      _yearsOfExperience != baselineYears);
              return Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  backgroundColor: BColors.white,
                  appBar: AppBar(
                    backgroundColor: BColors.white,
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: BColors.textDarkestBlue,
                      ),
                      onPressed: () => Navigator.of(routeCtx).pop(),
                    ),
                    title: const Text(
                      'المعلومات المهنية',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: BColors.textDarkestBlue,
                      ),
                    ),
                    centerTitle: true,
                    actions: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: _kAppBarEditTrailingPadding,
                        ),
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () async {
                                if (professionalEditing) {
                                  setState(() {
                                    _replaceQualificationEditors(
                                      baselineQualsList,
                                    );
                                    _yearsOfExperience = baselineYears;
                                    _saveError = null;
                                  });
                                } else {
                                  await _refreshProfessionalDraftFromBackend();
                                  baselineQualsList = List<String>.from(
                                    _qualificationsForSubmit(),
                                  );
                                  baselineQuals = baselineQualsList.join('\n');
                                  baselineYears = _yearsOfExperience;
                                }
                                professionalEditing = !professionalEditing;
                                setPage(() {});
                              },
                              child: _circularEditIcon(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  body: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _label('سنوات الخبرة'),
                                      professionalEditing
                                          ? _editDropdownField(
                                              routeCtx,
                                              value: yearsDropdownValue,
                                              items:
                                                  _experienceYearDropdownLabels,
                                              hintText: 'اختر عدد السنوات',
                                              onChanged: (v) {
                                                setState(
                                                  () => _yearsOfExperience =
                                                      _parseExperienceYearsLabel(
                                                        v,
                                                      ),
                                                );
                                                setPage(() {});
                                              },
                                            )
                                          : _readOnlyPlainField(
                                              _formatExperienceYearsReadOnly(
                                                _yearsOfExperience,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _label('مجال المعرفة'),
                                      _viewFieldGrey(_areaCtrl.text),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            _label('رقم التخصص'),
                            _viewFieldGrey(_specNoCtrl.text),
                            _label('المؤهلات'),
                            professionalEditing
                                ? _buildQualificationsEditor(
                                    onChanged: () => setPage(() {}),
                                  )
                                : _viewQualificationsList(
                                    _qualificationsForSubmit(),
                                  ),
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '* تعديل المؤهلات يتطلب موافقة الإدارة، وسيتم إشعارك عند اعتماد الطلب.',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: BColors.darkGrey,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ),
                            if (professionalEditing &&
                                qualificationsError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                qualificationsError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BColors.validationError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (professionalEditing && yearsError != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                yearsError,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BColors.validationError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (_saveError != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _saveError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: BColors.validationError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (professionalEditing) ...[
                              const SizedBox(height: 36),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: _kSaveButtonsLeftPadding,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    textDirection: TextDirection.ltr,
                                    children: [
                                      SizedBox(
                                        width: 168,
                                        height: 46,
                                        child: ElevatedButton(
                                          onPressed: !canSaveProfessional
                                              ? null
                                              : () async {
                                                      setPage(() {});
                                                      await _saveProfessional(
                                                        originalQualsJoined:
                                                            baselineQuals,
                                                        originalYears:
                                                            baselineYears,
                                                      );
                                                      if (_saveError == null) {
                                                        // Force a fresh backend read after submit so displayed
                                                        // qualifications always reflect persisted DB state.
                                                        await _loadProfile(
                                                          silent: true,
                                                        );
                                                        baselineQualsList =
                                                            List<String>.from(
                                                              _qualificationsForSubmit(),
                                                            );
                                                        baselineQuals =
                                                            baselineQualsList
                                                                .join('\n');
                                                        baselineYears =
                                                            _yearsOfExperience;
                                                        professionalEditing =
                                                            false;
                                                      }
                                                      setPage(() {});
                                                    },
                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,
                                            backgroundColor:
                                                BColors.secondary,
                                            foregroundColor:
                                                BColors.textDarkestBlue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: _saving
                                              ? const SizedBox(
                                                  width: 34,
                                                  height: 24,
                                                  child:
                                                      BouhOvalLoadingIndicator(
                                                    width: 30,
                                                    height: 20,
                                                    strokeWidth: 2.6,
                                                  ),
                                                )
                                              : const Text(
                                                  'حفظ التعديلات',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        width: 112,
                                        height: 46,
                                        child: OutlinedButton(
                                          onPressed:
                                              _saving || _loadingProfile
                                                  ? null
                                                  : () async {
                                                      setState(
                                                        () {
                                                            _replaceQualificationEditors(
                                                              baselineQualsList,
                                                            );
                                                            _yearsOfExperience =
                                                                baselineYears;
                                                            _saveError = null;
                                                          },
                                                      );
                                                      professionalEditing =
                                                          false;
                                                      setPage(() {});
                                                    },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                BColors.textDarkestBlue,
                                            side: const BorderSide(
                                              color: BColors.grey,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: const Text(
                                            'إلغاء',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
    if (!mounted) return;
    // Always re-sync from backend when leaving this page so the profile keeps
    // showing persisted values, not any local draft values.
    await _loadProfile(silent: true);
    if (!mounted) return;
    setState(() => _saveError = null);
  }

  Future<void> _refreshProfessionalDraftFromBackend() async {
    try {
      final p = await _profileService.fetchDoctorProfile();
      if (!mounted) return;
      setState(() {
        _replaceQualificationEditors(p.qualifications);
        _yearsOfExperience = p.yearsOfExperience;
        _saveError = null;
      });
    } catch (_) {
      // Keep current local values if refresh fails.
    }
  }

  Widget _settingsMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool danger = false,
    bool showChevron = true,
    double bottomPaddingAdjustment = 0,
  }) {
    final iconColor = danger ? BColors.validationError : BColors.primary;
    final titleColor =
        danger ? BColors.validationError : BColors.textDarkestBlue;
    final chevronColor =
        danger ? BColors.validationError.withOpacity(0.65) : BColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            14 + bottomPaddingAdjustment,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 24, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
              if (showChevron)
                Icon(Icons.chevron_right, size: 22, color: chevronColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsCard({
    required List<Widget> children,
    bool showItemDividers = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BColors.grey.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (showItemDividers && i > 0)
              Divider(height: 1, color: BColors.grey.withOpacity(0.5)),
            children[i],
          ],
        ],
      ),
    );
  }

  bool _isImagePath(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp') ||
        p.endsWith('.heic');
  }

  Future<String> _uploadDoctorProfilePhotoToStorage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final ref = FirebaseStorage.instance
        .ref()
        .child('doctorProfileImages')
        .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.fullPath;
  }

  Future<void> _pickDoctorImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;
    if (!_isImagePath(picked.path)) return;

    final file = File(picked.path);
    setState(() {
      _pickedImageFile = file;
      _saving = true;
      _saveError = null;
    });

    try {
      final uploadedPath = await _uploadDoctorProfilePhotoToStorage(file);
      if (uploadedPath.isEmpty) {
        throw Exception('تعذر رفع صورة الملف الشخصي');
      }
      final dto = DoctorUpdateDto(profilePhotoURL: uploadedPath);
      final result = await _profileService.updateDoctor(dto);
      if (!result.success) {
        throw Exception(result.message ?? 'فشل تحديث الصورة');
      }
      await _loadProfile(silent: true);
      widget.onProfileChanged?.call(
        name: '$_doctorNameHonorificPrefix${_nameCtrl.text.trim()}',
        photoUrl: _photoUrl ?? '',
      );
      if (!mounted) return;
      setState(() => _pickedImageFile = null);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pickedImageFile = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_userFriendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeDoctorImage() async {
    if (_saving || _loadingProfile) return;
    final confirmed = await ConfirmationPopup.show(
      context,
      title: 'حذف الصورة الشخصية',
      message: 'هل أنت متأكد أنك تريد حذف الصورة الشخصية؟',
      confirmText: 'حذف الصورة',
      cancelText: 'إلغاء',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final result = await _profileService.updateDoctor(
        DoctorUpdateDto(profilePhotoURL: 'null'),
      );
      if (!result.success) {
        throw Exception(result.message ?? 'فشل حذف الصورة');
      }
      await _loadProfile(silent: true);
      if (!mounted) return;
      setState(() {
        _pickedImageFile = null;
        _photoUrl = null;
      });
      widget.onProfileChanged?.call(
        name: '$_doctorNameHonorificPrefix${_nameCtrl.text.trim()}',
        photoUrl: '',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_userFriendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildIbanEditField({ValueChanged<String>? onChanged}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Container(
            height: 46,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BColors.grey),
              color: BColors.white,
            ),
            child: TextField(
              controller: _ibanCtrl,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              spellCheckConfiguration: SpellCheckConfiguration.disabled(),
              style: _kProfileFieldValueStyle,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(22),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
    );
  }

  Widget _editDropdownField(
    BuildContext context, {
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hintText,
  }) {
    return Container(
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
            hint: hintText == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      hintText,
                      style: _kProfileFieldValueStyle,
                    ),
                  ),
            dropdownColor: BColors.white,
            style: _kProfileFieldValueStyle,
            iconEnabledColor: BColors.textDarkestBlue,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        e,
                        style: _kProfileFieldValueStyle,
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

  Widget _buildAvatarImage() {
    const double size = 140;
    if (_pickedImageFile != null) {
      return ClipOval(
        child: Image.file(
          _pickedImageFile!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    final url = _photoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => Image.asset(
            _defaultAvatarAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.asset(
        _defaultAvatarAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _circularEditIcon({double diameter = 34}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: BColors.softGrey,
        shape: BoxShape.circle,
        border: Border.all(color: BColors.grey.withOpacity(0.45)),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            color: Colors.black.withOpacity(0.07),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.edit_outlined,
        size: diameter * 0.47,
        color: BColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
            clipBehavior: Clip.none,
            padding: EdgeInsets.only(
              bottom: widget.onTap != null
                  ? DoctorBottomNav.barHeight - 50
                  : 3,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 218,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: -50,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Image.asset(
                          'assets/images/ProfileBackground.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      Positioned(
                        top: 48,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _loadingProfile ? () {} : _pickDoctorImage,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: BColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 14,
                                        color: Colors.black.withOpacity(0.18),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 65,
                                    backgroundColor: BColors.white,
                                    child: _buildAvatarImage(),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: _circularEditIcon(diameter: 34),
                                ),
                                if (_pickedImageFile != null ||
                                    (_photoUrl != null && _photoUrl!.isNotEmpty))
                                  Positioned(
                                    bottom: 6,
                                    left: 6,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: _removeDoctorImage,
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: BColors.softGrey,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: BColors.grey.withOpacity(0.45),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                blurRadius: 6,
                                                color: Colors.black.withOpacity(0.07),
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 18,
                                            color: BColors.validationError,
                                          ),
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
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_loadError != null && !_loadingProfile) ...[
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: BColors.validationError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _loadProfile,
                            child: const Text('إعادة المحاولة'),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      _settingsCard(
                        children: [
                          _settingsMenuTile(
                            icon: Icons.person_outline_rounded,
                            title: 'المعلومات الشخصية',
                            onTap: _loadingProfile
                                ? () {}
                                : () => _openPersonalInfoPage(),
                          ),
                          _settingsMenuTile(
                            icon: Icons.work_outline_rounded,
                            title: 'المعلومات المهنية',
                            onTap: _loadingProfile
                                ? () {}
                                : () => _openProfessionalInfoPage(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 34),
                      _settingsCard(
                        children: [
                          _settingsMenuTile(
                            icon: Icons.logout_rounded,
                            title: 'تسجيل الخروج',
                            danger: true,
                            showChevron: false,
                            onTap: () => _confirmAndLogout(),
                          ),
                        ],
                      ),
                      if (_deleteError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _deleteError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: BColors.validationError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
          if (_isDeletingAccount || _loadingProfile || _saving)
            BouhLoadingOverlay(),
        ],
        ),
        bottomNavigationBar: widget.onTap != null
            ? Material(
                clipBehavior: Clip.none,
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: DoctorBottomNav(
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  static Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          color: BColors.darkGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  static Widget _viewFieldGrey(String value) => Container(
        constraints: const BoxConstraints(minHeight: 46),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BColors.grey.withOpacity(0.85)),
          color: const Color(0xFFF2F4F5),
        ),
        child: Text(
          value.isEmpty ? '—' : value,
          textAlign: TextAlign.right,
          style: _kProfileFieldValueStyle.copyWith(color: BColors.darkGrey),
        ),
      );

  static Widget _readOnlyPlainField(String value) => Container(
        height: 46,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BColors.grey),
          color: BColors.white,
        ),
        child: Text(
          value.trim().isEmpty ? '—' : value,
          textAlign: TextAlign.right,
          style: _kProfileFieldValueStyle,
        ),
      );

  static Widget _viewQualificationsList(List<String> items) {
    final sectionDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BColors.grey),
      color: BColors.white,
    );

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: sectionDecoration,
        alignment: Alignment.centerRight,
        child: Text(
          'لا توجد مؤهلات مسجّلة',
          textAlign: TextAlign.right,
          style: _kProfileFieldValueStyle.copyWith(color: BColors.darkGrey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: sectionDecoration,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: BColors.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: 'Markazi Text',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      items[i],
                      textAlign: TextAlign.right,
                      style: _kProfileFieldValueStyle.copyWith(height: 1.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static Widget _editField(
    TextEditingController c, {
    String? prefixText,
    ValueChanged<String>? onChanged,
  }) => Container(
    height: 46,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BColors.grey),
      color: BColors.white,
    ),
    child: TextField(
      controller: c,
      onChanged: onChanged,
      textAlign: TextAlign.right,
      textAlignVertical: TextAlignVertical.center,
      spellCheckConfiguration: SpellCheckConfiguration.disabled(),
      style: _kProfileFieldValueStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        prefixText: prefixText,
        prefixStyle: _kProfileFieldValueStyle,
      ),
    ),
  );

  static Widget _genderReadOnly({required String selected}) {
    final isMale = selected == 'male';
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
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMale ? BColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'ذكر',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isMale ? BColors.white : BColors.darkGrey,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: !isMale ? BColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'أنثى',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: !isMale ? BColors.white : BColors.darkGrey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _genderEditable({
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final isMale = selected == 'male';
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
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged('male'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isMale ? BColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ذكر',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isMale ? BColors.white : BColors.darkGrey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onChanged('female'),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isMale ? BColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'أنثى',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: !isMale ? BColors.white : BColors.darkGrey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhiteCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    const startY = 130.0;
    const peakY = 48.0;

    return Path()
      ..moveTo(0, startY)
      ..cubicTo(w * 0.30, startY, w * 0.55, peakY, w, startY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
