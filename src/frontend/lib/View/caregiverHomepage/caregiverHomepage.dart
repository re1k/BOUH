import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/base_themes/colors.dart';
import 'package:bouh/View/viewAppointments/widgets/appointmentCard.dart';
import 'package:bouh/dto/upcomingAppointmentDto.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/authentication/AuthService.dart';
import 'package:bouh/services/appointmentsService.dart';
import 'package:bouh/services/payment/RefundService.dart';
import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'widgets/suggestedDoctorCard.dart';
import 'widgets/caregiverBottomNav.dart';

class CaregiverHomepage extends StatefulWidget {
  const CaregiverHomepage({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex;
  final ValueChanged<int>? onTap;

  @override
  State<CaregiverHomepage> createState() => CaregiverHomepageState();
}

class CaregiverHomepageState extends State<CaregiverHomepage>
    with WidgetsBindingObserver {
  static const double _sectionGap = 24;
  static const double _cardGap = 16;
  static const double _headerBaseHeight = 130;
  static const double _contentPaddingRight = 24;
  static const Color _cancelRed = Color(0xFFE85D4F);

  final AppointmentsService _appointmentsService = AppointmentsService();
  final RefundService _refundService = RefundService();

  List<UpcomingAppointmentDto> _list = [];
  bool _loading = false;
  String? _error;
  bool _refundLoading = false;

  StreamSubscription<List<UpcomingAppointmentDto>>? _subscription;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
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
    if (state == AppLifecycleState.resumed) {
      _prepareSessionAndLoad();
    }
  }

  void refresh() {
    _prepareSessionAndLoad();
  }

  Future<void> _prepareSessionAndLoad() async {
    final AuthSession session = AuthSession.instance;
    await AuthService.instance.refreshSession();
    final String? userId = session.userId;
    if (!mounted) return;
    _subscribeToStream(userId);
  }

  void _subscribeToStream(String? caregiverId) {
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

  static String get _todayString {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

  Widget _buildCardFor(UpcomingAppointmentDto dto, {required bool isFirst}) {
    final dateStr = _formatDate(dto.date);
    final timeStr = _formatTimeRange(dto.startTime, dto.endTime);

    ImageProvider? profileImage;
    if (dto.doctorProfilePhotoURL != null &&
        dto.doctorProfilePhotoURL!.isNotEmpty) {
      profileImage = NetworkImage(dto.doctorProfilePhotoURL!);
    }

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
    }

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

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              left: 0,
              height: _headerBaseHeight + topPadding,
              child: _buildHeader(context, topPadding),
            ),
            _buildContent(context, topPadding),
          ],
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

  Widget _buildHeader(BuildContext context, double topPadding) {
    return Container(
      width: double.infinity,
      height: _headerBaseHeight + topPadding,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/header_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: topPadding + 24,
            right: 26,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'مرحبًا بعودتك،',
                  style: TextStyle(
                    fontFamily: 'Markazi Text',
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    color: BColors.white,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Text(
                    AuthSession.instance.userName?.trim().isNotEmpty == true
                        ? 'أهلًا ${AuthSession.instance.userName!}'
                        : 'أهلًا',
                    style: TextStyle(
                      fontFamily: 'Markazi Text',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: BColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, double topPadding) {
    return Positioned(
      left: 0,
      right: 0,
      top: _headerBaseHeight + topPadding,
      bottom: 0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          _contentPaddingRight,
          CaregiverBottomNav.barHeight + _cardGap,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('مواعيدك اليوم'),
            const SizedBox(height: 12),
            _buildTodayAppointments(),
            const SizedBox(height: _sectionGap),
            _buildSectionWithViewAll('الأطباء المقترحين لبسام'),
            const SizedBox(height: 12),
            const SuggestedDoctorCard(
              name: 'د. علي آل يحيى',
              specialty: 'خبير علاج القلق والتوتر',
              rating: 4,
            ),
            const SizedBox(height: _cardGap),
            const SuggestedDoctorCard(
              name: 'د. عبد العزيز الناصر',
              specialty: 'خبير التعامل مع نوبات الغضب',
              rating: 3,
            ),
            const SizedBox(height: _sectionGap),
            _buildSectionWithViewAll('الأطباء المقترحين لدانا'),
            const SizedBox(height: 12),
            const SuggestedDoctorCard(
              name: 'د. أحمد القحطاني',
              specialty: 'خبير التعامل مع الصدمات',
              rating: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAppointments() {
    if (_loading) {
      return const Center(child: BouhLoadingOverlay(showBarrier: false));
    }

    if (_error != null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
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

    final today = _todayString;
    final todayList = _list.where((dto) => dto.date == today).toList();

    if (todayList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'لا توجد مواعيد اليوم',
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
    for (var i = 0; i < todayList.length; i++) {
      if (i > 0) children.add(const SizedBox(height: _cardGap));
      children.add(_buildCardFor(todayList[i], isFirst: i == 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          title,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Markazi Text',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: BColors.textDarkestBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionWithViewAll(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          title,
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
              Icon(Icons.chevron_right, size: 20, color: BColors.textBlack),
            ],
          ),
        ),
      ],
    );
  }
}
