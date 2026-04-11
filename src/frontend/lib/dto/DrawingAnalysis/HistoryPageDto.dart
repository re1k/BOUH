// Maps to HistoryResponseDto.java
// records    → the page of DrawingDto items
// nextCursor → send back as ?cursor= on the next request
//              null means there are no more pages — stop paginating
import 'package:bouh/dto/DrawingAnalysis/DrawingDto.dart';

class HistoryPageDto {
  final List<DrawingDto> records;
  final String? nextCursor;

  const HistoryPageDto({required this.records, this.nextCursor});
  factory HistoryPageDto.fromJson(Map<String, dynamic> json) {
    final records = (json['records'] as List? ?? [])
        .map((e) => DrawingDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return HistoryPageDto(
      records: records,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
