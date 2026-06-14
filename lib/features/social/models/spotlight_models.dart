// lib/features/social/models/spotlight_models.dart
//
// PHASE 10 — one entry shape for both Spotlight boards. For Creators, weeklyCoins
// = coins received; for Supporters, weeklyCoins = coins gifted. Money is never
// part of this model — the boards show coins/tiers only.

enum SpotlightTier { rising, bronze, silver, gold, diamond }

extension SpotlightTierX on SpotlightTier {
  String get label => switch (this) {
    SpotlightTier.rising => 'Rising',
    SpotlightTier.bronze => 'Bronze',
    SpotlightTier.silver => 'Silver',
    SpotlightTier.gold => 'Gold',
    SpotlightTier.diamond => 'Diamond',
  };
}

class SpotlightEntry {
  final String userId;
  final String userName;
  final String? userAvatar;
  final int weeklyCoins; // received (creators) OR gifted (supporters)
  final int totalCoins;
  final int level;
  final int giftCount;

  const SpotlightEntry({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.weeklyCoins = 0,
    this.totalCoins = 0,
    this.level = 1,
    this.giftCount = 0,
  });

  factory SpotlightEntry.fromJson(Map<String, dynamic> j) => SpotlightEntry(
    userId: j['userId'] ?? '',
    userName: j['userName'] ?? 'Anonymous',
    userAvatar: j['userAvatar'],
    weeklyCoins: j['weeklyCoins'] ?? 0,
    totalCoins: j['totalCoins'] ?? 0,
    level: j['level'] ?? 1,
    giftCount: j['giftCount'] ?? 0,
  );

  /// Tier derived from weekly coins — purely cosmetic recognition, no money shown.
  SpotlightTier get tier {
    if (weeklyCoins >= 50000) return SpotlightTier.diamond;
    if (weeklyCoins >= 10000) return SpotlightTier.gold;
    if (weeklyCoins >= 2000) return SpotlightTier.silver;
    if (weeklyCoins >= 500) return SpotlightTier.bronze;
    return SpotlightTier.rising;
  }
}