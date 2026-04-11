import 'DrawingAnalysis/DrawingDto.dart';

class ChildDto {
  final String childId;
  final String name;
  final String dateOfBirth; // "YYYY-MM-DD"
  final String gender;
  final List<DrawingDto>? drawings;

  ChildDto({
    required this.childId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.drawings,
  });

  factory ChildDto.fromJson(Map<String, dynamic> json) {
    return ChildDto(
      // Support both possible keys from backend
      childId: (json['childId'] ?? json['childID'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      dateOfBirth: (json['dateOfBirth'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      drawings: (json['drawings'] is List)
          ? (json['drawings'] as List)
                .map((e) => DrawingDto.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'drawings': drawings?.map((d) => d.toJson()).toList(),
    };
  }
}
