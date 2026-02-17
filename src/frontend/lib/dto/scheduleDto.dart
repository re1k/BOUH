import 'timeSlotDto.dart';

class ScheduleDto {
  final String scheduleId;
  final String date;
  final List<TimeSlotDto> timeSlots;

  ScheduleDto({
    required this.scheduleId,
    required this.date,
    required this.timeSlots,
  });

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'date': date,
      'timeSlots': timeSlots.map((t) => t.toJson()).toList(),
    };
  }
}
