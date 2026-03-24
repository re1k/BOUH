import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bouh/View/caregiverHomepage/caregiverHomepage.dart';
import 'package:bouh/View/viewAppointments/appointmentspage.dart';
import 'package:bouh/View/viewAppointments/bookedAppointmentsUpcoming.dart';
import 'package:bouh/View/viewAppointments/bookedAppointmentsPrevious.dart';
import 'package:bouh/View/DrawingAnalysis/RequestAnalysisPage.dart';
import 'package:bouh/View/Profile/CaregiverProfile.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/View/Login/login_view.dart';

/// Shell that holds the caregiver bottom nav index and switches between
/// home (0), drawings (1), appointments (2), and profile (3).
class CaregiverNavbar extends StatefulWidget {
  const CaregiverNavbar({
    super.key,
    this.initialIndex = 0,
    this.initialAppointmentsSubIndex = 0,
    this.initialBookedSubIndex = 0,
  });

  final int initialIndex;

  /// داخل Tab المواعيد:
  /// 0 = Available (متاحة)
  /// 1 = Booked (محجوزة)
  final int initialAppointmentsSubIndex;

  /// داخل booked:
  /// 0 = Upcoming (القادمة)
  /// 1 = Previous (السابقة)
  final int initialBookedSubIndex;

  @override
  State<CaregiverNavbar> createState() => _CaregiverNavbarState();
}

class _CaregiverNavbarState extends State<CaregiverNavbar> {
  late int _currentIndex;

  // Key to access caregiver homepage state for refresh on re-tap.
  final GlobalKey<CaregiverHomepageState> _homeKey = GlobalKey();

  StreamSubscription<DocumentSnapshot>? _accountListener;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    final uid = AuthSession.instance.userId;
    if (uid != null) {
      _accountListener = FirebaseFirestore.instance
          .collection('caregivers')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists && mounted) {
              _forceLogout();
            }
          });
    }
  }

  Future<void> _forceLogout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _accountListener?.cancel();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final stackIndex = _currentIndex.clamp(0, 3);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: IndexedStack(
        index: stackIndex,
        children: [
          CaregiverHomepage(
            key: _homeKey,
            currentIndex: _currentIndex,
            onTap: _onTap,
          ),
          RequestAnalysisPage(currentIndex: _currentIndex, onTap: _onTap),
          _AppointmentsTabContent(
            currentIndex: _currentIndex,
            onTap: _onTap,
            initialSubIndex: widget.initialAppointmentsSubIndex,
            initialBookedSubIndex: widget.initialBookedSubIndex,
          ),
          CaregiverAccountView(currentIndex: _currentIndex, onTap: _onTap),
        ],
      ),
    );
  }
}

/// Holds available (متاحة) and booked (محجوزة) appointments. Switches with no animation.
class _AppointmentsTabContent extends StatefulWidget {
  const _AppointmentsTabContent({
    required this.currentIndex,
    required this.onTap,
    this.initialSubIndex = 0,
    this.initialBookedSubIndex = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 0 = متاحة ، 1 = محجوزة
  final int initialSubIndex;

  /// يمرر إلى booked
  final int initialBookedSubIndex;

  @override
  State<_AppointmentsTabContent> createState() =>
      _AppointmentsTabContentState();
}

class _AppointmentsTabContentState extends State<_AppointmentsTabContent> {
  /// 0 = Available (متاحة), 1 = Booked (محجوزة). IndexedStack = instant, no transition.
  late int _subIndex;

  @override
  void initState() {
    super.initState();
    _subIndex = widget.initialSubIndex.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _subIndex,
      children: [
        AppointmentsPage(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          onSwitchToBooked: () => setState(() => _subIndex = 1),
        ),
        _BookedTabContent(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          onSwitchToAvailable: () => setState(() => _subIndex = 0),
          initialBookedSubIndex: widget.initialBookedSubIndex,
        ),
      ],
    );
  }
}

/// Holds upcoming (القادمة) and previous (السابقة) booked. Switches with no animation.
class _BookedTabContent extends StatefulWidget {
  const _BookedTabContent({
    required this.currentIndex,
    required this.onTap,
    required this.onSwitchToAvailable,
    this.initialBookedSubIndex = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSwitchToAvailable;

  /// 0 = القادمة ، 1 = السابقة
  final int initialBookedSubIndex;

  @override
  State<_BookedTabContent> createState() => _BookedTabContentState();
}

class _BookedTabContentState extends State<_BookedTabContent> {
  /// 0 = Upcoming (القادمة), 1 = Previous (السابقة).
  late int _bookedSubIndex;

  @override
  void initState() {
    super.initState();
    _bookedSubIndex = widget.initialBookedSubIndex.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final AuthSession _session = AuthSession.instance;
    final String? caregiverId = _session.userId;

    return IndexedStack(
      index: _bookedSubIndex,
      children: [
        BookedAppointmentsUpcoming(
          caregiverId: caregiverId,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          onSwitchToAvailable: widget.onSwitchToAvailable,
          onSwitchToPrevious: () => setState(() => _bookedSubIndex = 1),
        ),
        BookedAppointmentsPrevious(
          caregiverId: caregiverId,
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          onSwitchToAvailable: widget.onSwitchToAvailable,
          onSwitchToUpcoming: () => setState(() => _bookedSubIndex = 0),
        ),
      ],
    );
  }
}
