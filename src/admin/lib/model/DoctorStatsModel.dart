class DoctorStatsModel {
  final int pending;
  final int accepted;
  final int rejected;

  const DoctorStatsModel({
    required this.pending,
    required this.accepted,
    required this.rejected,
  });

  factory DoctorStatsModel.fromJson(Map<String, dynamic> json) {
    return DoctorStatsModel(
      pending: json['pending'] ?? 0,
      accepted: json['accepted'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }
}
