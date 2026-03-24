import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/viewAppointments/widgets/appointmentCard.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/dto/payment/RefundResponseDto.dart';
import 'package:bouh/services/payment/RefundService.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';

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

  // Holds the active Firestore stream subscription so we can cancel it later.
  StreamSubscription<List<UpcomingAppointmentDto>>? _subscription;

  // Periodic timer that ticks every second to keep the UI in sync with the clock.
  // Each tick re-evaluates Join/Cancel button state and removes expired appointments.
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _prepareSessionAndLoad();
  }

  @override
  void didUpdateWidget(BookedAppointmentsUpcoming oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caregiverId != widget.caregiverId) {
      _prepareSessionAndLoad();
    }
  }

  Future<void> _prepareSessionAndLoad() async {
    final AuthSession _session = AuthSession.instance;
    await AuthService.instance.refreshSession();
    final String? _userId = _session.userId;
    if (!mounted) return;
    // Start the realtime stream for this user's appointments
    _subscribeToStream(_userId);
  }

  /// Cancel the old stream and timer, then start a fresh Firestore stream.
  /// After each list update, a precision timer is scheduled for the next boundary.
  void _subscribeToStream(String? caregiverId) {
    // Always cancel previous subscription and ticker before starting new ones
    _subscription?.cancel();
    _ticker?.cancel();

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

    // Subscribe to the Firestore realtime stream.
    // The stream fires immediately with current data, then again on every change.
    _subscription = _appointmentsService
        .streamUpcomingAppointments(caregiverId)
        .listen(
          (list) {
            if (!mounted) return;
            setState(() {
              _list = _removeExpired(list);
              _loading = false;
              _error = null;
            });
            // Start/restart the ticker so the UI stays in sync with the clock
            _startTicker();
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _error = e.toString();
              _list = [];
              _loading = false;
            });
          },
        );
  }

  /// Start a periodic timer that ticks every second.
  /// Each tick removes expired appointments and triggers a rebuild so that
  /// the Join/Cancel button always reflects the current time.
  void _startTicker() {
    _ticker?.cancel();
    if (_list.isEmpty) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _ticker?.cancel();
        return;
      }
      // Remove appointments whose endTime has passed and rebuild the UI.
      // The rebuild also re-evaluates _isJoinEnabled for each card.
      setState(() {
        final now = DateTime.now();
        _list.removeWhere((dto) {
          final end = AppointmentsService.parseAppointmentTime(
            dto.date,
            dto.endTime,
          );
          return end != null && !now.isBefore(end);
        });
      });
      // Stop ticking when there are no more appointments to track
      if (_list.isEmpty) _ticker?.cancel();
    });
  }

  /// Keep only appointments that have not ended yet (by device time).
  static List<UpcomingAppointmentDto> _removeExpired(
    List<UpcomingAppointmentDto> list,
  ) {
    final now = DateTime.now();
    return list.where((dto) {
      final end = AppointmentsService.parseAppointmentTime(
        dto.date,
        dto.endTime,
      );
      return end == null || now.isBefore(end);
    }).toList();
  }

  @override
  void dispose() {
    // Always cancel the stream and timer when the widget is removed from the tree.
    // This prevents memory leaks and errors from callbacks on a disposed widget.
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: Stack(
          children: [
            SafeArea(
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
                          SizedBox(
                            height: CaregiverBottomNav.barHeight + _cardGap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_loading) const BouhLoadingOverlay(showBarrier: false),
          ],
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

  Widget _buildCardList() {
    if (_loading) {
      return const SizedBox.shrink();
    }
    if (_error != null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'حدث خطأ، حاول مجددًا لاحقًا.',
            style: TextStyle(
              fontFamily: 'Markazi Text',
              fontSize: 16,
              color: BColors.darkGrey,
            ),
          ),
        ),
      );
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
    // Show Join only when this is the first card AND the appointment is active right now.
    // Active means: startTime <= now < endTime.
    // If the first card's appointment hasn't started yet, treat it like other cards (Cancel).
    final bool showJoin = isFirst && _isJoinEnabled(dto);
    final bool canCancel = !showJoin && _canCancelAppointment(dto);

    VoidCallback? onActionTap;
    String? actionLabel;
    Color? actionColor;

    if (showJoin) {
      actionLabel = 'انضمام';
      actionColor = BColors.accent;

      if (dto.meetingLink != null && dto.meetingLink!.trim().isNotEmpty) {
        final link = dto.meetingLink!.trim();
        onActionTap = () => _openMeetingLink(link);
      }
    } else if (canCancel) {
      actionLabel = 'الغاء';
      actionColor = _cancelRed;

      onActionTap = _refundLoading
          ? null
          : () async {
              final refundSucceeded = await _refundAppointment(dto);
              if (!refundSucceeded) return;

              try {
                await _appointmentsService.cancelAppointment(
                  appointmentId: dto.appointmentId,
                );

                if (!mounted) return;

                setState(() {
                  _list.removeWhere(
                    (x) => x.appointmentId == dto.appointmentId,
                  );
                });

                await showDialog(
                  context: context,
                  builder: (_) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      backgroundColor: BColors.white,
                      actionsAlignment: MainAxisAlignment.center,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'تم الإلغاء بنجاح',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: BColors.textDarkestBlue,
                        ),
                      ),
                      content: const Text(
                        'تم إلغاء الموعد واسترجاع المبلغ بنجاح.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: BColors.darkGrey,
                          height: 1.4,
                        ),
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BColors.primary,
                            foregroundColor: BColors.white,
                          ),
                          child: const Text('حسناً'),
                        ),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("فشل إلغاء الموعد: $e")));
              }
            };
    } else {
     // No action available (appointment not active yet and cancellation window passed).
      actionLabel = '';
     actionColor = BColors.darkGrey;
    }
    //  else {
    //   actionLabel = 'لا يمكن إلغاء الموعد قبل أقل من 30 دقيقة من وقت البدء';
    //   actionColor = Colors.grey;
    //   onActionTap = null;
    // }

    return AppointmentCard(
      doctorName: dto.doctorName ?? '',
      specialty: dto.doctorAreaOfKnowledge ?? '',
      childName: dto.childName ?? '',
      date: dateStr,
      time: timeStr,
      profileImage: profileImage,
      actionLabel: actionLabel,
      actionColor: actionColor,
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

  /// Join is active when startTime <= now < endTime (device time).
  static bool _isJoinEnabled(UpcomingAppointmentDto dto) {
    final now = DateTime.now();
    final start = AppointmentsService.parseAppointmentTime(
      dto.date,
      dto.startTime,
    );
    final end = AppointmentsService.parseAppointmentTime(dto.date, dto.endTime);
    if (start == null || end == null) return false;
    return !now.isBefore(start) && now.isBefore(end);
  }

  /// Cancellation is allowed only if there are more than 30 minutes
  /// before the appointment start time.
  static bool _canCancelAppointment(UpcomingAppointmentDto dto) {
    final now = DateTime.now();
    final start = AppointmentsService.parseAppointmentTime(
      dto.date,
      dto.startTime,
    );

    if (start == null) return false;

    final cancelDeadline = start.subtract(const Duration(minutes: 30));

    return now.isBefore(cancelDeadline);
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
        const SnackBar(content: Text("لا يوجد paymentIntentId لهذا الموعد")),
      );
      return false;
    }

    final confirm = await ConfirmationPopup.show(
      context,
      title: 'تأكيد الإلغاء',
      message: 'هل تريد إلغاء الموعد واسترجاع المبلغ؟',
      confirmText: 'تأكيد',
      cancelText: 'رجوع',
      isDestructive: true,
    );
    if (confirm != true) return false;

    setState(() => _refundLoading = true);

    try {
      await _refundService.refund(paymentIntentId: pi);
      return true;
    } catch (e) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: BColors.white,
            actionsAlignment: MainAxisAlignment.center,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'فشل الإلغاء',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: const Text(
              'حدث خطأ أثناء استرجاع المبلغ.\nيرجى المحاولة مرة أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: BColors.darkGrey,
                height: 1.4,
              ),
            ),
          ),
        ),
      );

      return false;
    } finally {
      if (mounted) setState(() => _refundLoading = false);
    }
  }
}
