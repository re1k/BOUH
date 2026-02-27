import 'dart:io' show SocketException;
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bouh/authentication/AuthLogInRoute.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/WelcomePage/welcomePage_view.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/widgets/email_reset_popup.dart';
import 'package:bouh/widgets/doctor_pending_popup.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _emailError;
  String? _passwordError;

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _emailTouched = false;
  bool _passwordTouched = false;

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'يرجى إدخال البريد الإلكتروني';
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim()))
      return 'يرجى إدخال بريد إلكتروني صحيح';
    return null;
  }

  static String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'يرجى إدخال كلمة المرور';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _emailTouched = true;
        _emailFieldKey.currentState?.validate();
        if (mounted) setState(() {});
      }
    });
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        _passwordTouched = true;
        _passwordFieldKey.currentState?.validate();
        if (mounted) setState(() {});
      }
    });
    if (widget.showPendingDoctorDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => DoctorPendingPopup(
            onOk: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AccountTypeView()),
                (route) => false,
              );
            },
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(() {});
    _passwordFocusNode.removeListener(() {});
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
      _emailTouched = true;
      _passwordTouched = true;
    });

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Check email format again before calling login (so wrong format never gets mistaken for network).
    final emailFormatError = _validateEmail(email);
    if (emailFormatError != null) {
      setState(() => _emailError = emailFormatError);
      return;
    }

    try {
      await AuthService.instance.login(email: email, password: password);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginResolverView()),
      );
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _passwordError =
            'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        switch (e.code) {
          case 'invalid-email':
          case 'invalid-credential':
            _emailError =
                'صيغة البريد الإلكتروني غير صحيحة أو الحساب غير موجود.';
            _passwordError = null;
            break;
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-login-credentials':
            _emailError = null;
            _passwordError = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
            break;
          default:
            _passwordError = _mapLoginErrorToMessage(e);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordError = _mapLoginErrorToMessage(e);
      });
    }
  }

  String _mapLoginErrorToMessage(Object e) {
    final msg = e.toString();

    if (msg.contains('wrong_credentials')) {
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    }

    // Only treat as network error for real I/O / socket errors, not for auth errors that might mention "connection".
    if (e is SocketException) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
    }
    if (msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى.';
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
    ).then((submitted) {
      if (submitted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك.'),
          ),
        );
      }
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
        body: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// Scrollable container to support small screens and keyboard overlap.
              SingleChildScrollView(
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
                          focusNode: _emailFocusNode,
                          fieldKey: _emailFieldKey,
                          validator: (v) =>
                              _emailTouched ? _validateEmail(v) : null,
                          textInputAction: TextInputAction.next,
                          serverError: _emailError,
                          onChanged: () {
                            if (_emailError != null)
                              setState(() => _emailError = null);
                          },
                        ),
                        const SizedBox(height: 14),

                        /// Password input with validation (required). Reactive error under field.
                        _LabeledField(
                          label: 'كلمة المرور',
                          keyboardType: TextInputType.text,
                          obscure: true,
                          controller: _passwordCtrl,
                          focusNode: _passwordFocusNode,
                          fieldKey: _passwordFieldKey,
                          validator: (v) =>
                              _passwordTouched ? _validatePassword(v) : null,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          serverError: _passwordError,
                          onChanged: () {
                            if (_passwordError != null)
                              setState(() => _passwordError = null);
                          },
                        ),
                        const SizedBox(height: 18),

                        /// Login button.
                        /// Connect loading/error states here in the next stage.
                        SizedBox(
                          width: 237,
                          height: 53,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: BColors.secondary,
                              foregroundColor: BColors.textDarkestBlue,
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
            ],
          ),
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
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: BColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: BColors.primary.withOpacity(0.6)),
            ),
            errorText: serverError,
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
