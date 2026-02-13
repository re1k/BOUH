import 'package:flutter/material.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/viewAppointments/widgets/appointmentCard.dart';
import 'widgets/suggestedDoctorCard.dart';
import 'widgets/caregiverBottomNav.dart';

/// When used inside [CaregiverNavbar], pass [currentIndex] and [onTap] so the
/// bottom nav reflects the active tab and handles tab changes.
class CaregiverHomepage extends StatelessWidget {
  const CaregiverHomepage({super.key, this.currentIndex = 0, this.onTap});

  /// Active bottom nav index (0 = home). Used when embedded in shell.
  final int currentIndex;

  /// Called when a bottom nav item is tapped. Used when embedded in shell.
  final ValueChanged<int>? onTap;

  static const double _sectionGap = 24;
  static const double _cardGap = 16;
  static const double _headerBaseHeight = 130;

  /// Extra padding from the right (RTL) so section titles don't sit flush to the edge.
  static const double _contentPaddingRight = 24;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              height: _headerBaseHeight + topPadding,
              child: _buildHeader(context, topPadding),
            ),
            _buildContent(context, topPadding),
          ],
        ),
        bottomNavigationBar: Material(
          clipBehavior: Clip.none,
          color: Colors.transparent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CaregiverBottomNav(currentIndex: currentIndex, onTap: onTap),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    return Container(
      width: double.infinity,
      height: _headerBaseHeight + topPadding,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image is set via DecorationImage
          Positioned(
            top: topPadding + 24,
            right: 26,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحبًا بعودتك،',
                  style: TextStyle(
                    fontFamily: 'Markazi Text',
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: BColors.white,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Text(
                    'أهلًا لبى',
                    style: TextStyle(
                      fontFamily: 'Markazi Text',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: BColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double topPadding) {
    return Positioned(
      left: 0,
      right: 0,
      top: _headerBaseHeight + topPadding,
      bottom: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          _contentPaddingRight,
          CaregiverBottomNav.barHeight + _cardGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionWithViewAll('مواعيدك اليوم'),
            const SizedBox(height: 12),
            const AppointmentCard(
              doctorName: 'د. موسى السبيعي',
              specialty: 'التعامل مع العزلة',
              childName: ' بسام',
              date: '8/12/2025',
              time: '8:00 - 8:30 مساء',
            ),
            const SizedBox(height: _sectionGap),
            _buildSectionWithViewAll('الأطباء المقترحين لبسام'),
            const SizedBox(height: 12),
            const SuggestedDoctorCard(
              name: 'د. علي آل يحيى',
              specialty: 'خبير علاج القلق والتوتر',
              rating: 4,
            ),
            const SizedBox(height: _cardGap),
            const SuggestedDoctorCard(
              name: 'د. عبد العزيز الناصر',
              specialty: 'خبير التعامل مع نوبات الغضب',
              rating: 3,
            ),
            const SizedBox(height: _sectionGap),
            _buildSectionWithViewAll('الأطباء المقترحين لدانا'),
            const SizedBox(height: 12),
            const SuggestedDoctorCard(
              name: 'د. أحمد القحطاني',
              specialty: 'خبير التعامل مع الصدمات',
              rating: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithViewAll(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Markazi Text',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: BColors.textDarkestBlue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'رؤية الكل',
                style: TextStyle(
                  fontFamily: 'Markazi Text',
                  fontSize: 13,
                  color: BColors.textBlack,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: BColors.textBlack),
            ],
          ),
        ),
      ],
    );
  }
}
