import 'package:bouh/widgets/confirmation_popup.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:bouh/dto/AvailabilityDto.dart';
import 'package:bouh/services/AvailabilityService.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/config/slot_config.dart';

class AvailableScheduleScreen extends StatefulWidget {
  const AvailableScheduleScreen({super.key});

  @override
  State<AvailableScheduleScreen> createState() =>
      _AvailableScheduleScreenState();
}

class _AvailableScheduleScreenState extends State<AvailableScheduleScreen> {
  DateTime _d(int y, int m, int d) => DateTime(y, m, d);

  //Backend integeration:
  late final String doctorId;
  late final AvailabilityService _service = AvailabilityService();

  // schedule loaded from backend
  List<AvailabilityDayDto> scheduleDays = [];

  // loading + errors
  bool isLoading = true;
  String? loadError;

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay = DateTime.now(); //default select today

  bool isEditMode = false;

  // Store slot indexes (0..9) - matches backend offeredSlotIndexes
  final Set<int> offeredIndexesDraft = {};
  final Map<String, Set<int>> originalByDate = {};

  final Map<String, Set<int>> draftByDate = {};

  //Fixed slot count
  static final int slotCount = SlotConfig.slotCount;

  // ─────────────────────────────────────────────────────────────
  // Date helpers
  // ─────────────────────────────────────────────────────────────
  String _two(int n) => n.toString().padLeft(2, '0');

  String _iso(DateTime dt) => "${dt.year}-${_two(dt.month)}-${_two(dt.day)}";

  DateTime _startOfMonth(DateTime dt) => DateTime(dt.year, dt.month, 1);

  DateTime _maxAllowedDate() {
    final now = DateTime.now();
    final plus2 = DateTime(now.year, now.month + 2, now.day);
    return _d(plus2.year, plus2.month, plus2.day);
  }

  bool _isPastDay(DateTime day) {
    final now = DateTime.now();
    final onlyDateNow = _d(now.year, now.month, now.day);
    final onlyDateDay = _d(day.year, day.month, day.day);
    return onlyDateDay.isBefore(onlyDateNow);
  }

  bool _isBeyondAllowed(DateTime day) {
    final max = _maxAllowedDate();
    final onlyMax = _d(max.year, max.month, max.day);
    final onlyDay = _d(day.year, day.month, day.day);
    return onlyDay.isAfter(onlyMax);
  }

  bool _isEditableDay(DateTime day) =>
      !_isPastDay(day) && !_isBeyondAllowed(day);

  // start time of a slot (today's date + 16:00 + index*30min)
  DateTime _slotStart(DateTime day, int index) {
    final (h, m) = SlotConfig.slotStart(index);
    return DateTime(day.year, day.month, day.day, h, m);
  }

  // ─────────────────────────────────────────────────────────────
  // Backend load (current month + next month always)
  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final session = AuthSession.instance;

    final uid = session.userId; // Firebase UID

    doctorId = uid!;

