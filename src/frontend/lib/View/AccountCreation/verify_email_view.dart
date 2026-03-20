// import 'dart:async';
// import 'dart:io' show SocketException;

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:bouh/theme/base_themes/colors.dart';
// import 'package:bouh/authentication/AuthService.dart';
// import 'package:bouh/View/Login/login_view.dart';
// import 'package:bouh/widgets/loading_overlay.dart';

// /// After signup: user verifies email, then we create backend profile (if pending) and go to login.
// class VerifyEmailView extends StatefulWidget {
//   const VerifyEmailView({super.key});

//   @override
//   State<VerifyEmailView> createState() => _VerifyEmailViewState();
// }

// class _VerifyEmailViewState extends State<VerifyEmailView> {
//   bool _isChecking = false;
//   bool _isSending = false;

//   String? _inlineMessage;
//   Color _inlineMessageColor = BColors.darkGrey;

//   static const int _cooldownSeconds = 60;
//   int _secondsUntilResend = 0;
//   Timer? _cooldownTimer;

//   bool get _canResend => _secondsUntilResend <= 0 && !_isSending;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await _sendVerificationEmail(
//         force: true,
//         messageOnSuccess: 'تم إرسال رابط التحقق إلى بريدك الإلكتروني، يرجى تفعيل حسابك عبر الرابط المرسل إليك، وفي حال عدم وصوله تحقق من البريد غير المرغوب فيه.',
//         messageColorOnSuccess: BColors.darkGrey,
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _cooldownTimer?.cancel();
//     super.dispose();
//   }

//   void _startCooldown() {
//     _cooldownTimer?.cancel();
//     _secondsUntilResend = _cooldownSeconds;
//     _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (!mounted) return;
//       if (_secondsUntilResend <= 1) {
//         t.cancel();
//         setState(() => _secondsUntilResend = 0);
//       } else {
//         setState(() => _secondsUntilResend -= 1);
//       }
//     });
//   }

//   void _setInlineMessage(String message, {required Color color}) {
//     setState(() {
//       _inlineMessage = message;
//       _inlineMessageColor = color;
//     });
//   }

//   Future<void> _sendVerificationEmail({
//     required bool force,
//     String? messageOnSuccess,
//     Color messageColorOnSuccess = BColors.darkGrey,
//   }) async {
//     var user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     if (!force && !_canResend) return;

//     if (mounted) setState(() => _isSending = true);
//     try {
//       await user.reload();
//       user = FirebaseAuth.instance.currentUser;
//       if (user == null || !mounted) return;
//       await user.sendEmailVerification();
//       if (!mounted) return;
//       _startCooldown();
//       if (messageOnSuccess != null) {
//         _setInlineMessage(messageOnSuccess, color: messageColorOnSuccess);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       _setInlineMessage('تعذر إرسال رابط التحقق. حاول مرة أخرى.', color: BColors.validationError);
//     } finally {
//       if (mounted) setState(() => _isSending = false);
//     }
//   }

//   Future<void> _onDoneTapped() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       if (mounted) {
//         _setInlineMessage(
//           'لم يتم العثور على مستخدم. يرجى تسجيل الدخول مجدداً.',
//           color: BColors.validationError,
//         );
//         _navigateToLogin();
//       }
//       return;
//     }

//     setState(() => _isChecking = true);

//     try {
//       await user.reload();
//       final updatedUser = FirebaseAuth.instance.currentUser;
//       final isVerified = updatedUser?.emailVerified ?? false;

//       if (!mounted) return;

