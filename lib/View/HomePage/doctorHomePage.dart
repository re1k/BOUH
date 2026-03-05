import 'package:flutter/material.dart';
import 'package:bouh/View/HomePage/widgets/appointment_card.dart';
import 'package:bouh/theme/base_themes/colors.dart';

class DoctorHomePage extends StatelessWidget {
  const DoctorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.lightGrey,
        body: Column(
          children: [
            _header(),
            const SizedBox(height: 16),
            _todayHeader(),
            const SizedBox(height: 12),

            // Backend hook: replace this with today's appointments from controller.
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  AppointmentCard(
                    date: '8/12/2025',
                    time: '4:00 - 4:30 مساءً',
                    caregiverName: 'جنى الشريف',
                    childName: 'بسام',
                    buttonType: AppointmentButtonType.start,
                  ),
                  AppointmentCard(
                    date: '8/12/2025',
                    time: '8:00 - 8:30 مساءً',
                    caregiverName: 'سعد إبراهيم',
                    childName: 'مهند',
                    buttonType: AppointmentButtonType.cancel,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(20),
      color: BColors.primary,
      child: Row(
        children: [
          // Backend hook: replace AssetImage with the logged-in doctor's profile image URL if available.
          // Example: NetworkImage(profileUrl) + placeholder fallback.
          const CircleAvatar(
            radius: 28,
            backgroundImage: AssetImage('assets/images/doctor.png'),
          ),
          const SizedBox(width: 12),

          // Backend hook: doctor name and rating should come from user profile API.
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'مرحباً بعودتك، أهلاً علي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  Icon(Icons.star_half, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text('4.5', style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            'مواعيدك اليوم',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Backend hook: this can navigate to the AppointmentsScreen (upcoming list)
          // or apply a filter for the full list.
          Row(
            children: [
              Text('رؤية الكل', style: TextStyle(color: BColors.darkGrey)),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 14, color: BColors.darkGrey),
            ],
          ),
        ],
      ),
    );
  }
}
