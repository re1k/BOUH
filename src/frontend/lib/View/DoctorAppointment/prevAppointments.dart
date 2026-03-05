import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/DoctorAppointment/AvailableScheduleScreen.dart';
import 'package:bouh/View/DoctorAppointment/upAppointments.dart';
import 'package:bouh/View/HomePage/widgets/appointment_card.dart';
import 'package:bouh/View/HomePage/widgets/doctorBottomNav.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/widgets/loading_overlay.dart';

class PrevAppointmentsScreen extends StatefulWidget {
  const PrevAppointmentsScreen({
    super.key,
    this.currentIndex = 1,
    this.onTap,
    this.onSwitchToUpcoming,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onSwitchToUpcoming;

  @override
  State<PrevAppointmentsScreen> createState() => _PrevAppointmentsScreenState();
}

class _PrevAppointmentsScreenState extends State<PrevAppointmentsScreen> {
  List<UpcomingAppointmentDto> _list = [];
  List<UpcomingAppointmentDto> _upcomingCache = [];
  bool _loading = false;
  String? _error;

  final AppointmentsService _appointmentsService = AppointmentsService();
  StreamSubscription<
    (List<UpcomingAppointmentDto>, List<UpcomingAppointmentDto>)
  >?
  _subscription;
  Timer? _ticker;

  static const double _cardGap = 16;

  @override
  void initState() {
    super.initState();
    _prepareSessionAndLoad();
  }

  @override
  void didUpdateWidget(PrevAppointmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        _upcomingCache = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _list = [];
      _upcomingCache = [];
    });

    _subscription = _appointmentsService
        .streamPreviousAppointmentsByDoctor(doctorId)
        .listen(
          (data) {
            if (!mounted) return;
            setState(() {
              _list = data.$1;
              _upcomingCache = data.$2;
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
              _upcomingCache = [];
              _loading = false;
            });
          },
        );
  }

  /// Every second move ended appointments from _upcomingCache into _list
  void _startTicker() {
    _ticker?.cancel();
    if (_upcomingCache.isEmpty) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _ticker?.cancel();
        return;
      }
      final now = DateTime.now();
      bool changed = false;
      setState(() {
        _upcomingCache.removeWhere((dto) {
          final end = AppointmentsService.parseAppointmentTime(
            dto.date,
            dto.endTime,
          );
          if (end == null || now.isBefore(end)) return false;
          _list.add(dto);
          changed = true;
          return true;
        });
        if (changed) {
          _list.sort((a, b) {
            final ta = AppointmentsService.parseAppointmentTime(
              a.date,
              a.startTime,
            );
            final tb = AppointmentsService.parseAppointmentTime(
              b.date,
              b.startTime,
            );
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1;
            if (tb == null) return -1;
            return tb.compareTo(ta);
          });
        }
      });
      if (_upcomingCache.isEmpty) _ticker?.cancel();
    });
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
                      selected: _AppointmentsTab.past,
                      onUpcomingTap: () {
                        if (widget.onSwitchToUpcoming != null) {
                          widget.onSwitchToUpcoming!();
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AppointmentsScreen(),
                            ),
                          );
                        }
                      },
                      onPastTap: () {},
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
            'لا توجد مواعيد سابقة',
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
      children.add(_buildCard(_list[i]));
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

  Widget _buildCard(UpcomingAppointmentDto dto) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);
    return AppointmentCard(
      date: dateStr,
      time: timeStr,
      caregiverName: dto.caregiverName ?? '',
      childName: dto.childName ?? '',
      buttonType: AppointmentButtonType.none,
    );
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