    focusedDay = _startOfMonth(DateTime.now());
    selectedDay = DateTime.now();
    _loadScheduleForCurrentWindow();
  }

  Future<void> _loadScheduleForCurrentWindow() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final now = DateTime.now();
      final fromDate = _startOfMonth(now);
      final toDate = _maxAllowedDate();

      final from = _iso(fromDate);
      final to = _iso(toDate);

      final days = await _service.getSchedule(
        doctorId: doctorId,
        from: from,
        to: to,
      );

      scheduleDays = days;
      draftByDate.clear();
      originalByDate.clear();

      // When schedule loads, update draft selection for the currently selected day
      _syncDraftFromLoadedData();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
        loadError = e.toString();
      });
    }
  }

  void _syncDraftFromLoadedData() {
    //The bridge between backend and editable draft
    if (selectedDay == null) return;

    offeredIndexesDraft.clear();
    final day = _getDayDto(selectedDay!);
    if (day == null) return;

    // offered slots are those in day.slots regardless booked status
    for (final s in day.slots) {
      offeredIndexesDraft.add(s.index);
    }
  }

  AvailabilityDayDto? _getDayDto(DateTime day) {
    final date = _iso(day);
    try {
      return scheduleDays.firstWhere((d) => d.date == date);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Availability for calendar highlight
  // ─────────────────────────────────────────────────────────────
  bool _isAvailable(DateTime day) {
    final dto = _getDayDto(day);
    return dto != null && dto.slots.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────────
  // Slot UI helpers
  // ─────────────────────────────────────────────────────────────
  bool _isSlotBooked(int index) {
    if (selectedDay == null) return false;
    final dto = _getDayDto(selectedDay!);
    if (dto == null) return false;
    final found = dto.slots.where((s) => s.index == index);
    if (found.isEmpty) return false;
    return found.first.booked;
  }

  String _slotLabel(int index) => SlotConfig.slotLabel(index);

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _slotEnd(DateTime day, int index) {
    return _slotStart(day, index).add(const Duration(minutes: 30));
  }

  // Hide ONLY for TODAY, and only slots that already ended.
  bool _shouldHideSlot(DateTime day, int index) {
    final now = DateTime.now();
    if (!_isSameDate(day, now)) return false; // past/future days show all
    return !_slotEnd(day, index).isAfter(now); // ended => hide
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      appBar: AppBar(
        backgroundColor: BColors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: BColors.textDarkestBlue,
              size: 20,
            ),
            onPressed: () async {
              final shouldPop = await _confirmDiscard();
              if (shouldPop && mounted) Navigator.of(context).pop();
            },
          ),
        ],
        title: const Text(
          'جدولة الأوقات المتاحة',
          style: TextStyle(
            color: BColors.textDarkestBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: BColors.textDarkestBlue),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment:
                              Alignment.centerLeft, // forces left even in RTL
                          child: _circleIconButton(
                            icon: isEditMode ? Icons.close : Icons.edit,
                            iconColor: BColors.textDarkestBlue,
                            onTap: () async {
                              if (isEditMode) {
                                if (draftByDate.isNotEmpty) {
                                  final confirmed = await _confirmDiscard();
                                  if (!confirmed) return;
                                }
                                _cancelEdit();
                                return;
                              }

                              setState(() {
                                isEditMode = true;

                                _syncDraftFromLoadedData(); // fills offeredIndexesDraft from backend

                                final key = _iso(selectedDay!);
                                originalByDate[key] = {
                                  ...offeredIndexesDraft,
                                }; // remember original
                                draftByDate.remove(
                                  key,
                                ); // ensure NOT treated as changed
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        _calendarCard(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Colors.grey,
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "الأوقات باللون الرمادي محجوزة ولا يمكن تعديلها.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Loading / error state
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: BouhOvalLoadingIndicator(),
                      )
                    else if (loadError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "حدث خطأ أثناء تحميل الجدول:\n$loadError",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadScheduleForCurrentWindow,
                              child: const Text("إعادة المحاولة"),
                            ),
                          ],
                        ),
                      )
                    else
                      _timeSlots(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            _saveButton(),
          ],
        ),
      ),
    );
  }

  Widget _calendarCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TableCalendar(
        // Backend note: requires intl date formatting initialization in main.dart.
        locale: 'ar',
        firstDay: _startOfMonth(DateTime.now()),
        lastDay: _maxAllowedDate(),
        focusedDay: focusedDay,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        availableGestures: AvailableGestures.horizontalSwipe,

        selectedDayPredicate: (day) =>
            selectedDay != null && isSameDay(day, selectedDay),

        // Prevent selecting non-editable days when in edit mode
        onDaySelected: (sel, foc) {
          setState(() {
            // 1) if editing, save current day's draft before switching
            if (isEditMode && selectedDay != null) {
              final prevKey = _iso(selectedDay!);
              final originalPrev = originalByDate[prevKey] ?? <int>{};

              if (_areSetsEqual(offeredIndexesDraft, originalPrev)) {
                draftByDate.remove(prevKey);
              } else {
                draftByDate[prevKey] = {...offeredIndexesDraft};
              }
            }

            // 2) switch day
            selectedDay = sel;
            focusedDay = foc;

            // 3) load new day's draft (if exists) else load from backend
            final key = _iso(sel);

            offeredIndexesDraft.clear();

            if (isEditMode) {
              // (A) Store ORIGINAL for this day once (from backend)
              if (!originalByDate.containsKey(key)) {
                final dayDto = _getDayDto(sel);
                final originalSet = <int>{};
                if (dayDto != null) {
                  for (final s in dayDto.slots) originalSet.add(s.index);
                }
                originalByDate[key] = {...originalSet};
              }

              // (B) Load draft if changed before, otherwise load original
              if (draftByDate.containsKey(key)) {
                offeredIndexesDraft.addAll(draftByDate[key]!);
              } else {
                offeredIndexesDraft.addAll(originalByDate[key]!);
              }
            } else {
              _syncDraftFromLoadedData();
            }
          });
        },

        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: const Icon(Icons.chevron_left),
          rightChevronIcon: const Icon(Icons.chevron_right),
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black.withOpacity(0.75),
          ),
        ),

        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.55),
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.55),
          ),
        ),

        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          isTodayHighlighted: false,
          selectedDecoration: const BoxDecoration(
            color: BColors.accent,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          defaultTextStyle: TextStyle(
            color: Colors.black.withOpacity(0.75),
            fontWeight: FontWeight.w700,
          ),
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) {
            final isDisabled = !_isEditableDay(day);

            final hasAvailability = _isAvailable(day);

            if (isDisabled) {
              // Past/beyond day: show marker if it had availability
              if (hasAvailability) {
                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade500,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${day.day}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }

              return Center(
                child: Text(
                  "${day.day}",
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            if (hasAvailability) {
              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade500,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }

            return null;
          },
        ),
      ),
    );
  }

  Widget _timeSlots() {
    final day = selectedDay;
    if (day == null) {
      return _emptyCard("اختر يوماً لعرض الأوقات");
    }

    final editable = _isEditableDay(day);
    final canEditNow = isEditMode && editable;

    // We always show all fixed slots (0..9) so doctor can add/remove offered.
    // Booked ones are locked and shown grey.
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - (2 * 12)) / 3;
              final visibleIndexes =
                  List<int>.generate(
                      slotCount,
                      (i) => i,
                    ).where((i) => !_shouldHideSlot(day, i)).toList()
                    ..sort((a, b) {
                      final isMorningA = SlotConfig.isMorningSlot(a);
                      final isMorningB = SlotConfig.isMorningSlot(b);
                      if (isMorningA && !isMorningB) return -1; // morning first
                      if (!isMorningA && isMorningB) return 1;
                      return a.compareTo(b);
                    });
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: visibleIndexes.map((i) {
                  final booked = _isSlotBooked(i);
                  final offered = offeredIndexesDraft.contains(i);

                  final effectiveOffered = booked ? true : offered;
                  final disabledTile = !canEditNow || booked;
                  final selected = effectiveOffered;

                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: disabledTile
                          ? null
                          : () {
                              setState(() {
                                if (offeredIndexesDraft.contains(i)) {
                                  offeredIndexesDraft.remove(i);
                                } else {
                                  offeredIndexesDraft.add(i);
                                }

                                final key = _iso(selectedDay!);
                                final original = originalByDate[key] ?? <int>{};

                                if (_areSetsEqual(
                                  offeredIndexesDraft,
                                  original,
                                )) {
                                  draftByDate.remove(key);
                                } else {
                                  draftByDate[key] = {...offeredIndexesDraft};
                                }
                              });
                            },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: booked
                              ? Colors.grey.shade300
                              : selected
                              ? BColors.accent
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: booked
                                ? Colors.grey.shade400
                                : selected
                                ? Colors.transparent
                                : Colors.black.withOpacity(0.10),
                          ),
                          boxShadow: selected && !booked
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          _slotLabel(i),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: booked
                                ? Colors.grey.shade700
                                : selected
                                ? Colors.white
                                : Colors.black.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: BColors.darkGrey),
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      draftByDate.clear(); // remove all unsaved edits
      originalByDate.clear();
      _syncDraftFromLoadedData(); // restore from backend
      isEditMode = false;
    });
  }

  Widget _saveButton() {
    final day = selectedDay;
    if (day == null) return const SizedBox.shrink();
    final editable = _isEditableDay(day);
    if (!editable) return const SizedBox.shrink();
    final canSave =
        isEditMode && draftByDate.isNotEmpty && !isLoading && loadError == null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canSave ? BColors.primary : Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        // Disabled unless edit mode + editable day
        onPressed: !canSave
            ? null
            : () async {
                final confirmed = await ConfirmationPopup.show(
                  context,
                  title: "تأكيد الحفظ",
                  message: "هل أنت متأكد أنك تريد حفظ التغييرات على الجدول؟",
                  confirmText: "حفظ",
                  cancelText: "إلغاء",
                );

                if (!confirmed) return;

                //  Make sure booked slots remain offered (just in case)
                for (int i = 0; i < slotCount; i++) {
                  if (_isSlotBooked(i)) {
                    offeredIndexesDraft.add(i);
                  }
                }

                final key = _iso(day);
                final original = originalByDate[key] ?? <int>{};

                if (_areSetsEqual(offeredIndexesDraft, original)) {
                  draftByDate.remove(key);
                } else {
                  draftByDate[key] = {...offeredIndexesDraft};
                }

                final payloadDays = draftByDate.entries.map((e) {
                  return {
                    "date": e.key,
                    "offeredSlotIndexes": e.value.toList()..sort(),
                  };
                }).toList();

                try {
                  setState(() => isLoading = true);

                  await _service.updateSchedule(
                    doctorId: doctorId,
                    days: payloadDays,
                  );

                  await _loadScheduleForCurrentWindow();

                  setState(() {
                    draftByDate.clear();
                    originalByDate.clear();
                    isEditMode = false;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "تم الحفظ بنجاح",
                          textDirection: TextDirection.rtl,
                          style: TextStyle(color: BColors.white),
                        ),
                        backgroundColor: BColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "فشل الحفظ",
                          textDirection: TextDirection.rtl,

                          style: TextStyle(color: BColors.white),
                        ),
                        backgroundColor: BColors.validationError,
                      ),
                    );
                  }
                  setState(() => isLoading = false);
                }
              },
        child: const Text(
          'حفظ',
          style: TextStyle(color: BColors.white, fontSize: 16),
        ),
      ),
    );
  }

  bool _areSetsEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;

    for (final value in a) {
      if (!b.contains(value)) return false;
    }

    return true;
  }

  Future<bool> _confirmDiscard() async {
    if (!isEditMode || draftByDate.isEmpty)
      return true; // no changes, allow freely

    final confirmed = await ConfirmationPopup.show(
      context,
      title: "تغييرات غير محفوظة",
      message: "لديك تغييرات غير محفوظة. هل تريد الخروج بدون حفظ؟",
      confirmText: "مغادرة",
      cancelText: "بقاء",
    );

    return confirmed;
  }

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
}
