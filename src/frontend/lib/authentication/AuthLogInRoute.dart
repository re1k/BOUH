import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bouh/View/HomePage/doctorNavbar.dart';
import 'package:bouh/View/Login/login_view.dart';
import 'package:bouh/View/WelcomePage/welcomePage_view.dart';
import 'package:bouh/View/caregiverHomepage/caregivernavbar.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/widgets/loading_overlay.dart';

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
    //On app start, Firebase may already have a currentUser but our in-memory
    //AuthSession has no JWT yet. Refresh it so _session.idToken is populated
    //before we route based on the persisted role.
    try {
      await AuthService.instance.refreshSession();
    } on FirebaseAuthException {
      // Token refresh failed 
      // Account was deleted or revoked.
      // Clear the stale session and send the user to login.
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
      return;
    }

    final role = await AuthService.instance.role;

    if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: BouhLoadingOverlay());
  }
}
