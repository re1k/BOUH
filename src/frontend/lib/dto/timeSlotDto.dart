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

  factory TimeSlotDto.fromJson(Map<String, dynamic> json) {
    return TimeSlotDto(
      timeSlotId: (json['timeSlotId'] ?? json['timeSlotID'] ?? '')
          .toString(), // Handle both 'timeSlotId' and 'timeSlotID لان بعض ملفاتنا تختلف فيها الاسماء
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeSlotId': timeSlotId,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }
}
