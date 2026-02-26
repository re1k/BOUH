import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/viewAppointments/widgets/appointmentCard.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/dto/payment/RefundResponseDto.dart';
import 'package:bouh/services/payment/RefundService.dart';

/// Booked appointments – upcoming
///
///
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
  final RefundService _refundService = RefundService();
  bool _refundLoading = false;

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

  /// Map DTO to AppointmentCard.
  Widget _buildCardFor(UpcomingAppointmentDto dto, {required bool isFirst}) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);
    ImageProvider? profileImage;
    if (dto.doctorProfilePhotoURL != null &&
        dto.doctorProfilePhotoURL!.isNotEmpty) {
      profileImage = NetworkImage(dto.doctorProfilePhotoURL!);
    }
    VoidCallback? onActionTap;
    if (isFirst) {
      if (dto.meetingLink != null && dto.meetingLink!.trim().isNotEmpty) {
        final link = dto.meetingLink!.trim();
        onActionTap = () => _openMeetingLink(link);
      }
    } else {
      onActionTap = _refundLoading
          ? null
          : () async {
              final refundSucceeded = await _refundAppointment(dto);
              if (refundSucceeded) {
                /* jana code here*/
              }
            };
    }

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

  /// Format startTime and endTime for display.
  static String _formatTimeRange(String? start, String? end) {
    const suffix = 'مساءً';
    final s = start ?? '';
    final e = end ?? '';
    if (s.isEmpty && e.isEmpty) return '';
    if (e.isEmpty) return '$s $suffix';
    return '$s - $e $suffix';
  }

  Future<bool> _refundAppointment(UpcomingAppointmentDto dto) async {
    final pi = dto.paymentIntentId?.trim();

    if (pi == null || pi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ لا يوجد paymentIntentId لهذا الموعد")),
      );
      return false;
    }

    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE53935),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "تأكيد الإلغاء",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "هل تريد إلغاء الموعد واسترجاع المبلغ؟",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.55),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(54),
                          ),
                        ),
                        child: const Text(
                          "رجوع",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(54),
                          ),
                        ),
                        child: const Text(
                          "تأكيد",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return false;

    setState(() => _refundLoading = true);

    try {
      final RefundResponseDto resp = await _refundService.refund(
        paymentIntentId: pi,
      );

      if (!mounted) return false;

      setState(() {
        _list.removeWhere((x) => x.appointmentId == dto.appointmentId);
      });

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF4CAF50),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "تم الإلغاء بنجاح",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "تم إلغاء الموعد واسترجاع المبلغ بنجاح.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.55),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BColors.accent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(54),
                      ),
                    ),
                    child: const Text(
                      "حسناً",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return true; // ✅ Refund succeeded — friend uses this to cancel the appointment
    } catch (e) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFE53935),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "فشل الإلغاء",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "حدث خطأ أثناء إلغاء الموعد.\nيرجى المحاولة مرة أخرى.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.55),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(54),
                      ),
                    ),
                    child: const Text(
                      "حسناً",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return false; // ❌ Refund failed — friend does nothing
    } finally {
      if (mounted) setState(() => _refundLoading = false);
    }
  }
}
