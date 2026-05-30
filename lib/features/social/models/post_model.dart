
class Post {
  final String postId;
  final String userId;
  final String userName;
  final String? topBadge;
  final String userHandle;
  final String? userAvatar;
  final String text;
  final String title;
  final List<String> images;
  final List<String> hashtags;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final int viewCount;

  // final int rewardCount;
  // final double rewardPointsTotal;

  final int giftCount;      // Total gifts received
  final int coinTotal;

  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final bool isRepost;
  final String? originalPostId;
  final String? originalUserName;
  final String? originalUserHandle;
  final double score;
  bool isLikedByCurrentUser;
  bool isFollowing;
  bool isSaved;
  int repostCount;

  Post({
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userHandle,
    this.userAvatar,
    this.topBadge,
    required this.title,
    required this.text,
    required this.images,
    this.hashtags = const [],
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    this.viewCount = 0,
    required this.giftCount,
    required this.coinTotal,
    required this.isBoosted,
    this.boostExpiresAt,
    this.isRepost = false,
    this.originalPostId,
    this.originalUserName,
    this.originalUserHandle,
    this.score = 0,
    this.isLikedByCurrentUser = false,
    this.isFollowing = false,
    this.isSaved = false,
    this.repostCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      userHandle: json['userHandle'] ?? '',
      topBadge: json['topBadge'],
      userAvatar: json['userAvatar'],
      title: json['title'] ?? '',
      text: json['text'] ?? '',
      images:      (json['images'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      hashtags: List<String>.from(json['hashtags'] ?? []),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      likeCount: json['likeCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      giftCount: json['giftCount'] ?? 0,
      coinTotal: json['coinTotal'] ?? 0,
      isBoosted: json['isBoosted'] ?? false,
      boostExpiresAt: _parseDateTime(json['boostExpiresAt']),
      isRepost: json['isRepost'] ?? false,
      originalPostId: json['originalPostId'],
      originalUserName: json['originalUserName'],
      originalUserHandle: json['originalUserHandle'],
      score: (json['algorithmScore'] ?? 0).toDouble(),
      isLikedByCurrentUser: json['isLikedByCurrentUser'] ?? false,
      isFollowing: json['isFollowing'] ?? false,
      isSaved: json['isSaved'] ?? false,
      repostCount: json['repostCount'] ?? 0,
    );
  }

  String get firstImage => images.isNotEmpty ? images.first : '';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is Map<String, dynamic>) {
      final seconds = value['_seconds'];
      final nanoseconds = value['_nanoseconds'] ?? 0;
      if (seconds != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (seconds * 1000) + (nanoseconds ~/ 1000000),
        );
      }
    }
    return null;
  }

  Post copyWith({
    int? likeCount,
    int? commentCount,
    int? viewCount,
    int? giftCount,
    int? coinTotal,
    bool? isLikedByCurrentUser,
    bool? isBoosted,
    bool? isFollowing,
    bool? isSaved,
    int? repostCount,
  }) {
    return Post(
      postId: postId,
      userId: userId,
      userName: userName,
      userHandle: userHandle,
      userAvatar: userAvatar,
      title: title,
      text: text,
      images: images,
      hashtags: hashtags,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewCount: viewCount ?? this.viewCount,
      giftCount: giftCount ?? this.giftCount,
      coinTotal: coinTotal ?? this.coinTotal,
      isBoosted: isBoosted ?? this.isBoosted,
      boostExpiresAt: boostExpiresAt,
      isRepost: isRepost,
      originalPostId: originalPostId,
      originalUserName: originalUserName,
      originalUserHandle: originalUserHandle,
      score: score,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isFollowing: isFollowing ?? this.isFollowing,
      isSaved: isSaved ?? this.isSaved,
      repostCount: repostCount ?? this.repostCount,
    );
  }

  bool get isBoostActive {
    if (!isBoosted || boostExpiresAt == null) return false;
    return DateTime.now().isBefore(boostExpiresAt!);
  }
}

