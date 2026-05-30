
class GiftType {
  final String id;
  final String name;
  final String emoji;
  final int coins;
  final double naira;

  const GiftType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.coins,
    required this.naira,
  });


  // TIER 1: Budget gifts (₦1-10)
  static const rose = GiftType(id: 'rose', name: 'Rose', emoji: '🌹', coins: 10, naira: 1.0);
  static const heart = GiftType(id: 'heart', name: 'Heart', emoji: '❤️', coins: 15, naira: 1.5);
  static const coffee = GiftType(id: 'coffee', name: 'Coffee', emoji: '☕', coins: 20, naira: 2.0);
  static const cake = GiftType(id: 'cake', name: 'Cake', emoji: '🎂', coins: 30, naira: 3.0);
  static const pizza = GiftType(id: 'pizza', name: 'Pizza', emoji: '🍕', coins: 50, naira: 5.0);
  static const gift = GiftType(id: 'gift', name: 'Gift Box', emoji: '🎁', coins: 75, naira: 7.5);
  static const star = GiftType(id: 'star', name: 'Star', emoji: '⭐', coins: 100, naira: 10.0);

  // TIER 2: Mid-range (₦15-100)
  static const fire = GiftType(id: 'fire', name: 'Fire', emoji: '🔥', coins: 150, naira: 15.0);
  static const balloon = GiftType(id: 'balloon', name: 'Balloon', emoji: '🎈', coins: 200, naira: 20.0);
  static const trophy = GiftType(id: 'trophy', name: 'Trophy', emoji: '🏆', coins: 250, naira: 25.0);
  static const champagne = GiftType(id: 'champagne', name: 'Champagne', emoji: '🍾', coins: 300, naira: 30.0);
  static const diamond = GiftType(id: 'diamond', name: 'Diamond', emoji: '💎', coins: 500, naira: 50.0);
  static const gem = GiftType(id: 'gem', name: 'Gem', emoji: '💍', coins: 750, naira: 75.0);
  static const fireworks = GiftType(id: 'fireworks', name: 'Fireworks', emoji: '🎆', coins: 1000, naira: 100.0);

  // TIER 3: Premium (₦150-500)
  static const rocket = GiftType(id: 'rocket', name: 'Rocket', emoji: '🚀', coins: 1500, naira: 150.0);
  static const sports = GiftType(id: 'sports', name: 'Sports Car', emoji: '🏎️', coins: 2000, naira: 200.0);
  static const airplane = GiftType(id: 'airplane', name: 'Airplane', emoji: '✈️', coins: 3000, naira: 300.0);
  static const yacht = GiftType(id: 'yacht', name: 'Yacht', emoji: '🛥️', coins: 4000, naira: 400.0);
  static const castle = GiftType(id: 'castle', name: 'Castle', emoji: '🏰', coins: 5000, naira: 500.0);

  // TIER 4: VIP (₦750-2000)
  static const crown = GiftType(id: 'crown', name: 'Crown', emoji: '👑', coins: 7500, naira: 750.0);
  static const unicorn = GiftType(id: 'unicorn', name: 'Unicorn', emoji: '🦄', coins: 10000, naira: 1000.0);
  static const dragon = GiftType(id: 'dragon', name: 'Dragon', emoji: '🐉', coins: 15000, naira: 1500.0);
  static const galaxy = GiftType(id: 'galaxy', name: 'Galaxy', emoji: '🌌', coins: 20000, naira: 2000.0);

  static const List<GiftType> allGifts = [
    // Budget tier
    rose, heart, coffee, cake, pizza, gift, star,
    // Mid-range
    fire, balloon, trophy, champagne, diamond, gem, fireworks,
    // Premium
    rocket, sports, airplane, yacht, castle,
    // VIP
    crown, unicorn, dragon, galaxy,
  ];

  static GiftType? fromId(String id) {
    return allGifts.firstWhere(
          (gift) => gift.id == id,
      orElse: () => rose,
    );
  }
}