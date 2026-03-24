import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/DoctorAppointment/prevAppointments.dart';
import 'package:bouh/View/DoctorAppointment/AvailableScheduleScreen.dart';
import 'package:bouh/View/HomePage/widgets/appointment_card.dart';
import 'package:bouh/View/HomePage/widgets/doctorBottomNav.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/services/payment/RefundService.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    this.currentIndex = 1,
    this.onTap,
    this.onSwitchToPrevious,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onSwitchToPrevious;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<UpcomingAppointmentDto> _list = [];
  bool _loading = false;
  String? _error;
  bool _refundLoading = false;

  final AppointmentsService _appointmentsService = AppointmentsService();
  final RefundService _refundService = RefundService();
  StreamSubscription<List<UpcomingAppointmentDto>>? _subscription;
  Timer? _ticker;

  static const double _cardGap = 16;

  @override
  void initState() {
    super.initState();
    _prepareSessionAndLoad();
  }

  @override
  void didUpdateWidget(AppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {}
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

    _subscription = _appointmentsService
        .streamUpcomingAppointmentsByDoctor(doctorId)
        .listen(
          (list) {
            if (!mounted) return;
            setState(() {
              _list = _removeExpired(list);
              _loading = false;
              _error = null;
            });
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

  void _startTicker() {
    _ticker?.cancel();
    if (_list.isEmpty) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _ticker?.cancel();
        return;
      }
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
      if (_list.isEmpty) _ticker?.cancel();
    });
  }

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
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.lightGrey,
        body: Stack(
          children: [
            SafeArea(
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
                      selected: _AppointmentsTab.upcoming,
                      onUpcomingTap: () {},
                      onPastTap: () {
                        if (widget.onSwitchToPrevious != null) {
                          widget.onSwitchToPrevious!();
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
                  Expanded(child: _buildList()),
                ],
              ),
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

  Widget _buildList() {
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
      if (i > 0) children.add(const SizedBox(height: 14));
      children.add(_buildCard(_list[i], isFirst: i == 0));
    }
    children.add(const SizedBox(height: 14));
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        DoctorBottomNav.barHeight + _cardGap,
      ),
      children: children,
    );
  }

  Widget _buildCard(UpcomingAppointmentDto dto, {required bool isFirst}) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);

    final showJoin = isFirst && _isJoinEnabled(dto);
    final canCancel = !showJoin && _canCancelAppointment(dto);

    AppointmentButtonType? buttonType;
    VoidCallback? onActionTap;

    if (showJoin) {
      buttonType = AppointmentButtonType.start;

      if (dto.meetingLink != null && dto.meetingLink!.trim().isNotEmpty) {
        final link = dto.meetingLink!.trim();
        onActionTap = () => _openMeetingLink(link);
      }
    } else if (canCancel) {
      buttonType = AppointmentButtonType.cancel;

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
    }
    print('appointment: ${dto.appointmentId}');
    print('showJoin: $showJoin');
    print('canCancel: $canCancel');
    print('start: ${dto.startTime}, end: ${dto.endTime}');
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
                  fontFamily: 'Markazi Text',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
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
            fontFamily: 'Markazi Text',
            fontSize: 16,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? BColors.textDarkestBlue : BColors.darkGrey,
          ),
        ),
      ),
    );
  }
}
