class DoctorStatsModel {
  final int pending;
  final int accepted;

  const DoctorStatsModel({required this.pending, required this.accepted});

  factory DoctorStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorStatsModel(
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
    );
  }
}
