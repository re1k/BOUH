import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'Widgets/AdminAvatar.dart';
import 'Widgets/ConfirmDeleteDialog.dart';
import 'Widgets/ActionButton.dart';
import 'package:bouh_admin/model/CaregiverModel.dart';
import 'Widgets/loading_overlay.dart';
import 'package:bouh_admin/services/CaregiverService.dart';

class CaregiversView extends StatefulWidget {
  const CaregiversView({super.key});

  @override
  State<CaregiversView> createState() => _CaregiversViewState();
}

class _CaregiversViewState extends State<CaregiversView> {
  List<CaregiverInfoModel> _caregivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCaregivers();
  }

  Future<void> _loadCaregivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final caregivers = await CaregiverInfoService.instance.getAllCaregivers(
        context,
      );
      if (mounted) {
        setState(() {
          _caregivers = caregivers;
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
        backgroundColor:
            isSuccess ? BColors.primary : BColors.validationError,
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
                    'مقدمو الرعاية',
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
                      onPressed: _loadCaregivers,
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
                        onPressed: _loadCaregivers,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_caregivers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'لا يوجد مقدمو رعاية',
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
                    DataColumn(label: Text('مقدم الرعاية')),
                    DataColumn(label: Text('البريد الإلكتروني')),
                    DataColumn(label: Text('الإجراء')),
                  ],
                  rows: _caregivers
                      .map(
                        (cg) => DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  AdminAvatarWidget(
                                    initials: cg.initials,
                                    bg: BColors.secondary,
                                    fg: BColors.primary,
                                    size: 40,
                                    fontSize: 14,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    cg.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: BColors.textDarkestBlue,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                cg.email,
                                style: const TextStyle(
                                  color: BColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            DataCell(
                              DeleteButton(
                                label: 'حذف الحساب',
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => ConfirmDeleteDialog(
                                    name: cg.name,
                                    onConfirm: () async {
                                      try {
                                        await CaregiverInfoService.instance
                                            .deleteCaregiver(context, cg.uid);
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        setState(() => _caregivers.removeWhere(
                                            (c) => c.uid == cg.uid));
                                        _showSnackBar(
                                          'تم حذف حساب ${cg.name} بنجاح',
                                          isSuccess: true,
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        Navigator.pop(context);
                                        final msg = e is Exception
                                            ? e.toString().replaceFirst('Exception: ', '')
                                            : 'تعذّر الاتصال بالخادم، تحقق من الاتصال';
                                        _showSnackBar(msg, isSuccess: false);
                                      }
                                    },
                                  ),
                                ),
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