//       if (isVerified) {
//         await AuthService.instance.refreshSession();
//         try {
//           print('[VerifyEmailView] email verified, calling createPendingDoctorProfileIfAny (profile image upload is ongoing)');
//           await AuthService.instance.createPendingDoctorProfileIfAny();
//           await AuthService.instance.createPendingCaregiverProfileIfAny();
//           _navigateToLogin();
//         } catch (e) {
//           final String msg = (e is SocketException || e is TimeoutException)
//               ? 'الخادم لا يستجيب أو لا يوجد اتصال. تحقق من الإنترنت ثم اضغط "تم تفعيل البريد الالكتروني" مرة أخرى.'
//               : 'تم تفعيل البريد ولكن فشل إنشاء الحساب في الخادم. اضغط "تم تفعيل البريد الالكتروني" للمحاولة مرة أخرى.';
//           _setInlineMessage(msg, color: BColors.validationError);
//           // Do not navigate: user stays on page and can tap the button again to retry.
//         }
//       } else {
//         if (_canResend) {
//           _setInlineMessage(
//             'لم يتم تفعيل البريد بعد. تم إعادة إرسال رابط التحقق.',
//             color: BColors.validationError,
//           );
//           await _sendVerificationEmail(
//             force: false,
//             messageOnSuccess: 'لم يتم تفعيل البريد بعد. تم إعادة إرسال رابط التحقق.',
//             messageColorOnSuccess: BColors.validationError,
//           );
//         } else {
//           _setInlineMessage(
//             'لم يتم تفعيل البريد بعد. يمكنك إعادة الإرسال بعد $_secondsUntilResend ثانية.',
//             color: BColors.validationError,
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) {
//         _setInlineMessage('حدث خطأ. حاول مرة أخرى.', color: BColors.validationError);
//       }
//     } finally {
//       if (mounted) setState(() => _isChecking = false);
//     }
//   }

//   void _navigateToLogin() {
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const LoginView()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: BColors.white,
//         body: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 28),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Spacer(flex: 2),
//                 Image.asset(
//                   'assets/images/verifyEmail.png',
//                   width: 280,
//                   fit: BoxFit.contain,
//                 ),
//                 const SizedBox(height: 32),

//                 const SizedBox(height: 12),

//                 if (_inlineMessage != null) ...[
//                   const SizedBox(height: 14),
//                   Text(
//                     _inlineMessage!,
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                       color: _inlineMessageColor,
//                       height: 1.35,
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 10),
//                 TextButton(
//                   onPressed: _canResend
//                       ? () async {
//                           await _sendVerificationEmail(
//                             force: false,
//                             messageOnSuccess: 'تم إرسال رابط التحقق إلى بريدك الإلكتروني، يرجى تفعيل حسابك عبر الرابط المرسل إليك، وفي حال عدم وصوله تحقق من البريد غير المرغوب فيه.',
//                             messageColorOnSuccess: BColors.darkGrey,
//                           );
//                         }
//                       : null,
//                   child: Text.rich(
//                     textAlign: TextAlign.center,
//                     TextSpan(
//                       style: TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.w700,
//                         color: _canResend ? BColors.primary : BColors.darkGrey,
//                       ),
//                       children: [
//                         const TextSpan(text: 'لم يصلني رابط التحقق '),
//                         TextSpan(
//                           text: _isSending ? 'جاري الإرسال...' : 'اعاده الارسال',
//                           style: TextStyle(
//                             decoration: _isSending ? null : TextDecoration.underline,
//                             decorationColor: _canResend ? BColors.primary : BColors.darkGrey,
//                           ),
//                         ),
//                         if (_secondsUntilResend > 0 && !_isSending)
//                           TextSpan(text: ' (بعد $_secondsUntilResend ث)'),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const Spacer(flex: 2),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: _isChecking ? null : _onDoneTapped,
//                     style: ElevatedButton.styleFrom(
//                       elevation: 0,
//                       backgroundColor: BColors.secondary,
//                       foregroundColor: BColors.textDarkestBlue,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                     ),
//                     child: _isChecking
//                         ? const BouhOvalLoadingIndicator(
//                             width: 24,
//                             height: 24,
//                             strokeWidth: 2,
//                           )
//                         : const Text(
//                             'تم تفعيل البريد الالكتروني',
//                             style: TextStyle(
//                               fontSize: 17,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:io' show SocketException;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/widgets/loading_overlay.dart';

