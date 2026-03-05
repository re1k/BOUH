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

  factory ScheduleDto.fromJson(Map<String, dynamic> json) {
    final slots = (json['timeSlots'] as List? ?? [])
        .map((e) => TimeSlotDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return ScheduleDto(
      scheduleId: (json['scheduleId'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      timeSlots: slots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'date': date,
      'timeSlots': timeSlots.map((t) => t.toJson()).toList(),
    };
  }
}
