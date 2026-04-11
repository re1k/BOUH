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
import 'package:bouh/services/doctorsService.dart';
import 'package:bouh/dto/doctorBarInfoDto.dart';
import 'package:bouh/services/profileService.dart';

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
class DoctorHomePageState extends State<DoctorHomePage>
    with WidgetsBindingObserver {
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
  String? _doctorId;
  final ProfileService _profileService = ProfileService();
  String? _headerDoctorName;
  String? _headerDoctorPhotoUrl;

  String? _normalizePhotoUrl(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty || v.toLowerCase() == 'null') return null;
    return v;
  }

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer so we re-subscribe when app resumes.
    WidgetsBinding.instance.addObserver(this);
    _prepareSessionAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app comes back to the foreground, re-subscribe to get fresh data.
    if (state == AppLifecycleState.resumed) {
      _prepareSessionAndLoad();
    }
  }

  /// Call when home nav is tapped to refresh today's appointments.
  void refresh() {
    refreshAppointmentsOnly();
    refreshHeaderFromBackend();
  }

  /// Lightweight refresh for home tab taps: updates appointments only.
  Future<void> refreshAppointmentsOnly() async {
    await AuthService.instance.refreshSession();
    final String? doctorId = AuthSession.instance.userId;
    if (!mounted) return;
    setState(() => _doctorId = doctorId);
    _subscribeToStream(doctorId);
  }

  /// Reuse already retrieved profile info without hitting profile endpoint again.
  void refreshProfileHeader({String? name, String? photoUrl}) {
    if (!mounted) return;
    setState(() {
      if (name != null) {
        _headerDoctorName = name.trim();
      }
      if (photoUrl != null) {
        final previous = _headerDoctorPhotoUrl;
        final next = _normalizePhotoUrl(photoUrl);

        // Prevent stale cached avatar after delete/change.
        if (previous != null &&
            previous.isNotEmpty &&
            previous != next) {
          NetworkImage(previous).evict();
        }
        _headerDoctorPhotoUrl = next;
      }
    });
  }

  Future<void> _prepareSessionAndLoad() async {
    await AuthService.instance.refreshSession();
    final String? doctorId = AuthSession.instance.userId;
    if (!mounted) return;
    setState(() => _doctorId = doctorId);
    await _loadHeaderProfile();
    _subscribeToStream(doctorId);
  }

  Future<void> _loadHeaderProfile() async {
    try {
      final profile = await _profileService.fetchDoctorProfile();
      if (!mounted) return;
      final nextPhoto = _normalizePhotoUrl(profile.profilePhotoURL);
      final prevPhoto = _headerDoctorPhotoUrl;
      if (prevPhoto != null && prevPhoto.isNotEmpty && prevPhoto != nextPhoto) {
        NetworkImage(prevPhoto).evict();
      }
      setState(() {
        _headerDoctorName = (profile.name ?? '').trim();
        _headerDoctorPhotoUrl = nextPhoto;
      });
    } catch (_) {
      // Keep fallback values from session/local UI if profile fetch fails.
    }
  }

  /// Force backend-truth refresh for header profile fields (name/photo).
  Future<void> refreshHeaderFromBackend() async {
    await AuthService.instance.refreshSession();
    await _loadHeaderProfile();
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
    // print('OPENED DoctorHomePage from: doctorHomePage.dart');
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
                  _todayList.removeWhere(
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
          CircleAvatar(
            radius: 31,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              child: ClipOval(
                child:
                    (_headerDoctorPhotoUrl != null &&
                        _headerDoctorPhotoUrl!.isNotEmpty)
                    ? Image.network(
                        _headerDoctorPhotoUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/default_ProfileImage.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/default_ProfileImage.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name/photo from profile endpoint (fetched once). Rating can refresh independently.
          Expanded(
            child: StreamBuilder<DoctorBarInfoDto>(
              stream: (_doctorId == null || _doctorId!.isEmpty)
                  ? null
                  : DoctorsService.streamDoctorBarInfo(
                      doctorId: _doctorId!,
                      interval: const Duration(seconds: 10),
                    ),
              builder: (context, snapshot) {
                final name = _headerDoctorName?.trim().isNotEmpty == true
                    ? _headerDoctorName!
                    : (AuthSession.instance.userName?.trim().isNotEmpty == true
                          ? AuthSession.instance.userName!
                          : '');
                final rating = snapshot.data?.averageRating ?? 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty
                          ? 'مرحباً بعودتك، أهلاً $name'
                          : 'مرحباً بعودتك، أهلاً',
                      style: const TextStyle(
                        fontFamily: 'Markazi Text',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BColors.secondary.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Markazi Text',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              _RatingStars(
                                rating: rating.clamp(0.0, 5.0),
                                size: 16,
                                filledColor: BColors.accent,
                                emptyColor: Colors.orange.withOpacity(0.30),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayHeader() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'مواعيدك اليوم',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: BColors.textDarkestBlue,
        ),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({
    required this.rating,
    required this.size,
    required this.filledColor,
    required this.emptyColor,
  });

  final double rating; // 0..5
  final double size;
  final Color filledColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: List.generate(5, (i) {
        final frac = (rating - i).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 2),
          child: SizedBox(
            width: size,
            height: size,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                if (frac <= 0) {
                  return LinearGradient(
                    colors: [emptyColor, emptyColor],
                  ).createShader(bounds);
                }
                if (frac >= 1) {
                  return LinearGradient(
                    colors: [filledColor, filledColor],
                  ).createShader(bounds);
                }

                // One icon only; gradient simulates partial fill.
                // LTR: fill left -> right. RTL: fill right -> left.
                if (isRtl) {
                  // Filled region is the RIGHT-most portion.
                  final t = 1 - frac;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: <double>[0, t, t, 1],
                    colors: <Color>[
                      emptyColor,
                      emptyColor,
                      filledColor,
                      filledColor,
                    ],
                  ).createShader(bounds);
                } else {
                  // Filled region is the LEFT-most portion.
                  final t = frac;
                  return LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: <double>[0, t, t, 1],
                    colors: <Color>[
                      filledColor,
                      filledColor,
                      emptyColor,
                      emptyColor,
                    ],
                  ).createShader(bounds);
                }
              },
              child: Icon(Icons.star, size: size, color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}
// _StarClipper no longer needed (ShaderMask handles fractional fill).

