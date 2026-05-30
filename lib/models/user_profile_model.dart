
class UserProfile {
  final String userId;
  final String userName;
  final String displayName;
  final String? bio;
  final String? buzEmail;
  final String? chatTag;
  final String? transferUID;
  final String? email;
  final String? phoneNumber;
  final String? avatar;
  final String? coverImage;
  final String? website;
  final String? location;
  final String? country;

  // Privacy
  final bool isPrivate;
  final bool allowFollowersToMessage;

  // Stats
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int repostCount;

  // Earnings
  final double totalRewardPointsEarned;
  final double totalNairaEarned;
  final double weeklyPoints;

  // KYC
  final bool isKycVerified;
  final DateTime? kycVerifiedAt;

  // Account
  final DateTime createdAt;
  final DateTime lastActiveAt;

  // Badges
  final Map<String, dynamic> badges;

  bool isFollowing;
  bool isFollowingYou;

  UserProfile({
    required this.userId,
    required this.userName,
    required this.displayName,
    this.buzEmail,
    this.bio,
    this.chatTag,
    this.transferUID,
    this.email,
    this.phoneNumber,
    this.avatar,
    this.coverImage,
    this.website,
    this.location,
    this.country,
    required this.isPrivate,
    required this.allowFollowersToMessage,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    this.repostCount = 0,
    required this.totalRewardPointsEarned,
    required this.totalNairaEarned,
    required this.weeklyPoints,
    required this.isKycVerified,
    this.kycVerifiedAt,
    required this.createdAt,
    required this.lastActiveAt,
    this.badges = const {},
    this.isFollowing = false,
    this.isFollowingYou = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Parse badges safely - handle both Map and List
    Map<String, dynamic> parsedBadges = {};
    final badgesData = json['badges'];

    if (badgesData is Map) {
      parsedBadges = Map<String, dynamic>.from(badgesData);
    } else if (badgesData is List) {
      // If it's a list (empty array from backend), convert to empty map
      parsedBadges = {};
    }

    return UserProfile(
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      displayName: json['displayName']  ?? 'Anonymous',
      bio: json['bio'],
      chatTag: json['chatTag'],
      transferUID: json['transferUID'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      avatar: json['avatar'],
      coverImage: json['coverImage'],
      website: json['website'],
      location: json['location'],
      country: json['country'],
      buzEmail: json['businessEmail'],
      isPrivate: json['isPrivate'] ?? false,
      allowFollowersToMessage: json['allowFollowersToMessage'] ?? false,
      followerCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      repostCount: json['repostCount'] ?? 0,
      totalRewardPointsEarned: (json['totalRewardPointsEarned'] ?? json['totalEarned'] ?? 0).toDouble(),
      totalNairaEarned: (json['totalNairaEarned'] ?? json['totalEarned'] ?? 0).toDouble(),
      weeklyPoints: (json['weeklyPoints'] ?? json['weeklyEarned'] ?? 0).toDouble(),
      isKycVerified: json['isKycVerified'] ?? false,
      kycVerifiedAt: json['kycVerifiedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['kycVerifiedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActiveAt'])
          : DateTime.now(),
      badges: parsedBadges,
      isFollowing: json['isFollowing'] ?? false,
      isFollowingYou: json['isFollowingYou'] ?? false,
    );
  }

  UserProfile copyWith({
    String? bio,
    String ? location,
    String ? website,
    String ? buzEmail,
    String ? displayName,
    bool? isFollowing,
    int? followerCount,
    bool? isPrivate,
    bool? allowFollowersToMessage
  }) {
    return UserProfile(
      userId: userId,
      userName: userName,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      chatTag: chatTag,
      transferUID: transferUID,
      email: email,
      phoneNumber: phoneNumber,
      avatar: avatar,
      coverImage: coverImage,
      website: website ?? this.website,
      location: location ?? this.location,
      buzEmail: buzEmail ?? this.buzEmail,
      isPrivate: isPrivate ?? this.isPrivate,
      allowFollowersToMessage: allowFollowersToMessage ?? this.allowFollowersToMessage,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount,
      postCount: postCount,
      repostCount: repostCount,
      totalRewardPointsEarned: totalRewardPointsEarned,
      totalNairaEarned: totalNairaEarned,
      weeklyPoints: weeklyPoints,
      isKycVerified: isKycVerified,
      kycVerifiedAt: kycVerifiedAt,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt,
      badges: badges,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowingYou: isFollowingYou,
    );
  }


  //This will be uncommented in production
  // bool get hasBlueCheck => badges['kycBlue'] == true;
  // bool get hasPremium => badges['premiumPaid'] == true;
  // bool get isBusiness => badges['business'] == true;
  // bool get isCreator => badges['creatorEarnings'] == true;

  //This will be deleted in production
  bool get hasBlueCheck => true;
  bool get hasPremium => badges['premiumPaid'] == true;
  bool get isBusiness => badges['business'] == true;
  bool get isCreator => badges['creatorEarnings'] == true;

  List<String> get activeBadges {
    final List<String> active = [];
    badges.forEach((key, value) {
      if (value is Map && value['awarded'] == true) {
        final expiresAt = value['expiresAt'];
        if (expiresAt == null || DateTime.now().isBefore(DateTime.fromMillisecondsSinceEpoch(expiresAt))) {
          active.add(key);
        }
      }
    });
    return active;
  }
}