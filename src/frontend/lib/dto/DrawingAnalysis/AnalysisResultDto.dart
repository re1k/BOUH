// Maps to DrawingAnalysisResponseDto.java
// Returned after a fresh analysis completes — not used for history.
import 'package:bouh/dto/DrawingAnalysis/DoctorSuggestionDto.dart';

class AnalysisResult {
  final String drawingId;
  final String emotion;

  /// Empty string if Gemini failed — never null.
  final String emotionalInterpretation;

  /// Empty list when threshold not met — never null.
  final List<DoctorSuggestionDto> doctors;

  const AnalysisResult({
    required this.drawingId,
    required this.emotion,
    required this.emotionalInterpretation,
    required this.doctors,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final doctors = (json['doctors'] as List? ?? [])
        .map((e) => DoctorSuggestionDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return AnalysisResult(
      drawingId: (json['drawingId'] ?? '').toString(),
      emotion: (json['emotion'] ?? '').toString(),
      emotionalInterpretation: (json['emotionalInterpretation'] ?? '')
          .toString(),
      doctors: doctors,
    );
  }
}
