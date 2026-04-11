import 'package:bouh/dto/DrawingAnalysis/DoctorSuggestionDto.dart';

class DrawingDto {
  final String drawingId;
  final String imageURL;
  final String emotionClass;
  final String emotionalInterpretation;
  final String createdAt;
  final List<DoctorSuggestionDto> doctors;

  DrawingDto({
    required this.drawingId,
    required this.imageURL,
    required this.emotionClass,
    required this.emotionalInterpretation,
    required this.createdAt,
    required this.doctors,
  });

  factory DrawingDto.fromJson(Map<String, dynamic> json) {
    // Parse embedded doctors array — each element is a map
    final rawDoctors = json['doctors'] as List<dynamic>? ?? [];
    final doctors = rawDoctors
        .map((e) => DoctorSuggestionDto.fromJson(e as Map<String, dynamic>))
        .toList();

    return DrawingDto(
      drawingId: (json['drawingId'] ?? '').toString(),
      imageURL: (json['imageURL'] ?? '').toString(),
      emotionClass: (json['emotionClass'] ?? '').toString(),
      emotionalInterpretation: (json['emotionalInterpretation'] ?? '')
          .toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      doctors: doctors,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drawingId': drawingId,
      'imageURL': imageURL,
      'emotionClass': emotionClass,
      'emotionalInterpretation': emotionalInterpretation,
      'createdAt': createdAt,
      'doctors': doctors.map((d) => d.toJson()).toList(),
    };
  }
}
