class User {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool active;
  final String referralCode;
  final String transferUID;
  final bool notificationsEnabled;
  final DateTime createdAt;

  final Wallet wallet;
  final UserProfile userProfile;
  final List<VirtualAccount> virtualAccounts;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.active,
    required this.referralCode,
    required this.transferUID,
    required this.notificationsEnabled,
    required this.createdAt,
    required this.wallet,
    required this.userProfile,
    required this.virtualAccounts,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      active: json['active'] ?? false,
      referralCode: json['referralCode'] ?? '',
      transferUID: json['transferUid'] ?? '',
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),

      wallet: Wallet.fromJson(json['wallet'] ?? {}),
      userProfile: UserProfile.fromJson(json['userProfile'] ?? {}),
      virtualAccounts: (json['virtualAccount'] as List? ?? [])
          .map((e) => VirtualAccount.fromJson(e))
          .toList(),
    );
  }

  User copyWith({String? userId}) {
    return User(userId: userId  ?? this.userId,
        name: name,
        email: email,
        phone: phone,
        role: role,
        active: active,
        referralCode: referralCode,
        transferUID: transferUID,
        notificationsEnabled: notificationsEnabled,
        createdAt: createdAt,
        wallet: wallet, userProfile: userProfile,
        virtualAccounts: virtualAccounts
    );
  }
}

class Wallet {
  final Fiat fiat;

  Wallet({required this.fiat});

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      fiat: Fiat.fromJson(json['fiat'] ?? {}),
    );
  }
}

class Fiat {
  final double availableBalance;
  final double lockedBalance;
  final double rewardBalance;

  Fiat({
    required this.availableBalance,
    required this.lockedBalance,
    required this.rewardBalance,
  });

  factory Fiat.fromJson(Map<String, dynamic> json) {
    return Fiat(
      availableBalance: (json['availableBalance'] ?? 0).toDouble(),
      lockedBalance: (json['lockedBalance'] ?? 0).toDouble(),
      rewardBalance: (json['rewardBalance'] ?? 0).toDouble(),
    );
  }
}

class UserProfile {
  final String id;
  final String userId;
  final String userName;
  final String bio;
  final String website;
  final String location;

  final String buzEmail;

  final String avatarUrl;
  final String coverPhotoUrl;
  final List badges;
  final int followersCount;
  final int followingCount;
  final int postCount;
  final bool isPrivate;
  final bool isVerified;
  final double totalEarnings;
  final bool allowFollowersToMessage;
  final double weeklyEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile( {
    required this.id,
    required this.userId,
    required this.userName,
    required this.bio,
    required this.website,
    required this.location,
    required this.buzEmail,
    required this.avatarUrl,
    required this.coverPhotoUrl,
    required this.badges,
    required this.followersCount,
    required this.followingCount,
    required this.postCount,
    required this.isPrivate,
    required this.isVerified,
    required this.totalEarnings,
    required this.allowFollowersToMessage,
    required this.weeklyEarned,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      bio: json['bio'] ?? '',
      website: json['website'] ?? '',
      location: json['location'] ?? '',
      buzEmail: json['businessEmail'] ?? '',
      avatarUrl: json['avatarUrl'] ?? '',
      coverPhotoUrl: json['coverPhotoUrl'] ?? '',
      badges: json['badges'] ?? [],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      isPrivate: json['isPrivate'] ?? false,
      isVerified: json['isVerified'] ?? false,
      totalEarnings: (json['totalEarnings'] ?? 0).toDouble(),
      allowFollowersToMessage: json['allowFollwersToMessage'] ?? false,
      weeklyEarned: (json['weeklyEarned'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}

class VirtualAccount {
  final String bankName;
  final String accountNumber;
  final String status;

  VirtualAccount({required this.bankName, required this.accountNumber, required this.status});

  factory VirtualAccount.fromJson(Map<String, dynamic> json) {
    return VirtualAccount(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      status: json['status'] ?? '',
    );
  }
}