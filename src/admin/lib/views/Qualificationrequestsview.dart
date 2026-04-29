import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'Widgets/AdminAvatar.dart';
import 'Widgets/ActionButton.dart';
import 'package:bouh_admin/views/Widgets/loading_overlay.dart';
import 'package:bouh_admin/model/DoctorModel.dart';
import 'package:bouh_admin/services/DoctorService.dart';
import 'package:bouh_admin/views/Widgets/ConfirmActionDialog.dart';
import 'responsive.dart';

class QualificationRequestsView extends StatefulWidget {
  final ValueChanged<int>? onCountLoaded;

  const QualificationRequestsView({super.key, this.onCountLoaded});

  @override
  State<QualificationRequestsView> createState() =>
      _QualificationRequestsViewState();
}

class _QualificationRequestsViewState extends State<QualificationRequestsView> {
  List<DoctorModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _processingIds = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRequests(showLoader: true);
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) _loadRequests();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRequests({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await DoctorService.instance
          .getPendingQualificationRequests(context);

      if (mounted) {
        setState(() {
          _requests = results;
          _isLoading = false;
        });
        widget.onCountLoaded?.call(_requests.length);
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

  Future<void> _accept(DoctorModel doc) async {
    final requestId = doc.requestId!;
    setState(() => _processingIds.add(requestId));
    try {
      await DoctorService.instance.acceptQualificationRequest(
        context,
        requestId,
      );
      if (mounted) {
        _showSnackBar(
          'تم قبول تحديث مؤهلات ${doc.name} وإرسال إشعار ✓',
          isSuccess: true,
        );
        await _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل قبول الطلب، حاول مرة أخرى', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(requestId));
    }
  }

  Future<void> _reject(DoctorModel doc) async {
    final requestId = doc.requestId!;
    setState(() => _processingIds.add(requestId));
    try {
      await DoctorService.instance.rejectQualificationRequest(
        context,
        requestId,
      );
      if (mounted) {
        _showSnackBar('تم رفض طلب تحديث مؤهلات ${doc.name}', isSuccess: false);
        await _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('فشل رفض الطلب، حاول مرة أخرى', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(requestId));
    }
  }

  void _showAcceptDialog(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'تأكيد القبول',
        message: 'هل أنت متأكد أنك تريد قبول تحديث مؤهلات ${doc.name}؟',
        confirmText: 'قبول',
        confirmColor: const Color(0xFF3B6D11),
        onConfirm: () async {
          Navigator.pop(context);
          await _accept(doc);
        },
      ),
    );
  }

  void _showRejectDialog(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'تأكيد الرفض',
        message: 'هل أنت متأكد أنك تريد رفض طلب تحديث مؤهلات ${doc.name}؟',
        confirmText: 'رفض',
        confirmColor: BColors.validationError,
        onConfirm: () async {
          Navigator.pop(context);
          await _reject(doc);
        },
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

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final isSmallLayout = isMobile || isTablet;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'طلبات تحديث المؤهلات',
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
                            onPressed: () => _loadRequests(showLoader: true),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_requests.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        'لا توجد طلبات تحديث مؤهلات',
                        style: TextStyle(color: BColors.darkGrey, fontSize: 14),
                      ),
                    ),
                  )
                else if (isSmallLayout)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: _requests.map((doc) {
                        final processing = _processingIds.contains(
                          doc.requestId,
                        );
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: BColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: BColors.grey, width: 0.5),
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
                              const SizedBox(height: 16),
                              _QualificationsComparison(
                                oldQualifications: doc.oldQualifications,
                                newQualifications: doc.newQualifications,
                              ),
                              const SizedBox(height: 12),
                              if (processing)
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
                                    _QualActionButton(
                                      label: 'قبول',
                                      bg: const Color(0xFFEAF3DE),
                                      fg: const Color(0xFF3B6D11),
                                      border: const Color(0xFFC0DD97),
                                      onTap: () => _showAcceptDialog(doc),
                                    ),
                                    _QualActionButton(
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
                              dataRowMinHeight: 90,
                              dataRowMaxHeight: 120,
                              columns: const [
                                DataColumn(label: Text('الطبيب')),
                                DataColumn(label: Text('المؤهلات الحالية')),
                                DataColumn(label: Text('المؤهلات المحدّثة ')),
                                DataColumn(label: Text('الإجراء')),
                              ],
                              rows: _requests.map((doc) {
                                final processing = _processingIds.contains(
                                  doc.requestId,
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
                                        width: 180,
                                        child: _QualificationsList(
                                          items: doc.oldQualifications,
                                          color: BColors.darkerGrey,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: _QualificationsList(
                                          items: doc.newQualifications,
                                          color: BColors.darkerGrey,
                                        ),
                                      ),
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
                                                _QualActionButton(
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
                                                _QualActionButton(
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

// ─── Qualifications side-by-side comparison (mobile) ─────────────────────────
class _QualificationsComparison extends StatelessWidget {
  final List<String> oldQualifications;
  final List<String> newQualifications;

  const _QualificationsComparison({
    required this.oldQualifications,
    required this.newQualifications,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الحالية',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BColors.darkGrey,
                ),
              ),
              const SizedBox(height: 6),
              _QualificationsList(
                items: oldQualifications,
                color: BColors.darkerGrey,
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Icon(Icons.arrow_back_ios, size: 14, color: BColors.darkGrey),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'المحدّثة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BColors.darkGrey,
                ),
              ),
              const SizedBox(height: 6),
              _QualificationsList(
                items: newQualifications,
                color: BColors.darkerGrey,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Simple bullet list of qualifications ────────────────────────────────────
class _QualificationsList extends StatelessWidget {
  final List<String> items;
  final Color color;

  const _QualificationsList({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: 13, color: color.withOpacity(0.5)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: items
          .map(
            (q) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      q,
                      style: TextStyle(fontSize: 13, color: color),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─── Bigger action button for this view only ─────────────────────────────────
class _QualActionButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color border;
  final VoidCallback onTap;

  const _QualActionButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── Doctor cell (reused from PendingRequestsView pattern) ───────────────────
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
