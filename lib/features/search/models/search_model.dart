// lib/features/search/models/search_models.dart

// ─────────────────────────────────────────────────────────────────────────────
// Search result models — mirror backend response shapes exactly
// ─────────────────────────────────────────────────────────────────────────────

class UserResult {
  final String userId;
  final String userName;
  final String userHandle;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final String? topBadge;
  final int followersCount;
  final bool isFollowing;
  final bool isMutual;
  final int mutualFollowersCount;

  const UserResult({
    required this.userId,
    required this.userName,
    required this.userHandle,
    this.avatarUrl,
    this.bio,
    required this.isVerified,
    this.topBadge,
    required this.followersCount,
    required this.isFollowing,
    required this.isMutual,
    required this.mutualFollowersCount,
  });

  factory UserResult.fromJson(Map<String, dynamic> j) => UserResult(
    userId:               j['userId']              ?? '',
    userName:             j['userName']            ?? '',
    userHandle:           j['userHandle']          ?? '',
    avatarUrl:            j['avatarUrl'],
    bio:                  j['bio'],
    isVerified:           j['isVerified']          ?? false,
    topBadge:             j['topBadge'],
    followersCount:       j['followersCount']      ?? 0,
    isFollowing:          j['isFollowing']         ?? false,
    isMutual:             j['isMutual']            ?? false,
    mutualFollowersCount: j['mutualFollowersCount'] ?? 0,
  );

  UserResult copyWith({bool? isFollowing}) => UserResult(
    userId:               userId,
    userName:             userName,
    userHandle:           userHandle,
    avatarUrl:            avatarUrl,
    bio:                  bio,
    isVerified:           isVerified,
    topBadge:             topBadge,
    followersCount:       followersCount,
    isFollowing:          isFollowing ?? this.isFollowing,
    isMutual:             isMutual,
    mutualFollowersCount: mutualFollowersCount,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class HashtagResult {
  final String tag;
  final int postCount;
  final bool isTrending;
  final double trendScore;

  const HashtagResult({
    required this.tag,
    required this.postCount,
    required this.isTrending,
    required this.trendScore,
  });

  factory HashtagResult.fromJson(Map<String, dynamic> j) => HashtagResult(
    tag:        j['tag']        ?? '',
    postCount:  j['postCount']  ?? 0,
    isTrending: j['isTrending'] ?? false,
    trendScore: (j['trendScore'] ?? 0).toDouble(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class TopResult {
  final List<UserResult> users;
  final List<dynamic> posts;     // reuse your existing Post model
  final List<HashtagResult> hashtags;

  const TopResult({
    required this.users,
    required this.posts,
    required this.hashtags,
  });

  factory TopResult.fromJson(Map<String, dynamic> j, List<dynamic> parsedPosts) => TopResult(
    users:    (j['users']    as List? ?? []).map((e) => UserResult.fromJson(e)).toList(),
    posts:    parsedPosts,
    hashtags: (j['hashtags'] as List? ?? []).map((e) => HashtagResult.fromJson(e)).toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

enum SuggestionKind { user, hashtag, query }

class Suggestion {
  final SuggestionKind kind;
  final String label;
  final String? subLabel;
  final String? avatarUrl;
  final String? userId;
  final bool isVerified;

  const Suggestion({
    required this.kind,
    required this.label,
    this.subLabel,
    this.avatarUrl,
    this.userId,
    this.isVerified = false,
  });

  factory Suggestion.fromJson(Map<String, dynamic> j) => Suggestion(
    kind: _parseKind(j['kind']),
    label:      j['label']     ?? '',
    subLabel:   j['subLabel'],
    avatarUrl:  j['avatarUrl'],
    userId:     j['userId'],
    isVerified: j['isVerified'] ?? false,
  );

  static SuggestionKind _parseKind(String? k) {
    switch (k) {
      case 'user':    return SuggestionKind.user;
      case 'hashtag': return SuggestionKind.hashtag;
      default:        return SuggestionKind.query;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class SearchHistoryItem {
  final String id;
  final SuggestionKind kind;
  final String label;
  final String? subLabel;
  final String? avatarUrl;
  final String? userId;
  final DateTime searchedAt;

  const SearchHistoryItem({
    required this.id,
    required this.kind,
    required this.label,
    this.subLabel,
    this.avatarUrl,
    this.userId,
    required this.searchedAt,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> j) => SearchHistoryItem(
    id:         j['id']        ?? '',
    kind:       Suggestion._parseKind(j['kind']),
    label:      j['label']     ?? '',
    subLabel:   j['subLabel'],
    avatarUrl:  j['avatarUrl'],
    userId:     j['refUserId'],
    searchedAt: DateTime.tryParse(j['searchedAt'] ?? '') ?? DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class PageMeta {
  final bool hasMore;
  final String? nextCursor;

  const PageMeta({required this.hasMore, this.nextCursor});

  factory PageMeta.fromJson(Map<String, dynamic> j) => PageMeta(
    hasMore:    j['hasMore']    ?? false,
    nextCursor: j['nextCursor'],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

enum SearchTab { top, users, posts, hashtags }

extension SearchTabX on SearchTab {
  String get key {
    switch (this) {
      case SearchTab.top:      return 'top';
      case SearchTab.users:    return 'users';
      case SearchTab.posts:    return 'posts';
      case SearchTab.hashtags: return 'hashtags';
    }
  }

  String get label {
    switch (this) {
      case SearchTab.top:      return 'Top';
      case SearchTab.users:    return 'People';
      case SearchTab.posts:    return 'Posts';
      case SearchTab.hashtags: return 'Tags';
    }
  }
}