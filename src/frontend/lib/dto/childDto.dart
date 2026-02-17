import 'drawingDto.dart';

class ChildDto {
  final String childId;
  final String name;
  final String dateOfBirth;
  final String gender;
  final List<DrawingDto>? drawings;

  ChildDto({
    required this.childId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    this.drawings,
  });

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
