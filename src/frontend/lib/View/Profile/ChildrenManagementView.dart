import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/services/childrenService.dart';
import 'package:bouh/dto/childDto.dart';

class ChildrenManagementView extends StatefulWidget {
  const ChildrenManagementView({super.key});

  @override
  State<ChildrenManagementView> createState() => _ChildrenManagementViewState();
}

class _ChildrenManagementViewState extends State<ChildrenManagementView> {
  final ChildrenService _service = ChildrenService();

  final String caregiverId = "cg_12";

  bool isLoading = true;
  List<ChildDto> children = [];

  // ✅ MAX CHILDREN CHECK (added)
  static const int _maxChildren = 5;
  bool get _reachedMaxChildren => children.length >= _maxChildren;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() => isLoading = true);
    try {
      children = await _service.getChildren(caregiverId);
    } catch (e) {
      _showSnack(" خطأ في تحميل الأطفال");
    }
    setState(() => isLoading = false);
  }

  Future<void> _confirmDeleteChild(ChildDto child) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text("تأكيد الحذف"),
            content: Text("هل انت متأكد من حذف ملف ${child.name}؟"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("إلغاء"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("حذف"),
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    try {
      await _service.deleteChild(
        caregiverId: caregiverId,
        childId: child.childId,
      );
      _showSnack("تم حذف الطفل");
      await _loadChildren();
    } catch (e) {
      _showSnack("لم يتم الحذف: ${_cleanError(e.toString())}");
    }
  }

  Future<void> _openAddChildDialog() async {
    final result = await showDialog<_AddChildResult>(
      context: context,
      builder: (ctx) => _AddChildDialog(),
    );

    if (result == null) return;

    try {
      await _service.addChild(
        caregiverId: caregiverId,
        name: result.name,
        dateOfBirth: result.dateOfBirth, // YYYY-MM-DD
        gender: result.gender,
      );
      _showSnack("تمت إضافة الطفل");
      await _loadChildren();
    } catch (e) {
      // احتمال: max 5 children
      _showSnack("لقد تجاوزت العدد المسموح ");
    }
  }

  Future<void> _openEditChildDialog(ChildDto child) async {
    final result = await showDialog<_AddChildResult>(
      context: context,
      builder: (ctx) => _AddChildDialog(
        initialName: child.name,
        initialDob: child.dateOfBirth,
        initialGender: child.gender,
        isEdit: true,
      ),
    );

    if (result == null) return;

    try {
      await _service.updateChild(
        caregiverId: caregiverId,
        childId: child.childId,
        name: result.name,
        dateOfBirth: result.dateOfBirth,
        gender: result.gender,
      );

      _showSnack("تم تحديث بيانات الطفل بنجاح");
      await _loadChildren();
    } catch (e) {
      _showSnack("تعذر تحديث بيانات الطفل");
    }
  }

  String _cleanError(String msg) {
    return msg.replaceAll("Exception:", "").trim();
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (_reachedMaxChildren) {
                    _showSnack(
                      "لقد تجاوزت العدد المسموح ($_maxChildren أطفال)",
                    );
                    return;
                  }
                  await _openAddChildDialog();
                },
          backgroundColor: _reachedMaxChildren ? Colors.grey : BColors.accent,
          shape: const CircleBorder(),
          elevation: 6,
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Title row
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back_ios_outlined,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 80),
                    Text(
                      "ادارة الاطفال",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadChildren,
                          child: ListView(
                            padding: const EdgeInsets.only(bottom: 90),
                            children: [
                              if (children.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 40),
                                  child: Center(
                                    child: Text(
                                      "لايوجد أطفال حالياً",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black.withOpacity(0.6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ...children.map((child) {
                                final parts = child.dateOfBirth.split("-");
                                final year = parts.length > 0 ? parts[0] : "";
                                final month = parts.length > 1 ? parts[1] : "";
                                final day = parts.length > 2 ? parts[2] : "";
                                final isFemale =
                                    child.gender.toLowerCase() == "female";

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _childCard(
                                    name: child.name,
                                    isFemaleSelected: isFemale,
                                    day: day,
                                    month: month,
                                    year: year,
                                    onDelete: () => _confirmDeleteChild(child),
                                    onEdit: () => _openEditChildDialog(child),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // CARD METHOD
  Widget _childCard({
    required String name,
    required bool isFemaleSelected,
    required String day,
    required String month,
    required String year,
    required VoidCallback onDelete,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              _circleIconButton(
                icon: Icons.edit,
                iconColor: Colors.grey,
                onTap: onEdit,
              ),
              const SizedBox(width: 10),
              _circleIconButton(
                icon: Icons.delete_outline,
                iconColor: Colors.redAccent,
                onTap: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "الاسم",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.40),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _inputBox(value: name),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "تاريخ الميلاد",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _tinyBox(label: "السنه", value: year),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tinyBox(label: "الشهر", value: month),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _tinyBox(label: "اليوم", value: day),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "الجنس",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),
                    _genderSegmented(isFemaleSelected: isFemaleSelected),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // UI helpers
  Widget _circleIconButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF3),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black.withOpacity(0.08)),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _inputBox({required String value}) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.21),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _tinyBox({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.89,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.35),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.21),
            border: Border.all(color: Colors.black.withOpacity(0.10)),
            color: Colors.white,
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _genderSegmented({required bool isFemaleSelected}) {
    final borderColor = Colors.black.withOpacity(0.10);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.21),
          border: Border.all(color: borderColor),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.21),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  color: isFemaleSelected ? Colors.white : BColors.accent,
                  child: Text(
                    "ذكر",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isFemaleSelected
                          ? Colors.black.withOpacity(0.75)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              Container(width: 1, color: borderColor),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  color: isFemaleSelected ? BColors.accent : Colors.white,
                  child: Text(
                    "أنثى",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isFemaleSelected
                          ? Colors.white
                          : Colors.black.withOpacity(0.75),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Dialog result + UI

class _AddChildResult {
  final String name;
  final String dateOfBirth; // YYYY-MM-DD
  final String gender;
  _AddChildResult({
    required this.name,
    required this.dateOfBirth,
    required this.gender,
  });
}

class _AddChildDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDob; // YYYY-MM-DD
  final String? initialGender;
  final bool isEdit;

  const _AddChildDialog({
    super.key,
    this.initialName,
    this.initialDob,
    this.initialGender,
    this.isEdit = false,
  });

  @override
  State<_AddChildDialog> createState() => _AddChildDialogState();
}

class _AddChildDialogState extends State<_AddChildDialog> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController yearCtrl = TextEditingController();
  final TextEditingController monthCtrl = TextEditingController();
  final TextEditingController dayCtrl = TextEditingController();

  bool isFemale = true;

  @override
  void initState() {
    super.initState();

    // Prefill for edit
    if (widget.initialName != null) {
      nameCtrl.text = widget.initialName!;
    }

    if (widget.initialDob != null) {
      final parts = widget.initialDob!.split("-");
      if (parts.length == 3) {
        yearCtrl.text = parts[0];
        monthCtrl.text = parts[1];
        dayCtrl.text = parts[2];
      }
    }

    if (widget.initialGender != null) {
      isFemale = widget.initialGender!.toLowerCase() == "female";
    }
  }

  String? _validate() {
    if (nameCtrl.text.trim().isEmpty) return "يرجى إدخال اسم الطفل";
    if (yearCtrl.text.trim().isEmpty ||
        monthCtrl.text.trim().isEmpty ||
        dayCtrl.text.trim().isEmpty) {
      return "يرجى استكمال تاريخ الميلاد";
    }

    final y = int.tryParse(yearCtrl.text.trim());
    final m = int.tryParse(monthCtrl.text.trim());
    final d = int.tryParse(dayCtrl.text.trim());

    if (y == null || m == null || d == null)
      return "تاريخ الميلاد يجب أن يكون أرقامًا";
    if (y < 1900 || y > DateTime.now().year) return "السنة غير صحيحة";
    if (m < 1 || m > 12) return "الشهر غير صحيح";
    if (d < 1 || d > 31) return "اليوم غير صحيح";

    final dob =
        "${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";
    final parsed = DateTime.tryParse("${dob}T00:00:00");
    if (parsed == null) return "تاريخ الميلاد غير صحيح";

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.isEdit ? "تعديل بيانات الطفل" : "إضافة طفل"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "اسم الطفل"),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "السنة"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: monthCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "الشهر"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: dayCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "اليوم"),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isFemale = false),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.10),
                          ),
                          color: isFemale ? Colors.white : BColors.accent,
                        ),
                        child: Text(
                          "ذكر",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isFemale
                                ? Colors.black.withOpacity(0.75)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isFemale = true),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.10),
                          ),
                          color: isFemale ? BColors.accent : Colors.white,
                        ),
                        child: Text(
                          "أنثى",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isFemale
                                ? Colors.white
                                : Colors.black.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final err = _validate();
              if (err != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(err)));
                return;
              }

              final y = int.parse(yearCtrl.text.trim());
              final m = int.parse(monthCtrl.text.trim());
              final d = int.parse(dayCtrl.text.trim());
              final dob =
                  "${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}";

              Navigator.pop(
                context,
                _AddChildResult(
                  name: nameCtrl.text.trim(),
                  dateOfBirth: dob,
                  gender: isFemale ? "female" : "male",
                ),
              );
            },
            child: Text(widget.isEdit ? "حفظ" : "إضافة"),
          ),
        ],
      ),
    );
  }
}
