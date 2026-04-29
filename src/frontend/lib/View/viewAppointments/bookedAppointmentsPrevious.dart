import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/View/RateDoctor/rate_doctor_bottom_sheet.dart'; // <Rating feature>
import 'package:bouh/widgets/loading_overlay.dart';
import 'widgets/previousBookedAppointmentCard.dart';
import 'package:bouh/config/slot_config.dart';

/// Booked appointments – previous.
///
/// Same structure and data model as Upcoming: uses [UpcomingAppointmentDto],
/// loads via [AppointmentsService.getPreviousAppointments]. Status displayed as
/// Attended (تم الحضور) / Absent (لم يتم الحضور).
class BookedAppointmentsPrevious extends StatefulWidget {
  const BookedAppointmentsPrevious({
    super.key,
    this.caregiverId,
    this.currentIndex = 2,
    this.onTap,
    this.onSwitchToAvailable,
    this.onSwitchToUpcoming,
  });

  /// When set, previous appointments are loaded from backend for this caregiver.
  final String? caregiverId;

  final int currentIndex;
  final ValueChanged<int>? onTap;

  /// Called when user taps "متاحة" in the top segmented control. Optional.
  final VoidCallback? onSwitchToAvailable;

  /// Called when user taps "القادمة" in the filter bar. Optional.
  final VoidCallback? onSwitchToUpcoming;

  @override
  State<BookedAppointmentsPrevious> createState() =>
      _BookedAppointmentsPreviousState();
}

class _BookedAppointmentsPreviousState
    extends State<BookedAppointmentsPrevious> {
  List<UpcomingAppointmentDto> _list = [];
  bool _loading = false;
  String? _error;

  final AppointmentsService _appointmentsService = AppointmentsService();

  StreamSubscription<
    (List<UpcomingAppointmentDto>, List<UpcomingAppointmentDto>)
  >?
  _subscription;

  // Upcoming list from last stream event; ticker moves ended ones into _list (no HTTP).
  List<UpcomingAppointmentDto> _upcomingCache = [];
  Timer? _ticker;

  // One Firestore listener per distinct doctorId in the current list.
  // Triggers a re-fetch when a doctor updates their profile photo.
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
  _doctorListeners = {};

  @override
  void initState() {
    super.initState();
    _prepareSessionAndLoad();
  }

  @override
  void didUpdateWidget(BookedAppointmentsPrevious oldWidget) {
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
    // Start the realtime stream for this user's previous appointments
    _subscribeToStream(_userId);
  }

  void _subscribeToStream(String? caregiverId) {
    _subscription?.cancel();
    _ticker?.cancel();
    for (final sub in _doctorListeners.values) {
      sub.cancel();
    }
    _doctorListeners.clear();

    if (caregiverId == null || caregiverId.isEmpty) {
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
        .streamPreviousAppointments(caregiverId)
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
            _updateDoctorListeners(_list);
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

  /// Keep doctor-photo listeners in sync with the current list.
  /// Called after every stream update.
  void _updateDoctorListeners(List<UpcomingAppointmentDto> list) {
    final currentIds = list
        .map((d) => d.doctorId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    // Cancel listeners for doctors no longer in the list
    _doctorListeners.keys
        .where((id) => !currentIds.contains(id))
        .toList()
        .forEach((id) => _doctorListeners.remove(id)?.cancel());

    // Add a listener for each new doctorId (skip the initial snapshot so we
    // only react to actual changes, not the first read).
    for (final doctorId in currentIds) {
      if (_doctorListeners.containsKey(doctorId)) continue;
      _doctorListeners[doctorId] = FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .snapshots()
          .skip(1)
          .listen((_) => _refetchOnDoctorChange());
    }
  }

  /// Called when any watched doctor document changes.
  /// Evicts stale cached images then re-fetches the appointment list.
  Future<void> _refetchOnDoctorChange() async {
    final caregiverId = AuthSession.instance.userId;
    if (caregiverId == null || caregiverId.isEmpty || !mounted) return;
    for (final dto in _list) {
      final url = dto.doctorProfilePhotoURL;
      if (url != null && url.isNotEmpty) NetworkImage(url).evict();
    }
    try {
      final data = await _appointmentsService.getFullPreviousWithUpcoming(
        caregiverId,
      );
      if (!mounted) return;
      setState(() {
        _list = data.$1;
        _upcomingCache = data.$2;
      });
      _updateDoctorListeners(_list);
    } catch (_) {
      // Silent — the main stream will re-sync on the next appointment change.
    }
  }

  /// Like Upcoming: every second move ended appointments from _upcomingCache into _list (no HTTP).
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
        // Re-sort newest first when new items were added
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
    for (final sub in _doctorListeners.values) {
      sub.cancel();
    }
    _doctorListeners.clear();
    super.dispose();
  }

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
        GestureDetector(
          onTap: widget.onSwitchToUpcoming,
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
                'القادمة',
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
        const SizedBox(width: _filterButtonGap),
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
              'السابقة',
              style: TextStyle(
                fontFamily: 'Markazi Text',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
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
      if (i > 0) children.add(const SizedBox(height: _cardGap));
      children.add(_buildCardFor(_list[i]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildCardFor(UpcomingAppointmentDto dto) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);
    final ImageProvider? profileImage =
        (dto.doctorProfilePhotoURL != null &&
            dto.doctorProfilePhotoURL!.isNotEmpty)
        ? NetworkImage(dto.doctorProfilePhotoURL!)
        : const AssetImage('assets/images/default_ProfileImage.png');
    final attendanceStatus = _statusToDisplay(dto.status);
    // <Rating feature> Only show rate button when:
    // - attended (status == 1)
    // - NOT rated yet (isRated == false / rated == false in DB)
    // - doctorId exists (needed by POST /api/rate/add)
    final doctorId = dto.doctorId?.trim();
    final attended = dto.status == 1;
    final isRated = dto.isRated ?? false;
    final showRateButton =
        attended && !isRated && (doctorId != null && doctorId.isNotEmpty);
    return PreviousBookedAppointmentCard(
      doctorName: dto.doctorName ?? '',
      specialty: dto.doctorAreaOfKnowledge ?? '',
      childName: dto.childName ?? '',
      date: dateStr,
      time: timeStr,
      profileImage: profileImage,
      attendanceStatus: attendanceStatus,
      showRateButton: showRateButton,
      onRateTap: showRateButton
          ? () => RateDoctorBottomSheet.show(
              context,
              doctorId: doctorId!,
              appointmentId: dto.appointmentId,
            )
          : null,
    );
  }

  static String _statusToDisplay(int? status) {
    return status == 1 ? 'تم الحضور' : 'لم يتم الحضور';
  }

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
    final s = start ?? '';
    final e = end ?? '';
    if (s.isEmpty && e.isEmpty) return '';

    // Find which slot matches this start time to get correct AM/PM
    String suffix = 'مساءً'; // default
    for (int i = 0; i < SlotConfig.slotCount; i++) {
      if (SlotConfig.slotStartText(i) == s) {
        suffix = SlotConfig.amPmSuffix(i);
        break;
      }
    }

    if (e.isEmpty) return '$s $suffix';
    return '$s - $e $suffix';
  }
}
