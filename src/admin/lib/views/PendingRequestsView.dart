import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'Widgets/AdminAvatar.dart';
import 'Widgets/ScfhsTag.dart';
import 'Widgets/ActionButton.dart';
import 'Widgets/DoctorDetailDialog.dart';
import 'package:bouh_admin/views/Widgets/loading_overlay.dart';
import 'package:bouh_admin/model/DoctorModel.dart';
import 'package:bouh_admin/model/DoctorStatsModel.dart';
import 'package:bouh_admin/services/DoctorService.dart';
import 'package:bouh_admin/views/Widgets/ConfirmActionDialog.dart';
import 'responsive.dart';

class PendingRequestsView extends StatefulWidget {
  final ValueChanged<int>? onCountLoaded;

  const PendingRequestsView({super.key, this.onCountLoaded});

  @override
  State<PendingRequestsView> createState() => _PendingRequestsViewState();
}

class _PendingRequestsViewState extends State<PendingRequestsView> {
  List<DoctorModel> _doctors = [];
  DoctorStatsModel? _stats;
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _processingUids = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPendingDoctors(showLoader: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _loadPendingDoctors();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPendingDoctors({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    try {
      final results = await Future.wait([
        DoctorService.instance.getPendingDoctors(context),
        DoctorService.instance.getStats(context),
      ]);

      if (mounted) {
        setState(() {
          _doctors = results[0] as List<DoctorModel>;
          _stats = results[1] as DoctorStatsModel?;
          _isLoading = false;
        });
        widget.onCountLoaded?.call(_doctors.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل تحميل البيانات، حاول مرة أخرى';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptDoctor(DoctorModel doc) async {
    setState(() => _processingUids.add(doc.uid));
    try {
      await DoctorService.instance.acceptDoctor(context, doc.uid);
      if (mounted) {
        _showSnackBar(
          'تم قبول ${doc.name} وإرسال إشعار عبر البريد الإلكتروني ✓',
          isSuccess: true,
        );
        await _loadPendingDoctors();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل قبول الطلب، حاول مرة أخرى', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _processingUids.remove(doc.uid));
    }
  }

  Future<void> _rejectDoctor(DoctorModel doc) async {
    setState(() => _processingUids.add(doc.uid));
    try {
      await DoctorService.instance.rejectDoctor(context, doc.uid);
      if (mounted) {
        _showSnackBar(
          'تم رفض طلب ${doc.name} وإرسال إشعار عبر البريد الإلكتروني',
          isSuccess: false,
        );
        await _loadPendingDoctors();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل رفض الطلب، حاول مرة أخرى', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _processingUids.remove(doc.uid));
    }
  }

  void _showDetail(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (_) => DoctorDetailDialog(
        name: doc.name,
        email: doc.email,
        specialty: doc.areaOfKnowledge,
        qualifications: doc.qualificationsDisplay,
        yearsOfExperience: '${doc.yearsOfExperience} سنوات',
        scfhsNumber: doc.scfhsNumber,
        iban: doc.iban,
        avatarBg: BColors.secondary,
        avatarFg: BColors.primary,
        photoUrl: doc.profilePhotoURL,
      ),
    );
  }

  void _showSnackBar(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isSuccess ? BColors.primary : BColors.validationError,
      ),
    );
  }

  void _showAcceptDialog(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'تأكيد القبول',
        message: 'هل أنت متأكد أنك تريد قبول ${doc.name}؟',
        confirmText: 'قبول',
        confirmColor: const Color(0xFF3B6D11),
        onConfirm: () async {
          Navigator.pop(context);
          await _acceptDoctor(doc);
        },
      ),
    );
  }

  void _showRejectDialog(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'تأكيد الرفض',
        message: 'هل أنت متأكد أنك تريد رفض ${doc.name}؟',
        confirmText: 'رفض',
        confirmColor: BColors.validationError,
        onConfirm: () async {
          Navigator.pop(context);
          await _rejectDoctor(doc);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final isSmallLayout = isMobile || isTablet;

    final stat1 = _StatCard(
      icon: Icons.access_time_outlined,
      iconBg: const Color(0xFFFFF1EA),
      iconColor: BColors.accent,
      label: 'طلبات معلقة',
      value: _stats?.pending ?? 0,
    );

    final stat2 = _StatCard(
      icon: Icons.people_outlined,
      iconBg: BColors.secondary,
      iconColor: BColors.primary,
      label: 'أطباء مقبولون',
      value: _stats?.accepted ?? 0,
    );

    final stat3 = _StatCard(
      icon: Icons.cancel_outlined,
      iconBg: const Color(0xFFFCEBEB),
      iconColor: BColors.validationError,
      label: 'طلبات مرفوضة',
      value: _stats?.rejected ?? 0,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSmallLayout)
            Column(
              children: [
                stat1,
                const SizedBox(height: 16),
                stat2,
                const SizedBox(height: 16),
                stat3,
              ],
            )
          else
            Row(
              children: [
                Expanded(child: stat1),
                const SizedBox(width: 16),
                Expanded(child: stat2),
                const SizedBox(width: 16),
                Expanded(child: stat3),
              ],
            ),
          const SizedBox(height: 28),

          Container(
            decoration: BoxDecoration(
              color: BColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BColors.grey, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Text(
                    'طلبات التسجيل المعلقة',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: BColors.textDarkestBlue,
                    ),
                  ),
                ),
                const Divider(color: BColors.grey, height: 0.5, thickness: 0.5),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: BouhLoadingOverlay(showBarrier: false, size: 48),
                    ),
                  )
                else if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: BColors.validationError,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () =>
                                _loadPendingDoctors(showLoader: true),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_doctors.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        'لا توجد طلبات معلقة',
                        style: TextStyle(color: BColors.darkGrey, fontSize: 14),
                      ),
                    ),
                  )
                else if (isSmallLayout)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _doctors.map((doc) {
                        final processing = _processingUids.contains(doc.uid);

                        return SizedBox(
                          width: double.infinity,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: BColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: BColors.grey,
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DoctorCell(
                                  name: doc.name,
                                  email: doc.email,
                                  initials: doc.initials,
                                  photoUrl: doc.profilePhotoURL,
                                ),
                                const SizedBox(height: 12),
                                Text('مجال المعرفة: ${doc.areaOfKnowledge}'),
                                const SizedBox(height: 8),
                                Text('المؤهلات: ${doc.qualificationsDisplay}'),
                                const SizedBox(height: 8),
                                Text(
                                  'سنوات الخبرة: ${doc.yearsOfExperience} سنوات',
                                ),
                                const SizedBox(height: 8),
                                Text('رقم التخصص: ${doc.scfhsNumber}'),
                                const SizedBox(height: 12),
                                if (_processingUids.contains(doc.uid))
                                  const BouhOvalLoadingIndicator(
                                    width: 28,
                                    height: 20,
                                    strokeWidth: 2.5,
                                  )
                                else
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ActionIconButton(
                                        icon: Icons.visibility_outlined,
                                        bg: BColors.secondary,
                                        fg: BColors.primary,
                                        tooltip: 'عرض التفاصيل',
                                        onTap: () => _showDetail(doc),
                                      ),
                                      ActionTextButton(
                                        label: 'قبول',
                                        bg: const Color(0xFFEAF3DE),
                                        fg: const Color(0xFF3B6D11),
                                        border: const Color(0xFFC0DD97),
                                        onTap: () => _showAcceptDialog(doc),
                                      ),
                                      ActionTextButton(
                                        label: 'رفض',
                                        bg: const Color(0xFFFCEBEB),
                                        fg: BColors.validationError,
                                        border: const Color(0xFFF7C1C1),
                                        onTap: () => _showRejectDialog(doc),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                BColors.lightGrey,
                              ),
                              headingTextStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: BColors.darkGrey,
                              ),
                              dataTextStyle: const TextStyle(
                                fontSize: 14,
                                color: BColors.darkerGrey,
                              ),
                              columnSpacing: 32,
                              dataRowMinHeight: 68,
                              dataRowMaxHeight: 68,
                              columns: const [
                                DataColumn(label: Text('الطبيب')),
                                DataColumn(label: Text('مجال المعرفة')),
                                DataColumn(label: Text('المؤهلات')),
                                DataColumn(label: Text('سنوات الخبرة')),
                                DataColumn(label: Text('رقم التخصص')),
                                DataColumn(label: Text('الإجراء')),
                              ],
                              rows: _doctors.map((doc) {
                                final processing = _processingUids.contains(
                                  doc.uid,
                                );

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      _DoctorCell(
                                        name: doc.name,
                                        email: doc.email,
                                        initials: doc.initials,
                                        photoUrl: doc.profilePhotoURL,
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          doc.areaOfKnowledge,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 140,
                                        child: Text(
                                          doc.qualificationsDisplay,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          '${doc.yearsOfExperience} سنوات',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      ScfhsTagWidget(value: doc.scfhsNumber),
                                    ),
                                    DataCell(
                                      processing
                                          ? const BouhOvalLoadingIndicator(
                                              width: 28,
                                              height: 20,
                                              strokeWidth: 2.5,
                                            )
                                          : Row(
                                              children: [
                                                ActionIconButton(
                                                  icon:
                                                      Icons.visibility_outlined,
                                                  bg: BColors.secondary,
                                                  fg: BColors.primary,
                                                  tooltip:
                                                      'عرض التفاصيل كاملة بما فيها رقم الايبان',
                                                  onTap: () => _showDetail(doc),
                                                ),
                                                const SizedBox(width: 8),
                                                ActionTextButton(
                                                  label: 'قبول',
                                                  bg: const Color(0xFFEAF3DE),
                                                  fg: const Color(0xFF3B6D11),
                                                  border: const Color(
                                                    0xFFC0DD97,
                                                  ),
                                                  onTap: () =>
                                                      _showAcceptDialog(doc),
                                                ),
                                                const SizedBox(width: 8),
                                                ActionTextButton(
                                                  label: 'رفض',
                                                  bg: const Color(0xFFFCEBEB),
                                                  fg: BColors.validationError,
                                                  border: const Color(
                                                    0xFFF7C1C1,
                                                  ),
                                                  onTap: () =>
                                                      _showRejectDialog(doc),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final int value;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BColors.grey, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: BColors.darkGrey),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: BColors.textDarkestBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCell extends StatelessWidget {
  final String name;
  final String email;
  final String initials;
  final String? photoUrl;

  const _DoctorCell({
    required this.name,
    required this.email,
    required this.initials,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        AdminAvatarWidget(
          initials: initials,
          bg: BColors.secondary,
          fg: BColors.primary,
          photoUrl: photoUrl,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: BColors.textDarkestBlue,
                fontSize: 15,
              ),
            ),
            Text(
              email,
              style: const TextStyle(fontSize: 13, color: BColors.darkGrey),
            ),
          ],
        ),
      ],
    );
  }
}
