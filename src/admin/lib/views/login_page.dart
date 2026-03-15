import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import 'homepage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _emailTouched = false;
  bool _passwordTouched = false;

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'يرجى إدخال البريد الإلكتروني';
    }
    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(trimmed)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    const allowedDomains = <String>{
      'gmail.com',
      'outlook.com',
      'hotmail.com',
      'yahoo.com',
      'icloud.com',
      'live.com',
    };

    final parts = trimmed.split('@');
    if (parts.length != 2) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }
    final domain = parts.last.toLowerCase();
    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    const allowedTlds = <String>{
      'com',
      'net',
      'org',
      'edu',
      'gov',
      'sa',
    };
    final tld = domainParts.last;
    final tldRegex = RegExp(r'^[a-zA-Z]{2,}$');
    if (!tldRegex.hasMatch(tld) || !allowedTlds.contains(tld)) {
      return 'يرجى إدخال بريد إلكتروني صحيح';
    }

    if (!allowedDomains.contains(domain)) {
      return 'يرجى استخدام بريد من مزوّد معتمد (مثل Gmail / Outlook)';
    }

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

    final emailFormatError = _validateEmail(_emailCtrl.text.trim());
    if (emailFormatError != null) {
      setState(() => _emailError = emailFormatError);
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      await AdminAuthService.instance.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        switch (e.code) {
          case 'invalid-email':
            _emailError = 'صيغة البريد الإلكتروني غير صحيحة.';
            break;
          case 'invalid-credential':
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-login-credentials':
            _passwordError =
                'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
            break;
          case 'too-many-requests':
            _passwordError =
                'تم تجاوز عدد المحاولات. انتظر قليلاً ثم حاول مرة أخرى.';
            break;
          default:
            _passwordError = 'حدث خطأ غير متوقع. حاول مرة أخرى.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        _passwordError = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
      });
    }
  }

  void _handleForgotPassword() {
    final resetEmailCtrl = TextEditingController();
    String? dialogError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'استعادة كلمة المرور',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط استعادة كلمة المرور.',
                  style: TextStyle(fontSize: 14, color: BColors.darkerGrey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: resetEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    errorText: dialogError,
                    errorMaxLines: 2,
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
                      borderSide:
                          BorderSide(color: BColors.primary.withValues(alpha: 0.6)),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: BColors.validationError),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: BColors.darkGrey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.primary,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final email = resetEmailCtrl.text.trim();
                  if (email.isEmpty) {
                    setDialogState(
                      () => dialogError = 'يرجى إدخال البريد الإلكتروني',
                    );
                    return;
                  }

                  final error = await AdminAuthService.instance
                      .sendPasswordResetEmail(email: email);

                  if (!ctx.mounted) return;

                  if (error != null) {
                    setDialogState(() => dialogError = error);
                  } else {
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني.',
                            textDirection: TextDirection.rtl,
                          ),
                          backgroundColor: BColors.primary,
                        ),
                      );
                    }
                  }
                },
                child: const Text('إرسال'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: Align(
          alignment: const Alignment(0, -0.15),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/login_header.png',
                      width: 250,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'لوحة تحكم المسؤول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: BColors.textDarkestBlue,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'البريد الإلكتروني',
                          style:
                              TextStyle(fontSize: 13, color: BColors.darkGrey),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: _emailFieldKey,
                          controller: _emailCtrl,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          textAlign: TextAlign.right,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              _emailTouched ? _validateEmail(v) : null,
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                            if (_emailTouched) {
                              _emailFieldKey.currentState?.validate();
                            }
                          },
                          decoration: _inputDecoration(
                            errorText: _emailError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Password
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'كلمة المرور',
                          style:
                              TextStyle(fontSize: 13, color: BColors.darkGrey),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: _passwordFieldKey,
                          controller: _passwordCtrl,
                          focusNode: _passwordFocusNode,
                          obscureText: _obscurePassword,
                          textAlign: TextAlign.right,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          validator: (v) =>
                              _passwordTouched ? _validatePassword(v) : null,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                            if (_passwordTouched) {
                              _passwordFieldKey.currentState?.validate();
                            }
                          },
                          decoration: _inputDecoration(
                            errorText: _passwordError,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: BColors.darkGrey,
                                size: 22,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Login button
                    SizedBox(
                      width: 260,
                      height: 56,
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
                        child: _isLoggingIn
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: BColors.primary,
                                ),
                              )
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 17),

                    // Forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'نسيت كلمة المرور؟',
                          style:
                              TextStyle(fontSize: 13, color: BColors.darkGrey),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: BColors.white,
      hoverColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 8),
              child: suffixIcon,
            )
          : null,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BColors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: BColors.primary.withValues(alpha: 0.6)),
      ),
      errorText: errorText,
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
    );
  }
}
