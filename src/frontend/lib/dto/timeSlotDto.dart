class TimeSlotDto {
  final String timeSlotId;
  final String startTime;
  final String endTime;
  final String status;

  TimeSlotDto({
    required this.timeSlotId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'timeSlotId': timeSlotId,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }
}
