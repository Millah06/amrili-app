import 'dart:convert';
import 'package:everywhere/models/user_profile_model.dart';

/// Lightweight profile data persisted to SharedPreferences.
/// Used for instant startup rendering before the server responds.
class CachedProfileData {
  final String userId;
  final String userName;
  final String? displayName;
  final String? bio;
  final String? avatar;
  final String? coverImage;
  final String? location;
  final String? country;       // ISO 3166-1 alpha-2 e.g. "NG"
  final String? website;
  final String? buzEmail;
  final bool isVerified;
  final bool isPrivate;
  final int followerCount;
  final int followingCount;
  final int postCount;

  const CachedProfileData({
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
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'displayName': displayName,
    'bio': bio,
    'avatar': avatar,
    'coverImage': coverImage,
    'location': location,
    'country': country,
    'website': website,
    'buzEmail': buzEmail,
    'isVerified': isVerified,
    'isPrivate': isPrivate,
    'followerCount': followerCount,
    'followingCount': followingCount,
    'postCount': postCount,
  };

  factory CachedProfileData.fromJson(Map<String, dynamic> json) =>
      CachedProfileData(
        userId: json['userId'] ?? '',
        userName: json['userName'] ?? '',
        displayName: json['displayName'],
        bio: json['bio'],
        avatar: json['avatar'],
        coverImage: json['coverImage'],
        location: json['location'],
        country: json['country'],
        website: json['website'],
        buzEmail: json['buzEmail'],
        isVerified: json['isVerified'] ?? false,
        isPrivate: json['isPrivate'] ?? false,
        followerCount: json['followerCount'] ?? 0,
        followingCount: json['followingCount'] ?? 0,
        postCount: json['postCount'] ?? 0,
      );

  factory CachedProfileData.fromUserProfile(UserProfile p) =>
      CachedProfileData(
        userId: p.userId,
        userName: p.userName,
        displayName: p.displayName,
        bio: p.bio,
        avatar: p.avatar,
        coverImage: p.coverImage,
        location: p.location,
        website: p.website,
        // NOTE: swap buzEmail for businessEmail if your model uses that field
        buzEmail: p.buzEmail,
        isVerified: p.isKycVerified,
        isPrivate: p.isPrivate,
        followerCount: p.followerCount,
        followingCount: p.followingCount,
        postCount: p.postCount,
      );

  static String encode(CachedProfileData d) => jsonEncode(d.toJson());
  static CachedProfileData decode(String raw) =>
      CachedProfileData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}