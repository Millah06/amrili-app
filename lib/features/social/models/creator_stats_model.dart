// lib/models/creator_stats_model.dart

class CreatorStats {
  final String userId;
  final int totalCoinsEarned;      // CHANGED from totalRewardPoints
  final double totalNairaEarned;   // CHANGED from totalEarnedNaira
  final int totalGiftsReceived;    // CHANGED from totalRewardsReceived
  final int weeklyCoins;           // CHANGED from weeklyPoints
  final int level;
  final bool isKycVerified;

  final DateTime lastUpdated;

  CreatorStats({
    required this.userId,
    required this.totalCoinsEarned,
    required this.totalNairaEarned,
    required this.totalGiftsReceived,
    required this.level,
    required this.isKycVerified,
    required this.weeklyCoins,
    required this.lastUpdated,
  });

  factory CreatorStats.fromJson(Map<String, dynamic> json) {
    return CreatorStats(
      userId: json['userId'] ?? '',
      totalCoinsEarned: json['totalCoinsEarned'] ?? 0,
      totalNairaEarned: (json['totalNairaEarned'] ?? 0).toDouble(),
      totalGiftsReceived: json['totalGiftsReceived'] ?? 0,
      weeklyCoins: json['weeklyCoins'] ?? 0,
      level: json['level'] ?? 1,
      isKycVerified: json['isKycVerified'] ?? false,
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