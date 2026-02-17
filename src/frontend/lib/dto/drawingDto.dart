class DrawingDto {
  final String drawingId;
  final String imageURL;
  final String emotionClass;
  final String emotionalInterpretation;
  final String createdAt;
  final String doctorsIDSuggestion;

  DrawingDto({
    required this.drawingId,
    required this.imageURL,
    required this.emotionClass,
    required this.emotionalInterpretation,
    required this.createdAt,
    required this.doctorsIDSuggestion,
  });

  Map<String, dynamic> toJson() {
    return {
      'drawingId': drawingId,
      'imageURL': imageURL,
      'emotionClass': emotionClass,
      'emotionalInterpretation': emotionalInterpretation,
      'createdAt': createdAt,
      'doctorsIDSuggestion': doctorsIDSuggestion,
    };
  }
}
