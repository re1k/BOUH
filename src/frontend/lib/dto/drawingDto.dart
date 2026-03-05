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

  factory DrawingDto.fromJson(Map<String, dynamic> json) {
    return DrawingDto(
      drawingId: (json['drawingId'] ?? '').toString(),
      imageURL: (json['imageURL'] ?? '').toString(),
      emotionClass: (json['emotionClass'] ?? '').toString(),
      emotionalInterpretation: (json['emotionalInterpretation'] ?? '')
          .toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      doctorsIDSuggestion: (json['doctorsIDSuggestion'] ?? '').toString(),
    );
  }

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
