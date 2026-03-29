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

class AcceptedDoctorsView extends StatefulWidget {
  const AcceptedDoctorsView({super.key});

  @override
  State<AcceptedDoctorsView> createState() => _AcceptedDoctorsViewState();
}

class _AcceptedDoctorsViewState extends State<AcceptedDoctorsView> {
  List<DoctorModel> _doctors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApprovedDoctors();
  }

  Future<void> _loadApprovedDoctors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الأطباء المقبولون',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: BColors.textDarkestBlue,
                    ),
                  ),
                  if (_isLoading)
                    const BouhOvalLoadingIndicator(
                      width: 28,
                      height: 20,
                      strokeWidth: 2.5,
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: BColors.darkGrey,
                        size: 20,
                      ),
                      onPressed: _loadApprovedDoctors,
                      tooltip: 'تحديث',
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
                        onPressed: _loadApprovedDoctors,
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
            else
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(BColors.lightGrey),
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
                    DataColumn(label: Text('رقم SCFHS')),
                    DataColumn(label: Text('الإجراء')),
                  ],
                  rows: _doctors
                      .map(
                        (doc) => DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  AdminAvatarWidget(
                                    initials: doc.initials,
                                    bg: BColors.secondary,
                                    fg: BColors.primary,
                                    size: 40,
                                    fontSize: 14,
                                    photoUrl: doc.profilePhotoURL,
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        doc.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: BColors.textDarkestBlue,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        doc.email,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: BColors.darkGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            DataCell(Text(doc.areaOfKnowledge)),
                            DataCell(Text(doc.qualificationsDisplay)),
                            DataCell(Text('${doc.yearsOfExperience} سنوات')),
                            DataCell(ScfhsTagWidget(value: doc.scfhsNumber)),
                            DataCell(
                              Row(
                                children: [
                                  ActionIconButton(
                                    icon: Icons.visibility_outlined,
                                    bg: BColors.secondary,
                                    fg: BColors.primary,
                                    tooltip:
                                        'عرض التفاصيل كاملة بما فيها رقم الايبان',
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => DoctorDetailDialog(
                                        name: doc.name,
                                        email: doc.email,
                                        specialty: doc.areaOfKnowledge,
                                        qualifications:
                                            doc.qualificationsDisplay,
                                        yearsOfExperience:
                                            '${doc.yearsOfExperience} سنوات',
                                        scfhsNumber: doc.scfhsNumber,
                                        iban: doc.iban,
                                        avatarBg: BColors.secondary,
                                        avatarFg: BColors.primary,
                                        photoUrl: doc.profilePhotoURL,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DeleteButton(
                                    label: 'حذف الحساب',
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => ConfirmDeleteDialog(
                                        name: doc.name,
                                        onConfirm: () async {
                                          try {
                                            await DoctorService.instance
                                                .deleteDoctor(context, doc.uid);
                                            if (!mounted) return;
                                            Navigator.pop(context);
                                            setState(
                                              () => _doctors.removeWhere(
                                                (d) => d.uid == doc.uid,
                                              ),
                                            );
                                            _showSnackBar(
                                              'تم حذف حساب ${doc.name} بنجاح',
                                              isSuccess: true,
                                            );
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
