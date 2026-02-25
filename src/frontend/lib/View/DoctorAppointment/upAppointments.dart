import 'package:bouh/View/DoctorAppointment/prevAppointments.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

import 'package:bouh/View/DoctorAppointment/available_schedule_screen.dart';
import 'package:bouh/View/HomePage/widgets/appointment_card.dart';
import 'package:bouh/View/HomePage/widgets/doctorBottomNav.dart';

/// Doctor appointments screen (المواعيد tab). When used inside [DoctorNavbar],
/// pass [currentIndex], [onTap], and optionally [onSwitchToPrevious].
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({
    super.key,
    this.currentIndex = 1,
    this.onTap,
    this.onSwitchToPrevious,
  });

  /// Active bottom nav index (1 = appointments). Pass from shell.
  final int currentIndex;

  /// Called when a bottom nav item is tapped. Pass from shell.
  final ValueChanged<int>? onTap;

  /// When provided (e.g. from [DoctorNavbar]), tapping "السابقة" switches
  /// to previous appointments without Navigator. When null, uses Navigator.pushReplacement.
  final VoidCallback? onSwitchToPrevious;

  static const double _cardGap = 16;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.lightGrey,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _TopHeader(
                // Backend hook: navigate to the availability scheduling screen.
                // If later you need to pass doctorId/userId, add it here and in AvailableScheduleScreen constructor.
                onCalendarTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AvailableScheduleScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Backend hook: tab switcher should decide which dataset to load (upcoming vs past).
              // For now, upcoming is the current screen; past navigates to PrevAppointmentsScreen.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SegmentedTabs(
                  selected: _AppointmentsTab.upcoming,
                  onUpcomingTap: () {
                    // Future: trigger fetchUpcomingAppointments() and refresh UI if you convert to StatefulWidget.
                  },
                  onPastTap: () {
                    if (onSwitchToPrevious != null) {
                      onSwitchToPrevious!();
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrevAppointmentsScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    DoctorBottomNav.barHeight + _cardGap,
                  ),
                  children: const [
                    AppointmentCard(
                      // Backend: date/time should come from the appointment entity (and be formatted).
                      date: '8/12/2025',
                      time: '8:00 - 8:30 مساءً',
                      caregiverName: 'جنى الشريف',
                      childName: 'بسام',
                      // Backend: map appointment status
                      buttonType: AppointmentButtonType.start,
                    ),
                    AppointmentCard(
                      date: '13/12/2025',
                      time: '8:00 - 8:30 مساءً',
                      caregiverName: 'سعد إبراهيم',
                      childName: 'مهند',
                      buttonType: AppointmentButtonType.cancel,
                    ),
                    AppointmentCard(
                      date: '19/12/2025',
                      time: '9:00 - 9:30 مساءً',
                      caregiverName: 'جمانه العيسى',
                      childName: 'سارة',
                      buttonType: AppointmentButtonType.cancel,
                    ),
                    SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),

        // replace with remaz navBar
        bottomNavigationBar: onTap != null
            ? Material(
                clipBehavior: Clip.none,
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: DoctorBottomNav(
                    currentIndex: currentIndex,
                    onTap: onTap,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final VoidCallback onCalendarTap;

  const _TopHeader({required this.onCalendarTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          InkWell(
            onTap: onCalendarTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: BColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'المواعيد',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: BColors.textDarkestBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

enum _AppointmentsTab { upcoming, past }

class _SegmentedTabs extends StatelessWidget {
  final _AppointmentsTab selected;
  final VoidCallback onUpcomingTap;
  final VoidCallback onPastTap;

  const _SegmentedTabs({
    required this.selected,
    required this.onUpcomingTap,
    required this.onPastTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: BColors.softGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              title: 'القادمة',
              selected: selected == _AppointmentsTab.upcoming,
              onTap: onUpcomingTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _TabPill(
              title: 'السابقة',
              selected: selected == _AppointmentsTab.past,
              onTap: onPastTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _TabPill({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: selected ? BColors.textDarkestBlue : BColors.darkGrey,
          ),
        ),
      ),
    );
  }
}
