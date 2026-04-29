import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'Widgets/AdminAvatar.dart';
import 'Widgets/ConfirmDeleteDialog.dart';
import 'Widgets/ActionButton.dart';
import 'Widgets/loading_overlay.dart';
import 'package:bouh_admin/model/CaregiverModel.dart';
import 'package:bouh_admin/services/CaregiverService.dart';
import 'responsive.dart';

class CaregiversView extends StatefulWidget {
  const CaregiversView({super.key});

  @override
  State<CaregiversView> createState() => _CaregiversViewState();
}

class _CaregiversViewState extends State<CaregiversView> {
  List<CaregiverInfoModel> _caregivers = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCaregivers(showLoader: true);

    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _loadCaregivers();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCaregivers({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      _errorMessage = null;
    }

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
        backgroundColor: isSuccess ? BColors.primary : BColors.validationError,
      ),
    );
  }

  void _showDeleteDialog(CaregiverInfoModel cg) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDeleteDialog(
        name: cg.name,
        onConfirm: () async {
          try {
            await CaregiverInfoService.instance.deleteCaregiver(
              context,
              cg.uid,
            );
            if (!mounted) return;
            Navigator.pop(context);
            setState(() {
              _caregivers.removeWhere((c) => c.uid == cg.uid);
            });
            _showSnackBar('تم حذف حساب ${cg.name} بنجاح', isSuccess: true);
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
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Text(
                    'مقدمو الرعاية',
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
                        onPressed: () => _loadCaregivers(showLoader: true),
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
            else if (isSmallLayout)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _caregivers.map((cg) {
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
                            _CaregiverCell(
                              name: cg.name,
                              email: cg.email,
                              initials: cg.initials,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cg.email,
                              style: const TextStyle(
                                color: BColors.darkGrey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                DeleteButton(
                                  label: 'حذف الحساب',
                                  onTap: () => _showDeleteDialog(cg),
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
                            DataColumn(label: Text('مقدم الرعاية')),
                            DataColumn(label: Text('البريد الإلكتروني')),
                            DataColumn(label: Text('الإجراء')),
                          ],
                          rows: _caregivers.map((cg) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  _CaregiverCell(
                                    name: cg.name,
                                    email: cg.email,
                                    initials: cg.initials,
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      cg.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: BColors.black,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  DeleteButton(
                                    label: 'حذف الحساب',
                                    onTap: () => _showDeleteDialog(cg),
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

class _CaregiverCell extends StatelessWidget {
  final String name;
  final String email;
  final String initials;

  const _CaregiverCell({
    required this.name,
    required this.email,
    required this.initials,
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
          ],
        ),
      ],
    );
  }
}
