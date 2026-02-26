import 'package:flutter/material.dart';
import 'package:bouh/View/HomePage/doctorHomePage.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/View/WelcomePage/splash_view.dart';
import 'package:bouh/View/WelcomePage/welcomePage_view.dart';
import 'package:bouh/View/caregiverHomepage/caregivernavbar.dart';
import 'package:bouh/authentication/AuthService.dart';

//Resolves route from session role set by backend at login
class LoginResolverView extends StatefulWidget {
  const LoginResolverView({super.key});

  @override
  State<LoginResolverView> createState() => _LoginResolverViewState();
}

class _LoginResolverViewState extends State<LoginResolverView> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final role = await AuthService.instance.role;

    if (!mounted) return;
    switch (role) {
      case 'doctor':
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorHomePage()),
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
  }

  @override
  Widget build(BuildContext context) {
    return const SplashView();
  }
}
