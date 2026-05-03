import 'dart:io' show SocketException;
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/WelcomePage/welcomePage_view.dart';
import 'package:bouh/View/HomePage/doctorNavbar.dart';
import 'package:bouh/View/caregiverHomepage/caregivernavbar.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/email_reset_popup.dart';
import 'package:bouh/widgets/doctor_pending_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:bouh/utils/profile_field_validation.dart';

/// Login: validate form → AuthService.login(email, password) → backend returns uid, role → route by role.
class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    this.onLogin,
    this.onForgotPassword,
    this.onCreateAccount,
    this.showPendingDoctorDialog = false,
  });

  final Future<void> Function(String email, String password)? onLogin;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;
  final bool showPendingDoctorDialog;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const String _kInvalidCredentialsMessage =
      'البريد الإلكتروني أو كلمة المرور غير صحيحة. لم يتم العثور على الحساب.';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _emailError;
  String? _passwordError;
  String? _loginErrorMessage;
  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _emailTouched = false;
  bool _passwordTouched = false;

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
    return null;
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

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_onEmailFocusChange);
    _passwordFocusNode.addListener(_onPasswordFocusChange);
    if (widget.showPendingDoctorDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DoctorPendingPopup(
            onOk: () => Navigator.pop(dialogContext),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_onEmailFocusChange);
    _passwordFocusNode.removeListener(_onPasswordFocusChange);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _loginErrorMessage = null;
      _emailTouched = true;
      _passwordTouched = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Check email format again before calling login (so wrong format never gets mistaken for network).
    final emailFormatError = ProfileFieldValidation.accountEmail(email);
    if (emailFormatError != null) {
      setState(() => _emailError = emailFormatError);
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final role = await AuthService.instance.login(email: email, password: password);

      if (!mounted) return;
      // Keep overlay on until we navigate (single loading, no second screen)

      switch (role) {
        case 'doctor':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const DoctorNavbar()),
          );
          break;
        case 'caregiver':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const CaregiverNavbar()),
          );
          break;
        case 'pending':
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginView(showPendingDoctorDialog: true)),
          );
          break;
        default:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AccountTypeView()),
          );
      }
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        _passwordError =
            'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        switch (e.code) {
          case 'invalid-email':
            _emailError = 'صيغة البريد الإلكتروني غير صحيحة.';
            _passwordError = null;
            break;
          case 'invalid-credential':
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-login-credentials':
            _emailError = null;
            _passwordError = null;
            _loginErrorMessage = _kInvalidCredentialsMessage;
            break;
          case 'too-many-requests':
            _emailError = null;
            _passwordError =
                'تم تجاوز عدد المحاولات. انتظر قليلاً ثم حاول مرة أخرى.';
            _loginErrorMessage = null;
            break;
          case 'user-disabled':
            _emailError = null;
            _passwordError = 'تم تعطيل هذا الحساب. تواصل مع الدعم.';
            _loginErrorMessage = null;
            break;
          default:
            _emailError = null;
            _passwordError = _mapLoginErrorToMessage(e);
            _loginErrorMessage = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      final mappedMessage = _mapLoginErrorToMessage(e);
      final isInvalidCredentials = mappedMessage == _kInvalidCredentialsMessage;
      setState(() {
        _isLoggingIn = false;
        if (isInvalidCredentials) {
          _emailError = null;
          _passwordError = null;
          _loginErrorMessage = mappedMessage;
        } else {
          _emailError = null;
          _passwordError = mappedMessage;
          _loginErrorMessage = null;
        }
      });
    }
  }

  String _mapLoginErrorToMessage(Object e) {
    final msg = e.toString();

    if (msg.contains('wrong_credentials') ||
        msg.contains('invalid-credential') ||
        msg.contains('INVALID_LOGIN_CREDENTIALS')) {
      return _kInvalidCredentialsMessage;
    }

    if (e is SocketException) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
    }
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
    }

    if (msg.contains('UNAUTHORIZED') || msg.contains('401')) {
      return _kInvalidCredentialsMessage;
    }

    return 'حدث خطأ غير متوقع. حاول مرة أخرى.';
  }

  void _handleForgotPassword() {
    if (widget.onForgotPassword != null) {
      widget.onForgotPassword!.call();
      return;
    }
    EmailResetPopup.show(
      context,
      onSubmit: (email) =>
          AuthService.instance.sendPasswordResetEmail(email: email),
    ).then((submitted) async {
      if (!submitted || !mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await Future<void>.delayed(const Duration(milliseconds: 180));
      if (!mounted) return;
      ConfirmationPopup.show(
        context,
        title: 'تحقق من بريدك الإلكتروني',
        message:
            'إذا كان البريد الإلكتروني مسجلاً، فستصلك رسالة تحتوي على رابط لإعادة تعيين كلمة المرور. يرجى التحقق من صندوق الوارد أو البريد غير الهام.',
        confirmText: 'حسناً',
        singleButton: true,
        useDarkMessageText: true,
      );
    });
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AccountTypeView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 75, 20, 220),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        /// Header branding image.
                        Image.asset(
                          'assets/images/login_header.png',
                          width: 160,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 14),

                        /// Screen title.
                        const Text(
                          'أهلًا بعودتك!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: BColors.textDarkestBlue,
                          ),
                        ),
                        const SizedBox(height: 22),

                        /// Email input with validation (format). Reactive error under field.
                        _LabeledField(
                          label: 'البريد الإلكتروني',
                          keyboardType: TextInputType.emailAddress,
                          obscure: false,
                          controller: _emailCtrl,
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: BColors.primary,
                            size: 22,
                          ),
                          focusNode: _emailFocusNode,
                          fieldKey: _emailFieldKey,
                          validator: (v) => _emailTouched
                              ? ProfileFieldValidation.accountEmail(v)
                              : null,
                          textInputAction: TextInputAction.next,
                          serverError: _emailError,
                          onChanged: () {
                            setState(() {
                              if (_emailError != null) _emailError = null;
                              if (_passwordError != null) _passwordError = null;
                              if (_loginErrorMessage != null) {
                                _loginErrorMessage = null;
                              }
                            });
                            if (_emailTouched) {
                              _emailFieldKey.currentState?.validate();
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        /// Password input with validation (required). Reactive error under field.
                        _LabeledField(
                          label: 'كلمة المرور',
                          keyboardType: TextInputType.text,
                          obscure: _obscurePassword,
                          controller: _passwordCtrl,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: BColors.primary,
                            size: 22,
                          ),
                          focusNode: _passwordFocusNode,
                          fieldKey: _passwordFieldKey,
                          validator: (v) =>
                              _passwordTouched ? _validatePassword(v) : null,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          serverError: _passwordError,
                          onChanged: () {
                            setState(() {
                              if (_passwordError != null) _passwordError = null;
                              if (_loginErrorMessage != null) {
                                _loginErrorMessage = null;
                              }
                            });
                            if (_passwordTouched) {
                              _passwordFieldKey.currentState?.validate();
                            }
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: BColors.primary,
                              size: 22,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (_loginErrorMessage != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _loginErrorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: BColors.validationError,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        /// Login button.
                        SizedBox(
                          width: 237,
                          height: 53,
                          child: ElevatedButton(
                            onPressed: _isLoggingIn ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: BColors.secondary,
                              foregroundColor: BColors.textDarkestBlue,
                              disabledBackgroundColor: BColors.secondary,
                              disabledForegroundColor: BColors.textDarkestBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),

                        /// Secondary actions (forgot password / sign up).
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: BColors.darkGrey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _handleForgotPassword,
                                  child: const Text(
                                    'اضغط هنا',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: BColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'لا تمتلك حساب؟',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: BColors.darkGrey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _handleCreateAccount,
                                  child: const Text(
                                    'سجّل الآن',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: BColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Decorative background wave.
            /// Visual-only element; must remain free of logic.
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              Positioned(
                left: -350,
                bottom: -250,
                child: Transform.rotate(
                  alignment: Alignment.bottomLeft,
                  angle: 11 * math.pi / 180,
                  child: SizedBox(
                    height: 500,
                    child: Image.asset(
                      'assets/images/wave_login.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            if (_isLoggingIn) BouhLoadingOverlay(),
          ],
          ),
        ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final bool obscure;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? serverError;
  final VoidCallback? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const _LabeledField({
    required this.label,
    required this.keyboardType,
    required this.obscure,
    required this.controller,
    this.focusNode,
    this.fieldKey,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.serverError,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
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
          textAlign: TextAlign.right,
          validator: validator,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged != null ? (_) => onChanged!() : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: BColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            prefixIcon: prefixIcon,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BColors.primary.withOpacity(0.6)),
            ),
            errorText: serverError,
            errorMaxLines: 2,
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
          ),
        ),
      ],
    );
  }
}
