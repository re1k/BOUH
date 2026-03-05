import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class AvailableScheduleScreen extends StatefulWidget {
  const AvailableScheduleScreen({super.key});

  @override
  State<AvailableScheduleScreen> createState() =>
      _AvailableScheduleScreenState();
}

class _AvailableScheduleScreenState extends State<AvailableScheduleScreen> {
  DateTime _d(int y, int m, int d) => DateTime(y, m, d);

  // Suggested: GET /availability?doctorId=... -> returns available dates + slots.
  final Map<DateTime, List<String>> availableSlotsByDate = {
    DateTime(2025, 10, 12): ["8:00 - 8:30 مساءً", "9:00 - 9:30 مساءً"],
    DateTime(2025, 10, 13): [
      "7:00 - 7:30 مساءً",
      "8:00 - 8:30 مساءً",
      "9:00 - 9:30 مساءً",
      "10:00 - 10:30 مساءً",
    ],
    DateTime(2025, 10, 25): ["6:00 - 6:30 مساءً", "7:00 - 7:30 مساءً"],
  };

  // Backend hook: these should be initialized using current month or server default.
  DateTime focusedDay = DateTime(2025, 10, 1);
  DateTime? selectedDay = DateTime(2025, 10, 12);

  int selectedTimeIndex = 0;

  bool _isAvailable(DateTime day) {
    final normalized = _d(day.year, day.month, day.day);
    return availableSlotsByDate.containsKey(normalized);
  }

  // Backend hook: if controller returns slot objects, change List<String> to List<Slot> and format in UI.
  List<String> get timeSlots {
    if (selectedDay == null) return [];
    final normalized = _d(
      selectedDay!.year,
      selectedDay!.month,
      selectedDay!.day,
    );
    return availableSlotsByDate[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BColors.lightGrey,
      appBar: AppBar(
        backgroundColor: BColors.white,
        elevation: 0,
        centerTitle: true,
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
            _viewSwitcher(),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _calendarCardLikeFriend(),
                    const SizedBox(height: 18),
                    _timeSlotsLikeFriend(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),

            _saveButton(),
          ],
        ),
      ),

      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _viewSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: BColors.softGrey,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _switchItem('يوم', false),
          _switchItem('اسبوع', false),
          _switchItem('شهر', true),
        ],
      ),
    );
  }

  Widget _switchItem(String title, bool selected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? BColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? BColors.textDarkestBlue : BColors.darkGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _calendarCardLikeFriend() {
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
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        startingDayOfWeek: StartingDayOfWeek.sunday,
        availableGestures: AvailableGestures.horizontalSwipe,

        selectedDayPredicate: (day) =>
            selectedDay != null && isSameDay(day, selectedDay),

        // Backend hook: on selecting a day, you may fetch slots for that day.
        // Example: GET /availability/slots?date=YYYY-MM-DD
        onDaySelected: (sel, foc) {
          setState(() {
            selectedDay = sel;
            focusedDay = foc;
            selectedTimeIndex = 0;
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

        // Backend hook: available days should come from availability endpoint.
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, _) {
            if (_isAvailable(day)) {
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

  Widget _timeSlotsLikeFriend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "الأوقات المتاحة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (timeSlots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: const Text(
              "لا توجد أوقات متاحة لهذا اليوم",
              textAlign: TextAlign.center,
              style: TextStyle(color: BColors.darkGrey),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - (2 * 12)) / 3;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(timeSlots.length, (i) {
                  final selected = i == selectedTimeIndex;

                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      // Backend hook: update selected slot, or toggle multiple selections if required.
                      onTap: () => setState(() => selectedTimeIndex = i),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? BColors.accent : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : Colors.black.withOpacity(0.10),
                          ),
                          boxShadow: selected
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
                          timeSlots[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : Colors.black.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: BColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        // Backend hook: call controller to persist selected availability.
        // You can read selectedDay + selectedTimeIndex/timeSlots to build the payload.
        onPressed: () {},
        child: const Text(
          'حفظ',
          style: TextStyle(color: BColors.white, fontSize: 16),
        ),
      ),
    );
  }

  // add remaz navbar
  Widget _bottomNav() {
    return BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: BColors.primary,
      unselectedItemColor: BColors.darkGrey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'المواعيد',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
      ],
    );
  }
}
