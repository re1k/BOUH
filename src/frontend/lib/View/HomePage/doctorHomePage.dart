import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bouh/View/HomePage/widgets/appointment_card.dart';
import 'package:bouh/View/HomePage/widgets/doctorBottomNav.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/services/payment/RefundService.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';

/// When used inside [DoctorNavbar], pass [currentIndex] and [onTap] so the
/// bottom nav reflects the active tab and handles tab changes.
class DoctorHomePage extends StatefulWidget {
  const DoctorHomePage({super.key, this.currentIndex = 0, this.onTap});

  /// Active bottom nav index (0 = home). Used when embedded in shell.
  final int currentIndex;

  /// Called when a bottom nav item is tapped. Used when embedded in shell.
  final ValueChanged<int>? onTap;

  @override
  State<DoctorHomePage> createState() => DoctorHomePageState();
}

/// State exposed so [DoctorNavbar] can trigger refresh when home is tapped.
class DoctorHomePageState extends State<DoctorHomePage> {
  static const double _cardGap = 16;
  static const double _headerBaseHeight = 130;

  List<UpcomingAppointmentDto> _todayList = [];
  bool _loading = false;
  String? _error;
  bool _refundLoading = false;

  final AppointmentsService _appointmentsService = AppointmentsService();
  final RefundService _refundService = RefundService();
  StreamSubscription<List<UpcomingAppointmentDto>>? _subscription;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _prepareSessionAndLoad();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  /// Call when home nav is tapped to refresh today's appointments.
  void refresh() {
    _prepareSessionAndLoad();
  }

  Future<void> _prepareSessionAndLoad() async {
    await AuthService.instance.refreshSession();
    final String? doctorId = AuthSession.instance.userId;
    if (!mounted) return;
    _subscribeToStream(doctorId);
  }

  void _subscribeToStream(String? doctorId) {
    _subscription?.cancel();
    _ticker?.cancel();

    if (doctorId == null || doctorId.isEmpty) {
      setState(() {
        _todayList = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _todayList = [];
    });

    _subscription = _appointmentsService
        .streamUpcomingAppointmentsByDoctor(doctorId)
        .listen(
          (list) {
            if (!mounted) return;
            setState(() {
              _todayList = _filterTodayAndRemoveExpired(list);
              _loading = false;
              _error = null;
            });
            _startTicker();
          },
          onError: (e) {
            if (!mounted) return;
            setState(() {
              _error = e.toString();
              _todayList = [];
              _loading = false;
            });
          },
        );
  }

  static List<UpcomingAppointmentDto> _filterTodayAndRemoveExpired(
    List<UpcomingAppointmentDto> list,
  ) {
    final now = DateTime.now();
    final todayString =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return list.where((dto) {
      if (dto.date != todayString) return false;
      final end = AppointmentsService.parseAppointmentTime(
        dto.date,
        dto.endTime,
      );
      return end == null || now.isBefore(end);
    }).toList();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (_todayList.isEmpty) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _ticker?.cancel();
        return;
      }
      setState(() {
        final now = DateTime.now();
        _todayList.removeWhere((dto) {
          final end = AppointmentsService.parseAppointmentTime(
            dto.date,
            dto.endTime,
          );
          return end != null && !now.isBefore(end);
        });
      });
      if (_todayList.isEmpty) _ticker?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.lightGrey,
        body: Stack(
          children: [
            Column(
              children: [
                _header(context, topPadding),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      DoctorBottomNav.barHeight + _cardGap,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _todayHeader(),
                        const SizedBox(height: 12),
                        _buildTodayList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_loading) const BouhLoadingOverlay(showBarrier: false),
          ],
        ),
        bottomNavigationBar: widget.onTap != null
            ? Material(
                clipBehavior: Clip.none,
                color: Colors.transparent,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: DoctorBottomNav(
                    currentIndex: widget.currentIndex,
                    onTap: widget.onTap!,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildTodayList() {
    if (_loading) {
      return const SizedBox.shrink();
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
    if (_todayList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'لا يوجد مواعيد اليوم',
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
    for (var i = 0; i < _todayList.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 14));
      children.add(_buildCard(_todayList[i], isFirst: i == 0));
    }
    children.add(const SizedBox(height: 14));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Same Join/Cancel rules as Upcoming: Join only for first card when in time window.
  Widget _buildCard(UpcomingAppointmentDto dto, {required bool isFirst}) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);
    final showJoin = isFirst && _isJoinEnabled(dto);
    final buttonType = showJoin
        ? AppointmentButtonType.start
        : AppointmentButtonType.cancel;

    VoidCallback? onActionTap;
    if (showJoin) {
      if (dto.meetingLink != null && dto.meetingLink!.trim().isNotEmpty) {
        final link = dto.meetingLink!.trim();
        onActionTap = () => _openMeetingLink(link);
      }
    } else {
      onActionTap = _refundLoading
          ? null
          : () async {
              final ok = await _refundAppointment(dto);
              if (ok && mounted) {
                setState(() {
                  _todayList.removeWhere(
                    (x) => x.appointmentId == dto.appointmentId,
                  );
                });
              }
            };
    }

    return AppointmentCard(
      date: dateStr,
      time: timeStr,
      caregiverName: dto.caregiverName ?? '',
      childName: dto.childName ?? '',
      buttonType: buttonType,
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

  static String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length != 3) return date;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

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
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد paymentIntentId لهذا الموعد')),
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
      if (!mounted) return true;
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
                fontFamily: 'Markazi Text',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: const Text(
              'تم إلغاء الموعد واسترجاع المبلغ بنجاح.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Markazi Text',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Markazi Text',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
                fontFamily: 'Markazi Text',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
            content: const Text(
              'حدث خطأ أثناء إلغاء الموعد.\nيرجى المحاولة مرة أخرى.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Markazi Text',
                fontSize: 15,
                color: BColors.darkGrey,
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BColors.validationError,
                  foregroundColor: BColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'حسناً',
                  style: TextStyle(
                    fontFamily: 'Markazi Text',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _refundLoading = false);
    }
  }

  Widget _header(BuildContext context, double topPadding) {
    return Container(
      height: _headerBaseHeight + topPadding,
      padding: EdgeInsets.only(
        top: topPadding + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
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
                  fontFamily: 'Markazi Text',
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
                  Text(
                    '4.5',
                    style: TextStyle(
                      fontFamily: 'Markazi Text',
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          'مواعيدك اليوم',
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
              SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: BColors.textBlack,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
