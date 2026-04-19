import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'Widgets/AdminAvatar.dart';
import 'Widgets/ScfhsTag.dart';
import 'Widgets/ActionButton.dart';
import 'Widgets/ConfirmDeleteDialog.dart';
import 'Widgets/DoctorDetailDialog.dart';
import 'package:bouh_admin/model/DoctorModel.dart';
import 'package:bouh_admin/services/DoctorService.dart';
import 'Widgets/loading_overlay.dart';
import 'responsive.dart';

class AcceptedDoctorsView extends StatefulWidget {
  const AcceptedDoctorsView({super.key});

  @override
  State<AcceptedDoctorsView> createState() => _AcceptedDoctorsViewState();
}

class _AcceptedDoctorsViewState extends State<AcceptedDoctorsView> {
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadApprovedDoctors(showLoader: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _loadApprovedDoctors();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadApprovedDoctors({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

    try {
      final doctors = await DoctorService.instance.getApprovedDoctors(context);
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
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

  void _showSnackBar(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: TextDirection.rtl),
        backgroundColor: isSuccess ? BColors.primary : BColors.validationError,
      ),
    );
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

  void _showDeleteDialog(DoctorModel doc) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        name: doc.name,
        onConfirm: () async {
          try {
            await DoctorService.instance.deleteDoctor(context, doc.uid);
            if (!mounted) return;
            Navigator.pop(context);
            setState(() {
              _doctors.removeWhere((d) => d.uid == doc.uid);
            });
            _showSnackBar('تم حذف حساب ${doc.name} بنجاح', isSuccess: true);
          } catch (_) {
            if (!mounted) return;
            Navigator.pop(context);
            _showSnackBar(
              'تعذّر الاتصال بالخادم، تحقق من الاتصال',
              isSuccess: false,
            );
          }
        },
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
      child: Container(
        decoration: BoxDecoration(
          color: BColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BColors.grey, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: const Row(
                children: [
                  Text(
                    'الأطباء المقبولون',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: BColors.textDarkestBlue,
                    ),
                  ),
                ],
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
                        onPressed: () => _loadApprovedDoctors(showLoader: true),
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
                    'لا يوجد أطباء مقبولون',
                    style: TextStyle(color: BColors.darkGrey, fontSize: 14),
                  ),
                ),
              )
            else if (isSmallLayout)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _doctors.map((doc) {
                    return SizedBox(
                      width: double.infinity,
                      child: Container(
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
                                DeleteButton(
                                  label: 'حذف الحساب',
                                  onTap: () => _showDeleteDialog(doc),
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
                                  Row(
                                    children: [
                                      ActionIconButton(
                                        icon: Icons.visibility_outlined,
                                        bg: BColors.secondary,
                                        fg: BColors.primary,
                                        tooltip:
                                            'عرض التفاصيل كاملة بما فيها رقم الايبان',
                                        onTap: () => _showDetail(doc),
                                      ),
                                      const SizedBox(width: 8),
                                      DeleteButton(
                                        label: 'حذف الحساب',
                                        onTap: () => _showDeleteDialog(doc),
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
          size: 40,
          fontSize: 14,
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
