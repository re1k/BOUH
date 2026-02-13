import 'package:flutter/material.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/caregiverHomepage/widgets/suggestedDoctorCard.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';

/// Appointments screen
///
/// Shows: title, segmented control (متاحة / محجوزة), search bar, filter button,
/// and a scrollable list of [SuggestedDoctorCard]. Uses existing bottom nav
/// with [currentIndex] and [onTap] so the المواعيد tab is active when shown
/// from [CaregiverNavbar].
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({
    super.key,
    this.currentIndex = 2,
    this.onTap,
    this.onSwitchToBooked,
  });

  /// Active bottom nav index (2 = المواعيد). Pass from shell.
  final int currentIndex;

  /// Called when a bottom nav item is tapped. Pass from shell.
  final ValueChanged<int>? onTap;

  /// Called when user taps "محجوزة" to switch to booked appointments. Optional.
  final VoidCallback? onSwitchToBooked;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Layout (match design.json & reference) ---
  static const double _titleTopPadding = 24;
  static const double _titleBottomPadding = 24;
  static const double _tabHeight = 44;
  static const double _tabRadius = 12;
  static const double _tabContainerPadding = 4;
  static const double _searchFilterGap = 8;
  static const double _searchHeight = 48;
  static const double _searchRadius = 12;
  static const double _filterButtonSize = 48;
  static const double _sectionGap = 24;
  static const double _cardGap = 16;

  /// Tab container background (inactive area).
  static const Color _tabContainerBg = Color(0xFFF0F2F4);
  static const Color _tabActiveBg = Color(0xFFFFFFFF);
  static const Color _tabActiveColor = Color(0xFF2C3E50);
  static const Color _tabInactiveColor = Color(0xFF7D8A96);
  static const Color _searchBorderColor = Color(0xFFE8EBED);
  static const Color _filterButtonBg = Color(0xFF5B8FA3);

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSegmentedControl(),
                      const SizedBox(height: _sectionGap),
                      _buildSearchAndFilter(),
                      const SizedBox(height: _sectionGap),
                      _buildDoctorList(),
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
              currentIndex: widget.currentIndex,
              onTap: widget.onTap,
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
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _tabActiveColor,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
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
          Expanded(child: _buildTabSegment(label: 'متاحة', active: true)),
          Expanded(
            child: GestureDetector(
              onTap: widget.onSwitchToBooked,
              behavior: HitTestBehavior.opaque,
              child: _buildTabSegment(label: 'محجوزة', active: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSegment({required String label, required bool active}) {
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

  Widget _buildSearchAndFilter() {
    // RTL: first child = right. Filter on RIGHT, search on LEFT.
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: _filterButtonSize,
          height: _filterButtonSize,
          decoration: BoxDecoration(
            color: _filterButtonBg,
            borderRadius: BorderRadius.circular(_searchRadius),
          ),
          child: const Icon(Icons.tune, color: BColors.white, size: 24),
        ),
        const SizedBox(width: _searchFilterGap),
        Expanded(
          child: SizedBox(
            height: _searchHeight,
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: InputDecorationTheme(
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
              ),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: BColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_searchRadius),
                    borderSide: const BorderSide(color: _searchBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_searchRadius),
                    borderSide: const BorderSide(color: _searchBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_searchRadius),
                    borderSide: const BorderSide(color: _searchBorderColor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_searchRadius),
                    borderSide: const BorderSide(color: _searchBorderColor),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(_searchRadius),
                    borderSide: const BorderSide(color: _searchBorderColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 22,
                    color: _tabInactiveColor,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Markazi Text',
                  fontSize: 14,
                  color: _tabActiveColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorList() {
    const mockDoctors = [
      (
        name: 'د. علي آل يحيى',
        specialty: 'خبير في علاج القلق والتوتر',
        rating: 5,
      ),
      (
        name: 'د. عبد العزيز الناصر',
        specialty: 'خبير في التعامل مع نوبات الغضب',
        rating: 4,
      ),
      (
        name: 'د. أحمد القحطاني',
        specialty: 'خبير في التعامل مع الصدمات',
        rating: 5,
      ),
      (
        name: 'د. موسى السبيعي',
        specialty: 'خبير في التعامل مع العزلة',
        rating: 4,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < mockDoctors.length; i++) ...[
          SuggestedDoctorCard(
            name: mockDoctors[i].name,
            specialty: mockDoctors[i].specialty,
            rating: mockDoctors[i].rating,
          ),
          if (i < mockDoctors.length - 1) const SizedBox(height: _cardGap),
        ],
      ],
    );
  }
}
