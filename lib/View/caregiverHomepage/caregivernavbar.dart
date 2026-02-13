import 'package:flutter/material.dart';
import 'caregiverHomepage.dart';
import 'package:bouh/View/viewAppointments/appointmentspage.dart';
import 'package:bouh/View/viewAppointments/bookedAppointmentsUpcoming.dart';
import 'package:bouh/View/viewAppointments/bookedAppointmentsPrevious.dart';

/// Shell that holds the caregiver bottom nav index and switches between
/// home (0), drawings (1), appointments (2), and profile (3).
/// Tapping the المواعيد tab shows the appointments stack (available ↔ booked).
class CaregiverNavbar extends StatefulWidget {
  const CaregiverNavbar({super.key});

  @override
  State<CaregiverNavbar> createState() => _CaregiverNavbarState();
}

class _CaregiverNavbarState extends State<CaregiverNavbar> {
  int _currentIndex = 0;

  void _onTap(int index) {
    if (index == 1 || index == 3) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: IndexedStack(
        index: _currentIndex == 2 ? 1 : 0,
        children: [
          CaregiverHomepage(currentIndex: _currentIndex, onTap: _onTap),
          _AppointmentsTabContent(currentIndex: _currentIndex, onTap: _onTap),
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
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<_AppointmentsTabContent> createState() => _AppointmentsTabContentState();
}

class _AppointmentsTabContentState extends State<_AppointmentsTabContent> {
  /// 0 = Available (متاحة), 1 = Booked (محجوزة). IndexedStack = instant, no transition.
  int _subIndex = 0;

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
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onSwitchToAvailable;

  @override
  State<_BookedTabContent> createState() => _BookedTabContentState();
}

class _BookedTabContentState extends State<_BookedTabContent> {
  /// 0 = Upcoming (القادمة), 1 = Previous (السابقة).
  int _bookedSubIndex = 0;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _bookedSubIndex,
      children: [
        BookedAppointmentsUpcoming(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          onSwitchToAvailable: widget.onSwitchToAvailable,
          onSwitchToPrevious: () => setState(() => _bookedSubIndex = 1),
        ),
        BookedAppointmentsPrevious(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          onSwitchToAvailable: widget.onSwitchToAvailable,
          onSwitchToUpcoming: () => setState(() => _bookedSubIndex = 0),
        ),
      ],
    );
  }
}
