// lib/models/top_earner_model.dart

class TopEarner {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int totalCoins;     // CHANGED from totalRewardPoints
  final int weeklyCoins;    // CHANGED from weeklyPoints
  final double totalNaira;  // CHANGED from totalEarnedNaira
  final int level;

  TopEarner({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.totalCoins,
    required this.weeklyCoins,
    required this.totalNaira,
    required this.level,
  });

  factory TopEarner.fromJson(Map<String, dynamic> json) {
    return TopEarner(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userAvatar: json['userAvatar'],
      totalCoins: (json['totalCoins'] ?? 0),
      weeklyCoins: (json['weeklyCoins'] ?? 0),
      totalNaira: (json['totalNaira'] ?? 0).toDouble(),
      level: json['level'] ?? 1,
    );
  }
}