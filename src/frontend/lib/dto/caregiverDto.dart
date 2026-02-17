import 'childDto.dart';

class CaregiverDto {
  final String caregiverId;
  final String name;
  final String email;
  final String? fcmToken;
  final List<ChildDto> children;

  CaregiverDto({
    required this.caregiverId,
    required this.name,
    required this.email,
    this.fcmToken,
    required this.children,
  });

  Map<String, dynamic> toJson() {
    return {
      'caregiverId': caregiverId,
      'name': name,
      'email': email,
      'fcmToken': fcmToken,
      'children': children.map((c) => c.toJson()).toList(),
    };
  }
}
