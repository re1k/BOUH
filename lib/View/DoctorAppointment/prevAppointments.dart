import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

import 'package:bouh/View/DoctorAppointment/available_schedule_screen.dart';
import 'package:bouh/View/HomePage/widgets/appointment_card.dart';

import 'package:bouh/View/DoctorAppointment/upAppointments.dart';

class PrevAppointmentsScreen extends StatelessWidget {
  const PrevAppointmentsScreen({super.key});

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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SegmentedTabs(
                  selected: _AppointmentsTab.past,
                  onUpcomingTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen(),
                      ),
                    );
                  },
                  onPastTap: () {},
                ),
              ),

              const SizedBox(height: 16),

              // Backend hook: replace static cards with data from controller.
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: const [
                    AppointmentCard(
                      date: '11/11/2025',
                      time: '7:30 مساءً',
                      caregiverName: 'فرح الشهري',
                      childName: 'تالا',
                      buttonType: AppointmentButtonType.none,
                    ),
                    AppointmentCard(
                      date: '11/11/2025',
                      time: '8:00 مساءً',
                      caregiverName: 'حسام العتيبي',
                      childName: 'ريم',
                      buttonType: AppointmentButtonType.none,
                    ),
                    AppointmentCard(
                      date: '13/11/2025',
                      time: '7:00 مساءً',
                      caregiverName: 'عبدالرحمن أحمد',
                      childName: 'خالد',
                      buttonType: AppointmentButtonType.none,
                    ),
                    SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          ),
        ),

        // add remaz navBar
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          selectedItemColor: BColors.primary,
          unselectedItemColor: BColors.darkGrey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'المواعيد',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          ],
        ),
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
