class CaregiverInfoModel {
  final String uid;
  final String name;
  final String email;

  const CaregiverInfoModel({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory CaregiverInfoModel.fromJson(Map<String, dynamic> json) {
    return CaregiverInfoModel(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    return parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : parts[0][0];
  }
}
