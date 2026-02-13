import 'package:flutter/material.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/viewAppointments/widgets/appointmentCard.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';

/// Booked appointments – upcoming
///
/// Layout (matches reference):
/// - Title "المواعيد" centered
/// - Top segmented control: "متاحة" (inactive), "محجوزة" (active)
/// - Secondary toggle: "القادمة" (active), "السابقة" (inactive)
/// - List of [AppointmentCard] (first = انضمام orange, others = الغاء red)
/// - Bottom nav with المواعيد tab active
class BookedAppointmentsUpcoming extends StatelessWidget {
  const BookedAppointmentsUpcoming({
    super.key,
    this.currentIndex = 2,
    this.onTap,
    this.onSwitchToAvailable,
    this.onSwitchToPrevious,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// Called when user taps "متاحة" to switch to available appointments. Optional.
  final VoidCallback? onSwitchToAvailable;

  /// Called when user taps "السابقة" to switch to previous booked. Optional.
  final VoidCallback? onSwitchToPrevious;

  // Match AvailableAppointments layout exactly (title, segmented control, section gaps).
  static const double _titleTopPadding = 24;
  static const double _titleBottomPadding = 24;
  static const double _titleFontSize = 24;
  static const double _tabHeight = 44;
  static const double _tabRadius = 12;
  static const double _tabContainerPadding = 4;
  static const Color _tabContainerBg = Color(0xFFF0F2F4);
  static const Color _tabActiveBg = Color(0xFFFFFFFF);
  static const Color _tabInactiveColor = Color(0xFF7D8A96);
  static const Color _tabActiveColor = Color(0xFF2C3E50);
  static const double _sectionGap = 24;
  static const double _contentPaddingH = 16;
  static const double _cardGap = 16;
  // القادمة / السابقة — exact size from reference: w=102, h=28, gap 8.
  static const double _filterButtonWidth = 102;
  static const double _filterButtonHeight = 28;
  static const double _filterButtonGap = 8;
  static const double _filterButtonRadius = 8;
  static const Color _filterActiveBg = Color(0xFF4F809A);
  static const Color _filterInactiveBg = Color(0xFFE0E0E0);
  static const Color _cancelRed = Color(0xFFE85D4F);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTitle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _contentPaddingH,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSegmentedControl(context),
                      const SizedBox(height: _sectionGap),
                      _buildFilterBar(),
                      const SizedBox(height: _sectionGap),
                      _buildCardList(),
                      SizedBox(height: CaregiverBottomNav.barHeight + _cardGap),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Material(
          clipBehavior: Clip.none,
          color: Colors.transparent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CaregiverBottomNav(
              currentIndex: currentIndex,
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(
        top: _titleTopPadding,
        bottom: _titleBottomPadding,
      ),
      child: Text(
        'المواعيد',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: _titleFontSize,
          fontWeight: FontWeight.w600,
          color: _tabActiveColor,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl(BuildContext context) {
    return Container(
      height: _tabHeight + _tabContainerPadding * 2,
      padding: const EdgeInsets.all(_tabContainerPadding),
      decoration: BoxDecoration(
        color: _tabContainerBg,
        borderRadius: BorderRadius.circular(_tabRadius + _tabContainerPadding),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSwitchToAvailable,
              behavior: HitTestBehavior.opaque,
              child: _buildSegment(label: 'متاحة', active: false),
            ),
          ),
          Expanded(child: _buildSegment(label: 'محجوزة', active: true)),
        ],
      ),
    );
  }

  Widget _buildSegment({required String label, required bool active}) {
    return Container(
      height: _tabHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _tabActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(_tabRadius),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: 16,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? _tabActiveColor : _tabInactiveColor,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _filterButtonWidth,
          height: _filterButtonHeight,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _filterActiveBg,
              borderRadius: BorderRadius.circular(_filterButtonRadius),
            ),
            child: Text(
              'القادمة',
              style: TextStyle(
                fontFamily: 'Markazi Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: _filterButtonGap),
        GestureDetector(
          onTap: onSwitchToPrevious,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: _filterButtonWidth,
            height: _filterButtonHeight,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _filterInactiveBg,
                borderRadius: BorderRadius.circular(_filterButtonRadius),
              ),
              child: Text(
                'السابقة',
                style: TextStyle(
                  fontFamily: 'Markazi Text',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _tabInactiveColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        AppointmentCard(
          doctorName: 'د. موسى السبيعي',
          specialty: 'التعامل مع العزلة',
          childName: 'بسام',
          date: '8/12/2025',
          time: '8:00 - 8:30 مساءً',
          actionLabel: 'انضمام',
          actionColor: BColors.accent,
        ),
        SizedBox(height: _cardGap),
        AppointmentCard(
          doctorName: 'د. عبد العزيز الناصر',
          specialty: 'خبير التعامل مع نوبات الغضب',
          childName: 'ليان',
          date: '10/12/2025',
          time: '9:00 - 9:30 صباحاً',
          actionLabel: 'الغاء',
          actionColor: _cancelRed,
        ),
        SizedBox(height: _cardGap),
        AppointmentCard(
          doctorName: 'د. محمد سعد',
          specialty: 'خبير التعامل مع القلق',
          childName: 'خزامی',
          date: '12/12/2025',
          time: '4:00 - 4:45 مساءً',
          actionLabel: 'الغاء',
          actionColor: _cancelRed,
        ),
      ],
    );
  }
}
