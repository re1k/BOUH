import 'dart:convert';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bouh/View/Profile/ChildrenManagementView.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/config/api_config.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';

class CaregiverAccountView extends StatefulWidget {
  const CaregiverAccountView({
    super.key,
    this.currentIndex = 3,
    this.onTap,
    this.onCaregiverNameSynced,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  //Called after name is loaded or saved so the home greeting can refresh.
  final VoidCallback? onCaregiverNameSynced;

  @override
  State<CaregiverAccountView> createState() => _CaregiverAccountViewState();
}

class _CaregiverAccountViewState extends State<CaregiverAccountView> {
  static const double _kControlHeight = 56;
  static const double _kControlRadius = 10;
  static const String _profileLoadFallbackErrorMessage =
      'حدث خطأ في استرجاع البيانات، تأكد من اتصالك بالشبكة وحاول مرة اخرى';
  static final RegExp _nameArabicOrEnglishRegex = RegExp(
    r'^[A-Za-z\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\s]+$',
  );

  final TextEditingController _nameCtrl = TextEditingController();
  String _name = '';
  String _email = '';
  bool _loadingProfile = true;
  bool _savingName = false;
  String? _deleteError;
  String? _profileError;
  String? _nameError;
  bool _isDeletingAccount = false;
  bool get _hasNameChanged => _nameCtrl.text.trim() != _name.trim();

  @override
  void initState() {
    super.initState();
    _loadCaregiverProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/ProfileBackground.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),

                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        _settingsCard(
                          children: [
                            _settingsItem(
                              title: 'المعلومات الشخصية',
                              titleColor: BColors.textDarkestBlue,
                              icon: Icons.person_outline_rounded,
                              iconColor: BColors.primary,
                              showChevron: true,
                              onTap: () => _openPersonalInfoPage(context),
                            ),
                            _childrenManagementItem(context),
                          ],
                        ),
                        if (_profileError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _profileError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: BColors.validationError,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const Spacer(),
                        _settingsCard(
                          children: [
                            _settingsItem(
                              title: 'تسجيل الخروج',
                              titleColor: BColors.validationError,
                              icon: Icons.logout,
                              iconColor: BColors.validationError,
                              onTap: () => _handleLogout(context),
                            ),
                          ],
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

                        const SizedBox(height: 250),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isDeletingAccount || _loadingProfile) BouhLoadingOverlay(),
          ],
        ),
        bottomNavigationBar: widget.onTap != null
            ? Material(
                clipBehavior: Clip.none,
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: CaregiverBottomNav(
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap!,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await ConfirmationPopup.show(
      context,
      title: 'تسجيل الخروج',
      message: 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      confirmText: 'تسجيل الخروج',
      cancelText: 'إلغاء',
      isDestructive: true,
    );
    if (!confirmed) return;

    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
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
      if (!mounted) return;
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDeletingAccount = false;
        _deleteError = 'تعذر حذف الحساب. حاول مرة أخرى.';
      });
    }
  }

  Future<void> _openPersonalInfoPage(BuildContext context) async {
    setState(() {
      _nameError = null;
      _nameCtrl.text = _name;
    });
    var pageEditingName = false;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setPage) => Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: BColors.textDarkestBlue,
                  ),
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    await Future.delayed(const Duration(milliseconds: 160));
                    if (!context.mounted) return;
                    setState(() {
                      _nameError = null;
                      _nameCtrl.text = _name;
                    });
                    Navigator.of(context).pop();
                  },
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
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionFieldItem(
                        label: 'البريد الالكتروني',
                        child: _field(
                          text: _email.isEmpty ? '—' : _email,
                          textColor: BColors.darkGrey,
                          backgroundColor: const Color(0xFFF5F5F5),
                        ),
                      ),
                      _sectionFieldItem(
                        label: 'الاسم',
                        child: Container(
                          height: _kControlHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_kControlRadius),
                            border: Border.all(color: Colors.black.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameCtrl,
                                  readOnly: !pageEditingName || _savingName,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: '—',
                                  ),
                                  onChanged: (_) {
                                    setState(() {
                                      if (_nameError != null) _nameError = null;
                                    });
                                    setPage(() {});
                                  },
                                ),
                              ),
                              if (pageEditingName) ...[
                                if (_savingName)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: BouhOvalLoadingIndicator(
                                      width: 30,
                                      height: 20,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                else ...[
                                  IconButton(
                                    onPressed: !_hasNameChanged
                                        ? null
                                        : () async {
                                            await _saveNameInline();
                                            if (!mounted) return;
                                            if (_nameError == null) {
                                              pageEditingName = false;
                                            }
                                            setPage(() {});
                                          },
                                    icon: Icon(
                                      Icons.check,
                                      color: _hasNameChanged
                                          ? BColors.primary
                                          : BColors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _nameError = null;
                                        _nameCtrl.text = _name;
                                      });
                                      pageEditingName = false;
                                      setPage(() {});
                                    },
                                    icon: const Icon(Icons.close, color: Colors.grey),
                                  ),
                                ],
                              ] else
                                _editIcon(
                                  onTap: () {
                                    pageEditingName = true;
                                    setState(() {
                                      _nameError = null;
                                      _nameCtrl.text = _name;
                                    });
                                    setPage(() {});
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (_nameError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _nameError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: BColors.validationError,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
              ),
              bottomNavigationBar: SafeArea(
                minimum: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isDeletingAccount
                        ? null
                        : () => _handleDeleteAccount(context),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: BColors.destructiveError,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text(
                      'حذف الحساب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _nameError = null;
      _nameCtrl.text = _name;
    });
  }

  Uri _url(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> _authHeaders({bool json = false}) {
    final token = AuthSession.instance.idToken;
    if (token == null || token.isEmpty) {
      throw StateError('No JWT (idToken). User not logged in.');
    }
    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _fetchProfileMap() async {
    var res = await http.get(
      _url('/api/accounts/profile'),
      headers: _authHeaders(json: true),
    );

    if (res.statusCode == 401) {
      await AuthService.instance.refreshSession();
      res = await http.get(
        _url('/api/accounts/profile'),
        headers: _authHeaders(json: true),
      );
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('UNAUTHORIZED');
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        res.body.isNotEmpty ? res.body : 'Failed to load caregiver profile',
      );
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _loadCaregiverProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final map = await _fetchProfileMap();
      if (!mounted) return;
      setState(() {
        _email = map['email']?.toString() ?? '';
        _name = map['name']?.toString() ?? '';
        _nameCtrl.text = _name;
        _loadingProfile = false;
      });
      await AuthSession.instance.updateCachedUserName(_name);
      if (!mounted) return;
      widget.onCaregiverNameSynced?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingProfile = false;
        _profileError = _profileLoadFallbackErrorMessage;
      });
    }
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'يرجى إدخال الاسم';
    if (!_nameArabicOrEnglishRegex.hasMatch(trimmed)) {
      return 'يرجى إدخال الاسم بحروف عربية أو إنجليزية فقط';
    }
    return null;
  }

  Future<void> _saveNameInline() async {
    final candidate = _nameCtrl.text.trim();
    final validation = _validateName(candidate);
    if (validation != null) {
      setState(() => _nameError = validation);
      return;
    }
    if (candidate == _name) {
      return;
    }

    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      var res = await http.patch(
        _url('/api/accounts/caregiver/update'),
        headers: _authHeaders(json: true),
        body: jsonEncode({'name': candidate}),
      );

      if (res.statusCode == 401) {
        await AuthService.instance.refreshSession();
        res = await http.patch(
          _url('/api/accounts/caregiver/update'),
          headers: _authHeaders(json: true),
          body: jsonEncode({'name': candidate}),
        );
      }

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Failed to update caregiver name');
      }

      if (!mounted) return;
      setState(() {
        _name = candidate;
      });
      await AuthSession.instance.updateCachedUserName(candidate);
      if (!mounted) return;
      widget.onCaregiverNameSynced?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nameError = 'تعذر تحديث الاسم. حاول مرة أخرى.';
      });
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  static Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black.withOpacity(0.45),
      ),
    );
  }

  Widget _field({
    required String text,
    Widget? trailing,
    Color textColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) {
    return Container(
      height: _kControlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_kControlRadius),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  static Widget _editIcon({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.1)),
        ),
        child: const Icon(Icons.edit, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(_kControlRadius),
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
            if (i > 0) Divider(height: 1, color: BColors.grey.withOpacity(0.5)),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _settingsItem({
    required String title,
    required Color titleColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    bool showChevron = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: _kControlHeight,
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const Spacer(),
                if (showChevron)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: BColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionFieldItem({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label(label),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _childrenManagementItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ChildrenManagementView(),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: _kControlHeight,
            child: Row(
              children: const [
                Icon(Icons.family_restroom, size: 20, color: BColors.primary),
                SizedBox(width: 10),
                Text(
                  "ادارة الاطفال",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BColors.textDarkestBlue,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: BColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
