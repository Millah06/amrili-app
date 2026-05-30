import 'package:everywhere/features/social/models/post_model.dart';
import 'package:everywhere/features/social/services/social_api_service.dart';
import 'package:everywhere/features/profile/models/cached_profile_data.dart';
import 'package:everywhere/models/user_profile_model.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the CURRENT USER's profile only.
/// Lives at the app root (MultiProvider) — persists across navigation.
/// Loads cached data instantly on startup, refreshes from server silently.
class MyProfileProvider with ChangeNotifier {
  static const String _cacheKey = 'my_profile_v1';
  static const int _pageSize = 15;

  final SocialApiService _api = SocialApiService();
  final ApiService _rawApi = ApiService();

  // ─── State ─────────────────────────────────────────────────────────────────
  CachedProfileData? _cached;   // from SharedPreferences — instant render
  UserProfile? _profile;         // from server
  List<Post> _posts = [];
  List<Post> _savedPosts = [];

  bool _profileLoading = false;
  bool _postsLoading = false;
  bool _savedLoading = false;
  bool _postsLoadingMore = false;
  bool _hasMorePosts = true;
  String? _lastPostId;
  String? _error;

  // ─── Getters ───────────────────────────────────────────────────────────────
  CachedProfileData? get cached => _cached;
  UserProfile? get profile => _profile;
  List<Post> get posts => _posts;
  List<Post> get savedPosts => _savedPosts;
  bool get profileLoading => _profileLoading;
  bool get postsLoading => _postsLoading;
  bool get savedLoading => _savedLoading;
  bool get postsLoadingMore => _postsLoadingMore;
  bool get hasMorePosts => _hasMorePosts;
  String? get error => _error;
  bool get hasAnyProfileData => _cached != null || _profile != null;

  // ─── Init (called once on app start) ──────────────────────────────────────

