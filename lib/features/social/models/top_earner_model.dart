// lib/models/top_earner_model.dart

class TopEarner {
  final String userId;
  final String userName;
  final String? userAvatar;
  final double totalRewardPoints;
  final double weeklyPoints;
  final double totalEarnedNaira;
  final int level;

  TopEarner({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.totalRewardPoints,
    required this.weeklyPoints,
    required this.totalEarnedNaira,
    required this.level,
  });

  factory TopEarner.fromJson(Map<String, dynamic> json) {
    return TopEarner(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userAvatar: json['userAvatar'],
      totalRewardPoints: (json['totalRewardPoints'] ?? 0).toDouble(),
      weeklyPoints: (json['weeklyPoints'] ?? 0).toDouble(),
      totalEarnedNaira: (json['totalEarnedNaira'] ?? 0).toDouble(),
      level: json['level'] ?? 1,
    );
  }
}