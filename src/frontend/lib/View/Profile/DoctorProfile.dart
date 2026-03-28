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

  /// Active bottom nav index (2 = profile). Pass when used inside [DoctorNavbar].
  final int currentIndex;

  /// Called when a bottom nav item is tapped. Pass when used inside [DoctorNavbar].
  final ValueChanged<int>? onTap;

  // TODO(next stage): implement DB update + image upload, then store returned image URL/path
  final Future<void> Function({
    required String email,
    required String name,
    required String iban,
    required String specNo,
    required String experience,
    required String specialty,
    required String qualificationsText,
    required String gender,
    File? pickedImage,
  })?
  onSave;

  // TODO(next stage): implement logout (clear session/token + navigate to login)
  final Future<void> Function()? onLogout;

  @override
  State<DoctorProfileView> createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  final ProfileService _profileService = ProfileService();

  bool _isEditing = false;
  String? _deleteError;
  bool _isDeletingAccount = false;
  Timer? _deleteErrorTimer;

  bool _loadingProfile = true;
  bool _saving = false;
  String? _loadError;
  String? _saveError;

  /// Signed photo URL from GET profile (display).
  String? _photoUrl;
  int? _yearsOfExperience;

  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _specNoCtrl;
  late final TextEditingController _areaCtrl;

  /// Same pattern as doctor registration step 2: one field per qualification (1–12).
  final List<TextEditingController> _qualificationCtrls = [];
  final List<FocusNode> _qualificationFocusNodes = [];
  String? _qualificationsError;
  bool _qualificationsTouched = false;

  late String _gender;

  File? _pickedImageFile;
  late final String _defaultAvatarAsset;

  final ImagePicker _picker = ImagePicker();

  static final List<int> _experienceYears = List.generate(50, (i) => i + 1);

  static const int _minQualifications = 1;
  static const int _maxQualifications = 12;
  static const int _qualMaxLength = 70;

  static final RegExp _arabicOnlyRegex = RegExp(
    r'^[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF\s]+$',
  );

  @override
  void initState() {
    super.initState();

    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _ibanCtrl = TextEditingController(text: widget.initialIban ?? '');
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
        widget.defaultAvatarAsset ?? 'assets/images/doctor.jpg';

    final exp = int.tryParse(widget.initialExperience ?? '');
    if (exp != null && _experienceYears.contains(exp)) {
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

  /// Rebuilds qualification fields from server (or initial) data.
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
      if (!_arabicOnlyRegex.hasMatch(s)) {
        return 'يرجى إدخال المؤهلات باللغة العربية فقط';
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

  String _qualificationsTextForCallback() {
    return _qualificationsForSubmit().join('\n');
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

  Widget _buildQualificationsEditor() {
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
                    keyboardType: TextInputType.text,
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
                    },
                  ),
                ),
                if (_qualificationCtrls.length > _minQualifications) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _removeQualificationRow(i),
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
                onPressed: _addQualificationRow,
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

  Future<void> _loadProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingProfile = true;
        _loadError = null;
      });
    }
    try {
      final p = await _profileService.fetchDoctorProfile();
      if (!mounted) return;
      _replaceQualificationEditors(p.qualifications);
      setState(() {
        _emailCtrl.text = p.email ?? '';
        _nameCtrl.text = p.name ?? '';
        _ibanCtrl.text = p.iban ?? '';
        _specNoCtrl.text = p.scfhsNumber ?? '';
        _areaCtrl.text = p.areaOfKnowledge ?? '';
        final g = (p.gender ?? '').toLowerCase();
        _gender = (g == 'female' || g == 'f' || g == 'أنثى') ? 'female' : 'male';
        _yearsOfExperience = p.yearsOfExperience;
        if (_yearsOfExperience != null &&
            !_experienceYears.contains(_yearsOfExperience)) {
          _yearsOfExperience = null;
        }
        _photoUrl = p.profilePhotoURL?.trim();
        if (!silent) _pickedImageFile = null;
        if (!silent) _loadingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) {
          _loadingProfile = false;
          _loadError = e.toString();
        }
      });
    }
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
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

  Future<void> _save() async {
    if (widget.onSave != null) {
      setState(() {
        _qualificationsTouched = true;
        _qualificationsError = _validateQualificationsList();
      });
      if (_qualificationsError != null) return;

      await widget.onSave!(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        iban: _ibanCtrl.text.trim(),
        specNo: _specNoCtrl.text.trim(),
        experience: _yearsOfExperience?.toString() ?? '',
        specialty: _areaCtrl.text.trim(),
        qualificationsText: _qualificationsTextForCallback(),
        gender: _gender,
        pickedImage: _pickedImageFile,
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      return;
    }

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _saveError = 'الرجاء إدخال الاسم');
      return;
    }

    setState(() {
      _qualificationsTouched = true;
      _qualificationsError = _validateQualificationsList();
      _saveError = null;
    });
    if (_qualificationsError != null) {
      return;
    }

    setState(() => _saving = true);

    try {
      String? newStoragePath;
      if (_pickedImageFile != null) {
        final uploadedPath =
            await _uploadDoctorProfilePhotoToStorage(_pickedImageFile!);
        if (uploadedPath.isEmpty) {
          throw Exception('تعذر رفع صورة الملف الشخصي');
        }
        newStoragePath = uploadedPath;
      }

      final qualLines = _qualificationsForSubmit();

      final dto = DoctorUpdateDto(
        name: name,
        gender: _gender,
        qualifications: qualLines,
        yearsOfExperience: _yearsOfExperience,
        profilePhotoURL: newStoragePath,
        iban: _ibanCtrl.text.trim(),
      );

      final result = await _profileService.updateDoctor(dto);
      if (!result.success) {
        throw Exception(result.message ?? 'فشل تحديث الملف الشخصي');
      }

      // Refetch profile so `profilePhotoURL` is a fresh signed URL from the backend.
      await _loadProfile(silent: true);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _pickedImageFile = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isImagePath(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp') ||
        p.endsWith('.heic');
  }

  /// Same storage path contract as registration: Firebase object path for backend `profilePhotoURL`.
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
    if (!_isEditing) return;

    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;
    if (!_isImagePath(picked.path)) return;

    setState(() => _pickedImageFile = File(picked.path));
  }

  Widget _editDropdownField(
    BuildContext context, {
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
            dropdownColor: BColors.white,
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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

  Widget _buildAvatarImage() {
    const double size = 120;
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

  @override
  Widget build(BuildContext context) {
    final String? yearsDropdownValue = _yearsOfExperience != null
        ? '${_yearsOfExperience}'
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: widget.onTap != null
                  ? DoctorBottomNav.barHeight - 50
                  : 3,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 150,
                        width: double.infinity,
                        color: const Color(0xFF5E8FA4),
                      ),
                      Positioned.fill(
                        child: ClipPath(
                          clipper: WhiteCurveClipper(),
                          child: Container(color: BColors.white),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 12,
                        child: InkWell(
                          onTap: () async {
                            await _confirmAndLogout();
                          },
                          child: Row(
                            children: [
                            const SizedBox(height: 40),
                              Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.rotationY(3.141592653589793),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: GestureDetector(
                            onTap: _isEditing ? _pickDoctorImage : null,
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
                                    radius: 60,
                                    backgroundColor: BColors.white,
                                    child: _buildAvatarImage(),
                                  ),
                                ),
                                if (_isEditing)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: BColors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: BColors.grey),
                                        boxShadow: [
                                          BoxShadow(
                                            blurRadius: 8,
                                            color: Colors.black.withOpacity(
                                              0.10,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 16,
                                        color: BColors.darkGrey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 170,
                        left: 22,
                        child: InkWell(
                          onTap: _toggleEdit,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: BColors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: BColors.grey),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black.withOpacity(0.10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _isEditing
                                  ? Icons.close_rounded
                                  : Icons.edit_outlined,
                              size: 18,
                              color: BColors.darkGrey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                      _label('البريد الإلكتروني'),
                      _viewField(_emailCtrl.text),

                      _label('الاسم'),
                      _isEditing
                          ? _editField(_nameCtrl)
                          : _viewField(_nameCtrl.text),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: BColors.darkGrey,
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
                        )
                      else
                        _label('المؤهلات'),
                      if (_isEditing) const SizedBox(height: 8),
                      _isEditing
                          ? _buildQualificationsEditor()
                          : _viewQualificationsList(_qualificationsForSubmit()),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _label('رقم الايبان'),
                      _isEditing
                          ? _editField(_ibanCtrl)
                          : _viewField(_ibanCtrl.text),

                      _label('رقم التخصص'),
                      _isEditing
                          ? _editField(_specNoCtrl)
                          : _viewField(_specNoCtrl.text),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('مجال المعرفة'),
                                _viewField(_areaCtrl.text),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('سنوات الخبرة'),
                                _isEditing
                                    ? _editDropdownField(
                                        context,
                                        value: yearsDropdownValue,
                                        items: _experienceYears
                                            .map((e) => '$e')
                                            .toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(
                                            () => _yearsOfExperience =
                                                int.tryParse(v),
                                          );
                                        },
                                      )
                                    : _viewField(
                                        _yearsOfExperience != null
                                            ? '${_yearsOfExperience}'
                                            : '',
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      _label('الجنس'),
                      const SizedBox(height: 8),
                      _isEditing
                          ? _genderEditable(
                              selected: _gender,
                              onChanged: (v) => setState(() => _gender = v),
                            )
                          : _genderReadOnly(selected: _gender),

                      const SizedBox(height: 14),

                      if (_saveError != null) ...[
                        const SizedBox(height: 8),
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

                      if (_isEditing)
                        Center(
                          child: SizedBox(
                            width: 220,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: (_loadingProfile || _saving)
                                  ? null
                                  : _save,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: BColors.secondary,
                                foregroundColor: BColors.textDarkestBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'حفظ التعديلات',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 80),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _isDeletingAccount
                                    ? null
                                    : () => _handleDeleteAccount(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE4573D),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'حذف الحساب',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            if (_deleteError != null) ...[
                              const SizedBox(height: 8),
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
                          ],
                        ),
                      ),
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

  static Widget _viewField(String value) => Container(
    height: 46,
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BColors.grey),
      color: BColors.white,
    ),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: BColors.textDarkestBlue,
      ),
    ),
  );

  static Widget _editField(TextEditingController c) => Container(
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
      textAlign: TextAlign.right,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: BColors.textDarkestBlue,
      ),
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
    ),
  );

  static Widget _viewQualificationsList(List<String> items) {
    if (items.isEmpty) {
      return _viewField('—');
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BColors.grey),
        color: BColors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 14,
                        color: BColors.textDarkestBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 13,
                          color: BColors.textDarkestBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

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

    const startY = 115.0;
    const peakY = 35.0;

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
