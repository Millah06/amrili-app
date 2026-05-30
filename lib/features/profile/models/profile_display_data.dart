import 'package:everywhere/models/user_profile_model.dart';
import 'cached_profile_data.dart';
import 'profile_initial_data.dart';

/// A unified read-only model consumed by profile header widgets.
/// Constructed from UserProfile (full), CachedProfileData (own profile cache),
/// or ProfileInitialData (lightweight nav data).
/// Null stats mean "not yet loaded" → show placeholder text.
class ProfileDisplayData {
  final String userId;
  final String userName;
  final String? displayName;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final String? location;
  final String? country;
  final String? website;
  final String? buzEmail;
  final bool isVerified;
  final bool isPrivate;
  final bool isFollowing;
  // Nullable = "not yet loaded" — header shows "_" placeholder
  final int? followerCount;
  final int? followingCount;
  final int? postCount;
  final bool isFullyLoaded;

  const ProfileDisplayData({
    required this.userId,
    required this.userName,
    this.displayName,
    this.bio,
    this.avatar,
    this.coverImage,
    this.location,
    this.country,
    this.website,
    this.buzEmail,
    this.isVerified = false,
    this.isPrivate = false,
    this.isFollowing = false,
    this.followerCount,
    this.followingCount,
    this.postCount,
    this.isFullyLoaded = false,
  });

  factory ProfileDisplayData.fromProfile(UserProfile p) => ProfileDisplayData(
    userId: p.userId,
    userName: p.userName,
    displayName: p.displayName,
    bio: p.bio,
    avatar: p.avatar,
    coverImage: p.coverImage,
    location: p.location,
    website: p.website,
    buzEmail: p.buzEmail,
    isVerified: p.isKycVerified,
    isPrivate: p.isPrivate,
    isFollowing: p.isFollowing,
    followerCount: p.followerCount,
    followingCount: p.followingCount,
    postCount: p.postCount,
    isFullyLoaded: true,
  );

  factory ProfileDisplayData.fromCache(CachedProfileData c) =>
      ProfileDisplayData(
        userId: c.userId,
        userName: c.userName,
        displayName: c.displayName,
        bio: c.bio,
        avatar: c.avatar,
        coverImage: c.coverImage,
        location: c.location,
        country: c.country,
        website: c.website,
        buzEmail: c.buzEmail,
        isVerified: c.isVerified,
        isPrivate: c.isPrivate,
        followerCount: c.followerCount,
        followingCount: c.followingCount,
        postCount: c.postCount,
        isFullyLoaded: false,
      );

  factory ProfileDisplayData.fromInitial(ProfileInitialData i) =>
      ProfileDisplayData(
        userId: i.userId,
        userName: i.userName ?? '',
        displayName: i.displayName,
        avatar: i.avatar,
        isVerified: i.isVerified ?? false,
        // Stats are unknown — show "_" placeholders
        isFullyLoaded: false,
      );

  /// Formatted count. Returns "_" when null (not loaded).
  String get formattedFollowers => _fmt(followerCount);
  String get formattedFollowing => _fmt(followingCount);
  String get formattedPosts => _fmt(postCount);

  static String _fmt(int? n) {
    if (n == null) return '_';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}