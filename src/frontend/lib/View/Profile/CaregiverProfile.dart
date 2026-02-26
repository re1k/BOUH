import 'package:bouh/theme/base_themes/colors.dart';
import 'package:flutter/material.dart';
import 'package:bouh/View/Profile/ChildrenManagementView.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/View/Login/login_view.dart';

class CaregiverAccountView extends StatelessWidget {
  const CaregiverAccountView({super.key, this.currentIndex = 3, this.onTap});

  /// Active bottom nav index (3 = profile). Pass when used inside [CaregiverNavbar].
  final int currentIndex;

  /// Called when a bottom nav item is tapped. Pass when used inside [CaregiverNavbar].
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            //HEADER
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

                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, left: 16),
                      child: Align(
                        alignment: Alignment.topLeft,
                      child: _LogoutButton(
                        onTap: () => _handleLogout(context),
                      ),
                      ),
                    ),
                  ),

                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "المعلومات الشخصية",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    _label("البريد الالكتروني"),
                    const SizedBox(height: 6),
                    _field(text: "lobaaliayhya@gmail.com"),

                    const SizedBox(height: 18),

                    _label("الاسم"),
                    const SizedBox(height: 6),
                    _field(
                      text: "لبى آل يحيى",
                      trailing: _editIcon(onTap: () {}),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChildrenManagementView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              "ادارة الاطفال",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Spacer(),
                            Icon(
                              Icons.arrow_forward_ios_outlined,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    Center(
                      child: SizedBox(
                        width: 180,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {}, // TODO later
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE4573D),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "حذف الحساب",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: onTap != null
            ? Material(
                clipBehavior: Clip.none,
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: CaregiverBottomNav(
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  // Helpers  (EASIER IF WE WANT TO CHANGE LATER THE FIELDS OR LABELS)

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

  static Widget _field({required String text, Widget? trailing}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // TODO later
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.logout, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text(
            "تسجيل الخروج",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
