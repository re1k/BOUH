import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/viewAppointments/widgets/appointmentCard.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';

/// Booked appointments – upcoming
///
/// Layout (matches reference):
/// - Title "المواعيد" centered
/// - Top segmented control: "متاحة" (inactive), "محجوزة" (active)
/// - Secondary toggle: "القادمة" (active), "السابقة" (inactive)
/// - List of [AppointmentCard] (first = انضمام orange, others = الغاء red)
/// - Bottom nav with المواعيد tab active
///
/// Data: optional [caregiverId] from session/caller; when set, loads real data from backend.
class BookedAppointmentsUpcoming extends StatefulWidget {
  const BookedAppointmentsUpcoming({
    super.key,
    this.caregiverId,
    this.currentIndex = 2,
    this.onTap,
    this.onSwitchToAvailable,
    this.onSwitchToPrevious,
  });

  /// When set, upcoming appointments are loaded from backend for this caregiver.
  final String? caregiverId;

  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// Called when user taps "متاحة" to switch to available appointments. Optional.
  final VoidCallback? onSwitchToAvailable;

  /// Called when user taps "السابقة" to switch to previous booked. Optional.
  final VoidCallback? onSwitchToPrevious;

  @override
  State<BookedAppointmentsUpcoming> createState() =>
      _BookedAppointmentsUpcomingState();
}

class _BookedAppointmentsUpcomingState
    extends State<BookedAppointmentsUpcoming> {
  // Data from backend: list of upcoming appointment DTOs.
  List<UpcomingAppointmentDto> _list = [];
  bool _loading = false;
  String? _error;

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
  static const double _filterButtonWidth = 102;
  static const double _filterButtonHeight = 28;
  static const double _filterButtonGap = 8;
  static const double _filterButtonRadius = 8;
  static const Color _filterActiveBg = Color(0xFF4F809A);
  static const Color _filterInactiveBg = Color(0xFFE0E0E0);
  static const Color _cancelRed = Color(0xFFE85D4F);

  final AppointmentsService _appointmentsService = AppointmentsService();

  @override
  void initState() {
    super.initState();
    _loadIfCaregiverSet(widget.caregiverId);
  }

  @override
  void didUpdateWidget(BookedAppointmentsUpcoming oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caregiverId != widget.caregiverId) {
      _loadIfCaregiverSet(widget.caregiverId);
    }
  }

  /// When caregiverId is set, call backend; on success set list and clear error; on failure set error and clear list.
  void _loadIfCaregiverSet(String? caregiverId) {
    if (caregiverId == null || caregiverId.isEmpty) {
      setState(() {
        _list = [];
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _list = [];
    });
    _appointmentsService
        .getUpcomingAppointments(caregiverId)
        .then((list) {
          if (mounted) {
            setState(() {
              _list = list;
              _loading = false;
              _error = null;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _error = e.toString();
              _list = [];
              _loading = false;
            });
          }
        });
  }

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
              currentIndex: widget.currentIndex,
              onTap: widget.onTap ?? (_) {},
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
              onTap: widget.onSwitchToAvailable,
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
          onTap: widget.onSwitchToPrevious,
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

  /// If loading show CircularProgressIndicator; if error show Text(error); if list empty show SizedBox.shrink(); else Column of AppointmentCard.
  /// First card: actionLabel "انضمام", BColors.accent; rest: "الغاء", _cancelRed.
  Widget _buildCardList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Text(_error!);
    }
    if (_list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'لا توجد مواعيد قادمة',
            style: TextStyle(
              fontFamily: 'Markazi Text',
              fontSize: 16,
              color: BColors.darkGrey,
            ),
          ),
        ),
      );
    }
    final children = <Widget>[];
    for (var i = 0; i < _list.length; i++) {
      if (i > 0) children.add(const SizedBox(height: _cardGap));
      children.add(_buildCardFor(_list[i], isFirst: i == 0));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Map DTO to AppointmentCard. For انضمام (first card), onActionTap opens meetingLink if present.
  Widget _buildCardFor(UpcomingAppointmentDto dto, {required bool isFirst}) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);
    ImageProvider? profileImage;
    if (dto.doctorProfilePhotoURL != null &&
        dto.doctorProfilePhotoURL!.isNotEmpty) {
      profileImage = NetworkImage(dto.doctorProfilePhotoURL!);
    }
    VoidCallback? onActionTap;
    if (isFirst &&
        dto.meetingLink != null &&
        dto.meetingLink!.trim().isNotEmpty) {
      final link = dto.meetingLink!.trim();
      onActionTap = () => _openMeetingLink(link);
    }
    // When actionLabel is "الغاء" (cancel), the appointment's paymentIntentId uniquely
    // identifies the payment for this appointment. It can later be used for refund
    return AppointmentCard(
      doctorName: dto.doctorName ?? '',
      specialty: dto.doctorAreaOfKnowledge ?? '',
      childName: dto.childName ?? '',
      date: dateStr,
      time: timeStr,
      profileImage: profileImage,
      actionLabel: isFirst ? 'انضمام' : 'الغاء',
      actionColor: isFirst ? BColors.accent : _cancelRed,
      onActionTap: onActionTap,
    );
  }

  Future<void> _openMeetingLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Convert backend date yyyy-MM-dd to display d/m/y.
  static String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    final y = parts[0];
    final m = parts[1];
    final d = parts[2];
    return '$d/$m/$y';
  }

  /// Format startTime and endTime for display, appending صباحاً or مساءً from first time hour (24h).
  static String _formatTimeRange(String? start, String? end) {
    final s = start ?? '';
    final e = end ?? '';
    final suffix = _suffixFromTimeString(s);
    if (s.isEmpty && e.isEmpty) return '';
    if (e.isEmpty) return '$s $suffix';
    return '$s - $e $suffix';
  }

  static String _suffixFromTimeString(String time) {
    final match = RegExp(r'^(\d{1,2})').firstMatch(time);
    if (match == null) return 'مساءً';
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    return hour < 12 ? 'صباحًا' : 'مساءً';
  }
}
