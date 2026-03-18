class DoctorBarInfoDto {
  final String name;
  final double averageRating;

  DoctorBarInfoDto({required this.name, required this.averageRating});

  factory DoctorBarInfoDto.fromJson(Map<String, dynamic> json) {
    final rawRating = json['averageRating'] ?? json['rating'];
    final double parsedRating = (rawRating is num)
        ? rawRating.toDouble()
        : (rawRating is String)
            ? (double.tryParse(rawRating) ?? 0.0)
            : 0.0;

    return DoctorBarInfoDto(
      name: (json['name'] ?? json['doctorName'] ?? '').toString(),
      averageRating: parsedRating,
    );
  }
}

