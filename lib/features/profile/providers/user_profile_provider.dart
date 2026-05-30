import 'package:everywhere/features/profile/models/profile_initial_data.dart';
import 'package:everywhere/features/social/models/post_model.dart';
import 'package:everywhere/features/social/services/social_api_service.dart';
import 'package:everywhere/models/user_profile_model.dart';
import 'package:flutter/foundation.dart';

/// Manages a single OTHER user's profile.
/// Created fresh per route — no global state, no persistence.
/// Wrap UserProfileScreen in ChangeNotifierProvider when navigating.
class UserProfileProvider with ChangeNotifier {
  static const int _pageSize = 15;

  final SocialApiService _api = SocialApiService();

  // ─── State ─────────────────────────────────────────────────────────────────
  ProfileInitialData? _initial;   // lightweight data from navigation
  UserProfile? _profile;
  List<Post> _posts = [];

  bool _profileLoading = false;
  bool _postsLoading = false;
  bool _postsLoadingMore = false;
  bool _hasMorePosts = true;
  String? _lastPostId;
  String? _error;

  // ─── Getters ───────────────────────────────────────────────────────────────
  UserProfile? get profile => _profile;
  List<Post> get posts => _posts;
  bool get profileLoading => _profileLoading;
  bool get postsLoading => _postsLoading;
  bool get postsLoadingMore => _postsLoadingMore;
  bool get hasMorePosts => _hasMorePosts;
  String? get error => _error;
  bool get isFollowing => _profile?.isFollowing ?? false;
  bool get isPrivateAndNotFollowing =>
      (_profile?.isPrivate ?? false) && !(_profile?.isFollowing ?? false);

  // Quick-access display values — fallback to initialData before profile loads
  String get displayUserName => _profile?.userName ?? _initial?.userName ?? '';
  String? get displayAvatar => _profile?.avatar ?? _initial?.avatar;
  String? get displayName => _profile?.displayName ?? _initial?.displayName;
  bool get displayVerified =>
      _profile?.isKycVerified ?? _initial?.isVerified ?? false;

  // ─── Init ──────────────────────────────────────────────────────────────────

  void setInitialData(ProfileInitialData data) {
    _initial = data;
    // Don't notify — called before first build
  }

  Future<void> load(String userId) async {
    await Future.wait([
      _loadProfile(userId),
      _loadInitialPosts(userId),
    ]);
  }

  Future<void> refresh(String userId) async {
    await Future.wait([
      _loadProfile(userId),
      _refreshPosts(userId),
    ]);
  }

  // ─── Profile ───────────────────────────────────────────────────────────────

  Future<void> _loadProfile(String userId) async {
    _profileLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.getUserProfile(userId);
      _profile = UserProfile.fromJson(response['profile']);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  // ─── Posts (paginated) ─────────────────────────────────────────────────────

  Future<void> _loadInitialPosts(String userId) async {
    if (_postsLoading) return;
    _postsLoading = true;
    _posts = [];
    _lastPostId = null;
    _hasMorePosts = true;
    notifyListeners();
    try {
      final result = await _api.getUserPostsPaginated(userId, limit: _pageSize);
      _posts = _parsePosts(result['posts']);
      _hasMorePosts = result['hasMore'] ?? false;
      _lastPostId = _posts.isNotEmpty ? _posts.last.postId : null;
    } catch (e) {
      debugPrint('[UserProfileProvider] load posts: $e');
    } finally {
      _postsLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMorePosts(String userId) async {
    if (_postsLoadingMore || !_hasMorePosts || _lastPostId == null) return;
    _postsLoadingMore = true;
    notifyListeners();
    try {
      final result = await _api.getUserPostsPaginated(
        userId,
        lastPostId: _lastPostId,
        limit: _pageSize,
      );
      final more = _parsePosts(result['posts']);
      _posts.addAll(more);
      _hasMorePosts = result['hasMore'] ?? false;
      if (more.isNotEmpty) _lastPostId = more.last.postId;
    } catch (e) {
      debugPrint('[UserProfileProvider] load more: $e');
    } finally {
      _postsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _refreshPosts(String userId) async {
    _posts = [];
    _lastPostId = null;
    _hasMorePosts = true;
    await _loadInitialPosts(userId);
  }

  // ─── Follow ────────────────────────────────────────────────────────────────

  Future<void> toggleFollow() async {
    if (_profile == null) return;
    final was = _profile!.isFollowing;
    _profile = _profile!.copyWith(
      isFollowing: !was,
      followerCount: was
          ? _profile!.followerCount - 1
          : _profile!.followerCount + 1,
    );
    notifyListeners();
    try {
      if (was) {
        await _api.unfollowUser(_profile!.userId);
      } else {
        await _api.followUser(_profile!.userId);
      }
    } catch (e) {
      // Revert on failure
      _profile = _profile!.copyWith(
        isFollowing: was,
        followerCount:
        was ? _profile!.followerCount + 1 : _profile!.followerCount - 1,
      );
      notifyListeners();
      rethrow;
    }
  }

  List<Post> _parsePosts(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((j) => Post.fromJson(j)).toList();
  }
}