  /// Call from main.dart or AppWrapper after auth is confirmed.
  Future<void> initialize(String userId) async {
    await _loadCache();
    _silentRefreshProfile(userId);
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        _cached = CachedProfileData.decode(raw);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MyProfileProvider] cache read error: $e');
    }
  }

  Future<void> _persistCache(UserProfile p) async {
    try {
      final data = CachedProfileData.fromUserProfile(p);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, CachedProfileData.encode(data));
      _cached = data;
    } catch (e) {
      debugPrint('[MyProfileProvider] cache write error: $e');
    }
  }

  // ─── Profile ───────────────────────────────────────────────────────────────

  Future<void> _silentRefreshProfile(String userId) async {
    try {
      final response = await _api.getUserProfile(userId);
      _profile = UserProfile.fromJson(response['profile']);
      _error = null;
      await _persistCache(_profile!);
      notifyListeners();
    } catch (e) {
      debugPrint('[MyProfileProvider] silent refresh error: $e');
    }
  }

  /// Full refresh with loading indicator (pull-to-refresh).
  Future<void> refresh(String userId) async {
    _profileLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _api.getUserProfile(userId);
      _profile = UserProfile.fromJson(response['profile']);
      await _persistCache(_profile!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
    await Future.wait([
      refreshPosts(userId),
      loadSavedPosts(force: true),
    ]);
  }

  // ─── Posts (paginated) ─────────────────────────────────────────────────────

  Future<void> loadInitialPosts(String userId) async {
    if (_postsLoading) return;
    _postsLoading = true;
    _posts = [];
    _lastPostId = null;
    _hasMorePosts = true;
    notifyListeners();
    try {
      final result = await _api.getUserPostsPaginated(
        userId,
        limit: _pageSize,
      );
      _posts = _parsePosts(result['posts']);
      _hasMorePosts = result['hasMore'] ?? false;
      _lastPostId = _posts.isNotEmpty ? _posts.last.postId : null;
    } catch (e) {
      debugPrint('[MyProfileProvider] load posts error: $e');
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
      debugPrint('[MyProfileProvider] load more posts error: $e');
    } finally {
      _postsLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshPosts(String userId) async {
    _posts = [];
    _lastPostId = null;
    _hasMorePosts = true;
    await loadInitialPosts(userId);
  }

  // ─── Saved posts ───────────────────────────────────────────────────────────

  Future<void> loadSavedPosts({bool force = false}) async {
    if (_savedLoading) return;
    if (!force && _savedPosts.isNotEmpty) return;
    _savedLoading = true;
    notifyListeners();
    try {
      final raw = await _api.getSavedPosts();
      _savedPosts = raw.map((j) => Post.fromJson(j)).toList();
    } catch (e) {
      debugPrint('[MyProfileProvider] load saved error: $e');
    } finally {
      _savedLoading = false;
      notifyListeners();
    }
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  /// Called immediately after a successful profile text edit.
  /// Updates memory + cache instantly so the UI reflects changes before
  /// the server round-trip completes.
  void applyProfileEdit({
    String? bio,
    String? location,
    String? website,
    String? buzEmail,
    String? displayName,
  }) {
    if (_profile == null && _cached == null) return;

    // Update full profile if available
    if (_profile != null) {
      _profile = _profile!.copyWith(
        bio: bio ?? _profile!.bio,
        location: location ?? _profile!.location,
        website: website ?? _profile!.website,
        buzEmail: buzEmail ?? _profile!.buzEmail,
        displayName: displayName ?? _profile!.displayName,
      );
      _persistCache(_profile!); // update SharedPreferences immediately
    }

    // Also patch the cached data so it's consistent
    // (covers the case where _profile is null but _cached exists)
    if (_cached != null) {
      _cached = CachedProfileData(
        userId: _cached!.userId,
        userName: _cached!.userName,
        displayName: displayName ?? _cached!.displayName,
        bio: bio ?? _cached!.bio,
        avatar: _cached!.avatar,
        coverImage: _cached!.coverImage,
        location: location ?? _cached!.location,
        country: _cached!.country,
        website: website ?? _cached!.website,
        buzEmail: buzEmail ?? _cached!.buzEmail,
        isVerified: _cached!.isVerified,
        isPrivate: _cached!.isPrivate,
        followerCount: _cached!.followerCount,
        followingCount: _cached!.followingCount,
        postCount: _cached!.postCount,
      );
      // Persist patched cache even if _profile was null
      if (_profile == null) {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(_cacheKey, CachedProfileData.encode(_cached!));
        });
      }
    }

    notifyListeners();
  }

  /// Called after image uploads complete.
  /// Silently fetches the fresh profile from the server to pick up new
  /// avatar/cover URLs without any loading indicator.
  Future<void> handleProfileSaved(String userId) async {
    await _silentRefreshProfile(userId);
  }

  Future<bool> togglePrivateAccount() async {
    if (_profile == null) return false;
    final newVal = !_profile!.isPrivate;
    _profile = _profile!.copyWith(isPrivate: newVal);
    notifyListeners();
    try {
      await _rawApi.post('/users/me/toggle-private', {'isPrivate': newVal});
      await _persistCache(_profile!);
      return true;
    } catch (_) {
      _profile = _profile!.copyWith(isPrivate: !newVal);
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAllowFollowersToMessage() async {
    if (_profile == null) return false;
    final newVal = !_profile!.allowFollowersToMessage;
    _profile = _profile!.copyWith(allowFollowersToMessage: newVal);
    notifyListeners();
    try {
      await _rawApi.post(
          '/users/me/toggle-allow-messages', {'allowFollowersToMessage': newVal});
      return true;
    } catch (_) {
      _profile = _profile!.copyWith(allowFollowersToMessage: !newVal);
      notifyListeners();
      return false;
    }
  }

  void removePost(String postId) {
    _posts.removeWhere((p) => p.postId == postId);
    _savedPosts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

  void updatePost(String postId, Post updated) {
    final i = _posts.indexWhere((p) => p.postId == postId);
    if (i != -1) _posts[i] = updated;
    final j = _savedPosts.indexWhere((p) => p.postId == postId);
    if (j != -1) _savedPosts[j] = updated;
    notifyListeners();
  }

  void removeFromSaved(String postId) {
    _savedPosts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

  void invalidate() {
    SharedPreferences.getInstance().then((p) => p.remove(_cacheKey));
    _cached = null;
    _profile = null;
    _posts = [];
    _savedPosts = [];
    _error = null;
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  List<Post> _parsePosts(dynamic raw) {
    if (raw == null) return [];
    return (raw as List).map((j) => Post.fromJson(j)).toList();
  }
}