import 'dart:async';
import 'dart:io';

import 'package:bouh/theme/base_themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:bouh/View/Profile/ChildrenManagementView.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:bouh/widgets/profile_field_validation.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/services/profileService.dart';

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
  static const String _deleteNetworkErrorMessage =
      'لا يوجد اتصال بالإنترنت أو تعذر الوصول إلى الخادم. تحقق من الشبكة وحاول مرة أخرى.';
  static const String _upcomingCheckFailedMessage =
      'تعذر التحقق من المواعيد القادمة. حاول مرة أخرى.';
  static const String _deleteAccountBaseMessage =
      'هل أنت متأكد أنك تريد حذف الحساب؟ لا يمكن التراجع عن هذا.';
  static const String _deleteAccountWithUpcoming =
      'لديك مواعيد قادمة. '
      'يمكنك إلغاؤها أولًا لاسترداد المبلغ، '
      'أو المتابعة بالحذف وسيتم إلغاؤها دون استرداد.';
  final ProfileService _profileService = ProfileService();
  final AppointmentsService _appointmentsService = AppointmentsService();
  final TextEditingController _nameCtrl = TextEditingController();
  String _name = '';
  String _email = '';
  bool _loadingProfile = true;
  bool _savingName = false;
  String? _deleteError;
  String? _profileError;
  String? _nameError;
  bool _isDeletingAccount = false;
  bool _isDeletePreflightBusy = false;
  void Function()? _refreshCaregiverPersonalPage;
  Timer? _deleteErrorTimer;
  static const Duration _deleteErrorAutoDismiss = Duration(seconds: 5);
  bool get _hasNameChanged =>
      ProfileFieldValidation.normalizePersonName(_nameCtrl.text) !=
      ProfileFieldValidation.normalizePersonName(_name);

  void _cancelDeleteErrorTimer() {
    _deleteErrorTimer?.cancel();
    _deleteErrorTimer = null;
  }

  void _clearDeleteError() {
    _cancelDeleteErrorTimer();
    if (!mounted) return;
    if (_deleteError != null) {
      setState(() => _deleteError = null);
    }
  }

  void _showTransientDeleteError(String message) {
    _cancelDeleteErrorTimer();
    if (!mounted) return;
    setState(() => _deleteError = message);
    _deleteErrorTimer = Timer(_deleteErrorAutoDismiss, () {
      if (!mounted) return;
      setState(() => _deleteError = null);
      _deleteErrorTimer = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCaregiverProfile();
  }

  @override
  void didUpdateWidget(covariant CaregiverAccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == 3 && oldWidget.currentIndex != 3) {
      _clearDeleteError();
    }
  }

  @override
  void dispose() {
    _cancelDeleteErrorTimer();
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
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],

                        const SizedBox(height: 34),
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

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_loadingProfile) BouhLoadingOverlay(),
            if (_isDeletingAccount) BouhFullScreenLoadingOverlay(),
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
      title: 'تأكيد تسجيل الخروج',
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

  bool _isNetworkFailure(Object e) {
    return e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException;
  }

  String _messageForUpcomingFetchFailure(Object e) {
    if (_isNetworkFailure(e)) return _deleteNetworkErrorMessage;
    return _upcomingCheckFailedMessage;
  }

  String _messageForDeleteFailure(Object e) {
    if (_isNetworkFailure(e)) return _deleteNetworkErrorMessage;
    return 'تعذر حذف الحساب. حاول مرة أخرى.';
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    _clearDeleteError();

    final uid = AuthSession.instance.userId;
    if (uid == null || uid.isEmpty) {
      _showTransientDeleteError('تعذر حذف الحساب. حاول مرة أخرى.');
      return;
    }

    setState(() => _isDeletePreflightBusy = true);
    _refreshCaregiverPersonalPage?.call();

    late final List<UpcomingAppointmentDto> activeUpcoming;
    try {
      final raw = await _appointmentsService.getUpcomingAppointments(uid);
      activeUpcoming = AppointmentsService.filterUpcomingNotEnded(raw);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletePreflightBusy = false);
      _refreshCaregiverPersonalPage?.call();
      _showTransientDeleteError(_messageForUpcomingFetchFailure(e));
      return;
    }

    if (!mounted || !context.mounted) return;

    final hasUpcoming = activeUpcoming.isNotEmpty;
    final message =
        hasUpcoming ? _deleteAccountWithUpcoming : _deleteAccountBaseMessage;

    var confirmed = false;
    try {
      confirmed = await ConfirmationPopup.show(
        context,
        title: 'تأكيد حذف الحساب',
        message: message,
        confirmText: 'حذف الحساب',
        cancelText: 'إلغاء',
        isDestructive: true,
        useDarkMessageText: hasUpcoming,
        onDialogVisible: () {
          if (!mounted) return;
          setState(() => _isDeletePreflightBusy = false);
          _refreshCaregiverPersonalPage?.call();
        },
      );
    } finally {
      if (mounted && _isDeletePreflightBusy) {
        setState(() => _isDeletePreflightBusy = false);
        _refreshCaregiverPersonalPage?.call();
      }
    }
    if (!confirmed || !mounted || !context.mounted) return;

    setState(() => _isDeletingAccount = true);
    _refreshCaregiverPersonalPage?.call();

    try {
      await AuthService.instance.deleteAccountOnBackend();
      if (!mounted || !context.mounted) return;
      await AuthService.instance.signOut();
      if (!mounted || !context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginView()),
        (route) => false,
      );
    } on AccountDeleteBlockedException {
      if (!mounted || !context.mounted) return;
      setState(() => _isDeletingAccount = false);
      _refreshCaregiverPersonalPage?.call();
      await ConfirmationPopup.show(
        context,
        title: 'لا يمكن حذف الحساب',
        message: 'تعذر إكمال الحذف حالياً. حاول لاحقاً .',
        confirmText: 'حسناً',
        singleButton: true,
        useDarkMessageText: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      _refreshCaregiverPersonalPage?.call();
      _showTransientDeleteError(_messageForDeleteFailure(e));
    }
  }

  Future<void> _openPersonalInfoPage(BuildContext context) async {
    _clearDeleteError();
    setState(() {
      _nameError = null;
      _nameCtrl.text = _name;
    });
    final nameFocusNode = FocusNode();
    var nameStartedTyping = false;
    void Function()? refreshPersonalPage;
    final editingNameRef = <bool>[false];
    void onNameFocusChange() {
      if (!nameFocusNode.hasFocus && editingNameRef[0]) {
        ProfileFieldValidation.syncTextControllerToNormalizedPersonName(_nameCtrl);
        if (nameStartedTyping) {
          setState(() {
            _nameError = _validateName(_nameCtrl.text);
          });
        }
        refreshPersonalPage?.call();
      }
    }

    nameFocusNode.addListener(onNameFocusChange);
    const discardChangesMessage = 'لديك تغييرات غير محفوظة. هل تريد المغادرة؟';

    Future<bool> confirmDiscardIfNeeded() async {
      final hasUnsavedChanges = editingNameRef[0] && _hasNameChanged;
      if (!hasUnsavedChanges) return true;
      return ConfirmationPopup.show(
        context,
        title: 'تغييرات غير محفوظة',
        message: discardChangesMessage,
        confirmText: 'مغادرة',
        cancelText: 'بقاء',
      );
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StatefulBuilder(
          builder: (context, setPage) {
            refreshPersonalPage = () => setPage(() {});
            _refreshCaregiverPersonalPage = () => setPage(() {});
            return Directionality(
              textDirection: TextDirection.rtl,
              child: WillPopScope(
                onWillPop: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await Future.delayed(const Duration(milliseconds: 160));
                  if (!context.mounted) return false;
                  final shouldDiscard = await confirmDiscardIfNeeded();
                  if (!shouldDiscard) return false;
                  setState(() {
                    _nameError = null;
                    _nameCtrl.text = _name;
                  });
                  return true;
                },
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
                        final shouldDiscard = await confirmDiscardIfNeeded();
                        if (!shouldDiscard || !context.mounted) return;
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
                  body: Stack(
                    children: [
                      SafeArea(
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      _kControlRadius,
                                    ),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nameCtrl,
                                          focusNode: nameFocusNode,
                                          readOnly:
                                              !editingNameRef[0] || _savingName,
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(
                                              ProfileFieldValidation
                                                  .caregiverOrDoctorNameMaxLength,
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: InputBorder.none,
                                            hintText: '—',
                                          ),
                                          onChanged: (_) {
                                            nameStartedTyping = true;
                                            setState(() {
                                              _nameError = _validateName(
                                                _nameCtrl.text,
                                              );
                                            });
                                            setPage(() {});
                                          },
                                        ),
                                      ),
                                      if (editingNameRef[0]) ...[
                                        if (_savingName)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
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
                                                      editingNameRef[0] = false;
                                                      nameStartedTyping = false;
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
                                            onPressed: () async {
                                              final shouldDiscard =
                                                  await confirmDiscardIfNeeded();
                                              if (!shouldDiscard) return;
                                              setState(() {
                                                _nameError = null;
                                                _nameCtrl.text = _name;
                                              });
                                              editingNameRef[0] = false;
                                              nameStartedTyping = false;
                                              setPage(() {});
                                            },
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ] else
                                        _editIcon(
                                          onTap: () {
                                            nameStartedTyping = false;
                                            editingNameRef[0] = true;
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
                              if (editingNameRef[0] &&
                                  nameStartedTyping &&
                                  _nameError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _nameError!,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BColors.validationError,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_isDeletingAccount) BouhFullScreenLoadingOverlay(),
                    ],
                  ),
                  bottomNavigationBar: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: (_isDeletePreflightBusy || _isDeletingAccount)
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
                        icon: (_isDeletePreflightBusy || _isDeletingAccount)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
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
            );
          },
        ),
      ),
    );

    nameFocusNode.removeListener(onNameFocusChange);
    nameFocusNode.dispose();
    _refreshCaregiverPersonalPage = null;

    if (!mounted) return;
    setState(() {
      _nameError = null;
      _nameCtrl.text = _name;
    });
  }

  Future<void> _loadCaregiverProfile() async {
    setState(() {
      _loadingProfile = true;
      _profileError = null;
    });
    try {
      final map = await _profileService.fetchCaregiverProfile();
      if (!mounted) return;
      _cancelDeleteErrorTimer();
      setState(() {
        _deleteError = null;
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

  String? _validateName(String value) =>
      ProfileFieldValidation.caregiverDisplayName(value);

  Future<void> _saveNameInline() async {
    final validation = _validateName(_nameCtrl.text);
    if (validation != null) {
      setState(() => _nameError = validation);
      return;
    }
    ProfileFieldValidation.syncTextControllerToNormalizedPersonName(_nameCtrl);
    final candidate = ProfileFieldValidation.normalizePersonName(
      _nameCtrl.text,
    );
    if (candidate == ProfileFieldValidation.normalizePersonName(_name)) {
      setState(() => _nameError = null);
      return;
    }

    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      await _profileService.updateCaregiverName(candidate);

      if (!mounted) return;
      setState(() {
        _name = candidate;
        _nameCtrl.text = candidate;
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

  Widget _sectionFieldItem({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_label(label), const SizedBox(height: 6), child],
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
            MaterialPageRoute(builder: (_) => const ChildrenManagementView()),
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
