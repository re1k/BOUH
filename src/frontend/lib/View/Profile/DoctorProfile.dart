import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/HomePage/widgets/doctorBottomNav.dart';

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
  bool _isEditing = false;

  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _specNoCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _specCtrl;
  late final TextEditingController _qualCtrl;

  late String _gender;

  File? _pickedImageFile;
  late final String _defaultAvatarAsset;

  final ImagePicker _picker = ImagePicker();

  final List<String> _specialties = const ['توتر وقلق', 'خوف', 'حزن', 'تفاؤل'];
  final List<String> _yearsList = const ['1', '2', '3', '4', '5+'];

  @override
  void initState() {
    super.initState();

    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _ibanCtrl = TextEditingController(text: widget.initialIban ?? '');
    _specNoCtrl = TextEditingController(text: widget.initialSpecNo ?? '');
    _expCtrl = TextEditingController(text: widget.initialExperience ?? '');
    _specCtrl = TextEditingController(text: widget.initialSpecialty ?? '');
    _qualCtrl = TextEditingController(
      text: widget.initialQualificationsText ?? '',
    );

    _gender = widget.initialGender ?? 'male';
    _defaultAvatarAsset =
        widget.defaultAvatarAsset ?? 'assets/images/doctor.jpg';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    _specNoCtrl.dispose();
    _expCtrl.dispose();
    _specCtrl.dispose();
    _qualCtrl.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _save() async {
    if (widget.onSave != null) {
      await widget.onSave!(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        iban: _ibanCtrl.text.trim(),
        specNo: _specNoCtrl.text.trim(),
        experience: _expCtrl.text.trim(),
        specialty: _specCtrl.text.trim(),
        qualificationsText: _qualCtrl.text,
        gender: _gender,
        pickedImage: _pickedImageFile,
      );
    }

    setState(() => _isEditing = false);
  }

  bool _isImagePath(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') ||
        p.endsWith('.jpeg') ||
        p.endsWith('.png') ||
        p.endsWith('.webp') ||
        p.endsWith('.heic');
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

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarProvider = _pickedImageFile != null
        ? FileImage(_pickedImageFile!)
        : AssetImage(_defaultAvatarAsset);

    final String expText = _expCtrl.text.trim();
    final String specText = _specCtrl.text.trim();

    final String? currentYearsValue = _yearsList.contains(expText)
        ? expText
        : null;
    final String? currentSpecialtyValue = _specialties.contains(specText)
        ? specText
        : null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: widget.onTap != null
                  ? DoctorBottomNav.barHeight + 24
                  : 24,
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
                            if (widget.onLogout != null) {
                              await widget.onLogout!();
                            }
                          },
                          child: Row(
                            children: [
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
                                    backgroundImage: avatarProvider,
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
                      _label('البريد الإلكتروني'),
                      _isEditing
                          ? _editField(_emailCtrl)
                          : _viewField(_emailCtrl.text),

                      _label('الاسم'),
                      _isEditing
                          ? _editField(_nameCtrl)
                          : _viewField(_nameCtrl.text),

                      _label('المؤهلات'),
                      _isEditing
                          ? _editQualificationsBox(_qualCtrl)
                          : _viewQualificationsBox(_qualCtrl.text),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('رقم الايبان'),
                                _isEditing
                                    ? _editField(_ibanCtrl)
                                    : _viewField(_ibanCtrl.text),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('رقم التخصص'),
                                _isEditing
                                    ? _editField(_specNoCtrl)
                                    : _viewField(_specNoCtrl.text),
                              ],
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _label('التخصص'),
                                _isEditing
                                    ? _editDropdownField(
                                        context,
                                        value: currentSpecialtyValue,
                                        items: _specialties,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() => _specCtrl.text = v);
                                        },
                                      )
                                    : _viewField(_specCtrl.text),
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
                                        value: currentYearsValue,
                                        items: _yearsList,
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() => _expCtrl.text = v);
                                        },
                                      )
                                    : _viewField(_expCtrl.text),
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

                      const SizedBox(height: 18),

                      if (_isEditing)
                        Center(
                          child: SizedBox(
                            width: 220,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: _save,
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

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    padding: const EdgeInsets.only(top: 14, bottom: 6),
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

  static Widget _viewQualificationsBox(String text) {
    final items = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

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

  static Widget _editQualificationsBox(TextEditingController c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BColors.grey),
      color: BColors.white,
    ),
    child: TextField(
      controller: c,
      textAlign: TextAlign.right,
      style: const TextStyle(
        fontSize: 13,
        color: BColors.textDarkestBlue,
        fontWeight: FontWeight.w600,
      ),
      maxLines: null,
      decoration: const InputDecoration(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
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
