import 'package:bouh/View/BookAppointment/ApointmentDetails.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:table_calendar/table_calendar.dart';

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  // DUMMY DATA
  final List<String> childrenNames = const ["بسّام", "دانا"];
  String selectedChild = "بسّام";

  DateTime d(int y, int m, int d) => DateTime(y, m, d);
  // DUMMY available dates (grey) -> take this later from the contoller
  //Note that every available date is related to different time slots
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
  // Selected day (orange) DUMMY
  DateTime focusedDay = DateTime(2025, 10, 1);
  DateTime? selectedDay = DateTime(2025, 10, 10);

  int selectedTimeIndex = 0;

  bool _isAvailable(DateTime day) {
    final normalized = d(day.year, day.month, day.day);
    return availableSlotsByDate.containsKey(normalized);
  }

  List<String> get timeSlots {
    if (selectedDay == null) return [];
    final normalized = d(
      selectedDay!.year,
      selectedDay!.month,
      selectedDay!.day,
    );
    return availableSlotsByDate[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title + dropdown UNDER it (stacked)
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "الطفل",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: Container(
            height: 44,
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.88),
              border: Border.all(color: Colors.black.withOpacity(0.10)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: Colors.white,
                value: selectedChild,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: childrenNames
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selectedChild = v);
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "تواريخ الحجز المتاحة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: BColors.textBlack,
            ),
          ),
        ),
        // Calendar card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9.24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TableCalendar(
            locale: 'ar',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            availableGestures: AvailableGestures.horizontalSwipe,
            selectedDayPredicate: (day) =>
                selectedDay != null && isSameDay(day, selectedDay),
            onDaySelected: (sel, foc) {
              setState(() {
                selectedDay = sel;
                focusedDay = foc;
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
              selectedDecoration: BoxDecoration(
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
            // Grey available days
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
        ),

        const SizedBox(height: 18),

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

        if (timeSlots.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              //max 3 per row
              final itemWidth =
                  (constraints.maxWidth - (2 * 12)) / 3; // 12 = spacing*2

              return Wrap(
                spacing: 12, // horizontal space between items
                runSpacing: 12, // vertical space between rows
                children: List.generate(timeSlots.length, (i) {
                  final selected = i == selectedTimeIndex;

                  return SizedBox(
                    width: itemWidth, // forces 3 items per row
                    child: InkWell(
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

        const SizedBox(height: 18),

        SizedBox(
          width: 220,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => const AppointmentDetailsView(
                    //DUMMY LATER SEND THE CURRNET DOCOTOR'S DATA
                    doctorName: "د. علي آل يحيى",
                    timeRange: "10:30 - 11:00 PM",
                    dateText: "10 أكتوبر",
                    childName: "بسّام",
                    price: 130,
                    total: 149.5,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BColors.accent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(54.52),
              ),
            ),
            child: const Text(
              "حجز",
              style: TextStyle(
                fontSize: 20.44,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
