// lib/models/creator_stats_model.dart

class CreatorStats {
  final String userId;
  final double totalRewardPoints;
  final double totalEarnedNaira;
  final int totalRewardsReceived;
  final int level;
  final bool isKycVerified;
  final double weeklyPoints;
  final DateTime lastUpdated;

  CreatorStats({
    required this.userId,
    required this.totalRewardPoints,
    required this.totalEarnedNaira,
    required this.totalRewardsReceived,
    required this.level,
    required this.isKycVerified,
    required this.weeklyPoints,
    required this.lastUpdated,
  });

  factory CreatorStats.fromJson(Map<String, dynamic> json) {
    return CreatorStats(
      userId: json['userId'] ?? '',
      totalRewardPoints: (json['totalRewardPoints'] ?? 0).toDouble(),
      totalEarnedNaira: (json['totalEarnedNaira'] ?? 0).toDouble(),
      totalRewardsReceived: json['totalRewardsReceived'] ?? 0,
      level: json['level'] ?? 1,
      isKycVerified: json['isKycVerified'] ?? false,
      weeklyPoints: (json['weeklyPoints'] ?? 0).toDouble(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        json['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  String get levelName {
    switch (level) {
      case 1: return 'Newcomer';
      case 2: return 'Rising Star';
      case 3: return 'Contributor';
      case 4: return 'Influencer';
      case 5: return 'Expert';
      case 6: return 'Authority';
      case 7: return 'Pioneer';
      case 8: return 'Legend';
      case 9: return 'Icon';
      case 10: return 'Master';
      default: return 'Newcomer';
    }
  }
}