/// After signup: user verifies email, then we create backend profile (if pending) and go to login.
class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  bool _isChecking = false;
  bool _isSending = false;

  String? _inlineMessage;
  Color _inlineMessageColor = BColors.textDarkestBlue;

  static const int _cooldownSeconds = 60;
  int _secondsUntilResend = 0;
  Timer? _cooldownTimer;

  bool get _canResend => _secondsUntilResend <= 0 && !_isSending;

  @override
  void initState() {
    super.initState();

    // Auto-send verification email once when opening the page (only if not verified).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _sendVerificationEmail(
        force: true,
        messageOnSuccess:
            'تم إرسال رابط التحقق إلى بريدك الإلكتروني، يرجى تفعيل حسابك عبر الرابط المرسل إليك، وفي حال عدم وصوله تحقق من البريد غير المرغوب فيه.',
        messageColorOnSuccess: BColors.textDarkestBlue,
      );
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _secondsUntilResend = _cooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsUntilResend <= 1) {
        t.cancel();
        setState(() => _secondsUntilResend = 0);
      } else {
        setState(() => _secondsUntilResend -= 1);
      }
    });
  }

  void _setInlineMessage(String message, {required Color color}) {
    if (!mounted) return;
    setState(() {
      _inlineMessage = message;
      _inlineMessageColor = color;
    });
  }

  Future<void> _sendVerificationEmail({
    required bool force,
    String? messageOnSuccess,
    Color messageColorOnSuccess = BColors.textDarkestBlue,
  }) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (!force && !_canResend) return;

    if (mounted) setState(() => _isSending = true);
    try {
      // Refresh user state first.
      await user.reload();
      user = FirebaseAuth.instance.currentUser;
      if (user == null || !mounted) return;

      // If already verified, do NOT send again.
      if (user.emailVerified) {
        _setInlineMessage(
          'تم تفعيل البريد بالفعل ',
          color: BColors.textDarkestBlue,
        );
        return;
      }

      await user.sendEmailVerification();

      if (!mounted) return;
      _startCooldown();

      if (messageOnSuccess != null) {
        _setInlineMessage(messageOnSuccess, color: messageColorOnSuccess);
      }
    } catch (_) {
      if (!mounted) return;
      _setInlineMessage(
        'تعذر إرسال رابط التحقق. حاول مرة أخرى.',
        color: BColors.validationError,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _onDoneTapped() async {
    if (_isChecking) return;

    // Always work on the latest currentUser reference.
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      _setInlineMessage(
        'لم يتم العثور على مستخدم. يرجى تسجيل الدخول مجدداً.',
        color: BColors.validationError,
      );
      _navigateToLogin();
      return;
    }

    setState(() => _isChecking = true);

    try {
      await current.reload();
      final updatedUser = FirebaseAuth.instance.currentUser;
      final isVerified = updatedUser?.emailVerified ?? false;

      if (!mounted) return;

      if (isVerified) {
        // Ensure we have a fresh JWT before calling backend.
        await AuthService.instance.refreshSession();

        try {
          // Try to create whichever pending profile exists (doctor/caregiver).
          final didDoctor = await AuthService.instance
              .createPendingDoctorProfileIfAny();
          final didCaregiver = await AuthService.instance
              .createPendingCaregiverProfileIfAny();

          // Optional: show a friendly message if there was nothing pending.
          if (!didDoctor && !didCaregiver) {
            _setInlineMessage(
              'تم تفعيل البريد ويمكنك تسجيل الدخول الآن.',
              color: BColors.textDarkestBlue,
            );
          }

          _navigateToLogin();
        } catch (e) {
          final String msg = (e is SocketException || e is TimeoutException)
              ? 'الخادم لا يستجيب أو لا يوجد اتصال. تحقق من الإنترنت ثم اضغط "تم تفعيل البريد الالكتروني" مرة أخرى.'
              : 'تم تفعيل البريد ولكن فشل إنشاء الحساب في الخادم. اضغط "تم تفعيل البريد الالكتروني" للمحاولة مرة أخرى.';
          _setInlineMessage(msg, color: BColors.validationError);
          // Stay on page for retry.
        }
      } else {
        // Not verified yet: resend if allowed; otherwise show remaining seconds.
        if (_canResend) {
          await _sendVerificationEmail(
            force: false,
            messageOnSuccess:
                'لم يتم تفعيل البريد بعد. تم إعادة إرسال رابط التحقق.',
            messageColorOnSuccess: BColors.validationError,
          );
        } else {
          _setInlineMessage(
            '.لم يتم تفعيل البريد بعد',
            color: BColors.validationError,
          );
        }
      }
    } catch (_) {
      if (mounted) {
        _setInlineMessage(
          'حدث خطأ. حاول مرة أخرى.',
          color: BColors.validationError,
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Image.asset(
                  'assets/images/verifyEmail.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  'يرجى تفعيل البريد الإلكتروني للمتابعة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: BColors.textDarkestBlue,
                  ),
                ),
                const SizedBox(height: 16),

                if (_inlineMessage != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _inlineMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _inlineMessageColor,
                      height: 1.35,
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                TextButton(
                  onPressed: _canResend
                      ? () async {
                          await _sendVerificationEmail(
                            force: false,
                            messageOnSuccess:
                                'تم إرسال رابط التحقق إلى بريدك الإلكتروني، يرجى تفعيل حسابك عبر الرابط المرسل إليك، وفي حال عدم وصوله تحقق من البريد غير المرغوب فيه.',
                            messageColorOnSuccess: BColors.textDarkestBlue,
                          );
                        }
                      : null,
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _canResend
                            ? BColors.primary
                            : BColors.textDarkestBlue.withOpacity(0.65),
                      ),
                      children: [
                        const TextSpan(text: 'لم يصلني رابط التحقق '),
                        TextSpan(
                          text: _isSending
                              ? 'جاري الإرسال...'
                              : 'اعاده الارسال',
                          style: TextStyle(
                            decoration: _isSending
                                ? null
                                : TextDecoration.underline,
                            decorationColor: _canResend
                                ? BColors.primary
                                : BColors.textDarkestBlue.withOpacity(0.65),
                          ),
                        ),
                        if (_secondsUntilResend > 0 && !_isSending)
                          TextSpan(text: ' (بعد $_secondsUntilResend ث)'),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _onDoneTapped,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: BColors.secondary,
                      foregroundColor: BColors.textDarkestBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isChecking
                        ? const BouhOvalLoadingIndicator(
                            width: 24,
                            height: 24,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'تم تفعيل البريد الالكتروني',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
