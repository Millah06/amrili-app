// lib/providers/profile_provider.dart - UPDATED WITHOUT FIRESTORE

import 'package:everywhere/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/social/models/post_model.dart';
import '../features/social/services/social_api_service.dart';
import '../models/user_profile_model.dart';


// lib/providers/profile_provider.dart - ADD CACHING
class ProfileProvider with ChangeNotifier {
  final SocialApiService _apiService = SocialApiService();
  final ApiService api = ApiService();

  UserProfile? _profile;
  List<Post> _userPosts = [];
  List<Post> _savedPosts = [];
  bool _isLoadingProfile = false;
  bool _isLoadingPosts = false;
  bool _isLoadingSaved = false;
  String? _error;

  // CACHE MANAGEMENT
  String? _cachedUserId;
  DateTime? _lastProfileLoadTime;
  DateTime? _lastPostsLoadTime;
  DateTime? _lastSavedLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  UserProfile? get profile => _profile;
  List<Post> get userPosts => _userPosts;
  List<Post> get savedPosts => _savedPosts;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingSaved => _isLoadingSaved;
  String? get error => _error;

  bool _isProfileCacheValid(String userId) {
    if (_cachedUserId != userId) return false;
    if (_lastProfileLoadTime == null || _profile == null) return false;
    return DateTime.now().difference(_lastProfileLoadTime!) < _cacheValidDuration;
  }

  bool get _isPostsCacheValid {
    if (_lastPostsLoadTime == null || _userPosts.isEmpty) return false;
    return DateTime.now().difference(_lastPostsLoadTime!) < _cacheValidDuration;
  }

  bool get _isSavedCacheValid {
    if (_lastSavedLoadTime == null) return false;
    return DateTime.now().difference(_lastSavedLoadTime!) < _cacheValidDuration;
  }

  Future<void> loadUserProfile(String userId, {bool force = false}) async {
    // Check cache
    if (!force && _isProfileCacheValid(userId)) {
      print('✅ Using cached profile data for: $userId');
      return;
    }

    _isLoadingProfile = true;
    _error = null;
    notifyListeners();

    try {
      print('🔍 Loading profile for userId: $userId');
      final response = await _apiService.getUserProfile(userId);

      _profile = UserProfile.fromJson(response['profile']);
      _cachedUserId = userId;
      _lastProfileLoadTime = DateTime.now();

      print('✅ Profile loaded and cached: ${_profile?.userName}');
    } catch (e) {
      print('❌ Profile error: $e');
      _error = e.toString();
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadUserPosts(String userId, {bool force = false}) async {
    // Check cache (but only if same user)
    if (!force && _cachedUserId == userId && _isPostsCacheValid) {
      print('✅ Using cached posts data (${_userPosts.length} posts)');
      return;
    }

    _isLoadingPosts = true;
    notifyListeners();

    try {
      print('📥 Loading posts for user: $userId');
      final posts = await _apiService.getUserPosts(userId);

      _userPosts = posts.map((json) => Post.fromJson(json)).toList();

      // Check save status
      for (var i = 0; i < _userPosts.length; i++) {
        final isSaved = await _apiService.isPostSaved(_userPosts[i].postId);
        _userPosts[i] = _userPosts[i].copyWith(isSaved: isSaved);
      }

      _lastPostsLoadTime = DateTime.now();
      print('✅ Posts loaded and cached: ${_userPosts.length} posts');
    } catch (e) {
      debugPrint('❌ Load user posts error: $e');
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  Future<void> loadSavedPosts({bool force = false}) async {
    // Check cache
    if (!force && _isSavedCacheValid) {
      print('✅ Using cached saved posts (${_savedPosts.length} posts)');
      return;
    }

    _isLoadingSaved = true;
    notifyListeners();

    try {
      print('📥 Loading saved posts...');
      final posts = await _apiService.getSavedPosts();

      _savedPosts = posts.map((json) => Post.fromJson(json)).toList();
      _lastSavedLoadTime = DateTime.now();

      print('✅ Saved posts loaded and cached: ${_savedPosts.length} posts');
    } catch (e) {
      debugPrint('❌ Load saved posts error: $e');
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  // Invalidate caches
  void invalidateCache() {
    _lastProfileLoadTime = null;
    _lastPostsLoadTime = null;
    _lastSavedLoadTime = null;
    print('🗑️ Profile cache invalidated');
  }

  void removePostFromUserPosts(String postId) {
    _userPosts.removeWhere((p) => p.postId == postId);
    _savedPosts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

// ... rest of existing methods

  Future<void> toggleFollow() async {
    if (_profile == null) return;

    try {
      final wasFollowing = _profile!.isFollowing;
      final previousFollowerCount = _profile!.followerCount;

      // Optimistic update
      _profile = _profile!.copyWith(
        isFollowing: !wasFollowing,
        followerCount: wasFollowing
            ? previousFollowerCount - 1
            : previousFollowerCount + 1,
      );
      notifyListeners();

      // Call API
      if (wasFollowing) {
        await _apiService.unfollowUser(_profile!.userId);
      } else {
        await _apiService.followUser(_profile!.userId);
      }
    } catch (e) {
      // Revert on error
      if (_profile != null) {
        _profile = _profile!.copyWith(
          isFollowing: !_profile!.isFollowing,
          followerCount: _profile!.isFollowing
              ? _profile!.followerCount - 1
              : _profile!.followerCount + 1,
        );
        notifyListeners();
      }
      debugPrint('Toggle follow error: $e');
      rethrow;
    }
  }

  void updatePostInLists(String postId, Post updatedPost) {
    // Update in user posts
    final userPostIndex = _userPosts.indexWhere((p) => p.postId == postId);
    if (userPostIndex != -1) {
      _userPosts[userPostIndex] = updatedPost;
    }

    // Update in saved posts
    final savedPostIndex = _savedPosts.indexWhere((p) => p.postId == postId);
    if (savedPostIndex != -1) {
      _savedPosts[savedPostIndex] = updatedPost;
    }

    notifyListeners();
  }

  void removePostFromSaved(String postId) {
    _savedPosts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

  Future<bool> togglePrivateAccount() async {

    // instant UI update
    final newValue = !_profile!.isPrivate;
    print(newValue);

    _profile = _profile!.copyWith(isPrivate: newValue);

    notifyListeners();

    try {
      await api.post('/users/me/toggle-private', {'isPrivate' : newValue});
      return true;
    } catch (e) {
      e.toString();
      return false;
    }
  }

  Future<bool> toggleAllowFollowersToMessage() async {

    // instant UI update
    final newValue = !_profile!.allowFollowersToMessage;
    print(newValue);

    _profile = _profile!.copyWith(allowFollowersToMessage: newValue);

    notifyListeners();

    try {
      await api.post('/users/me/toggle-allow-messages', {'allowFollowersToMessage' : newValue});
      return true;
    } catch (e) {
      e.toString();
      return false;
    }
  }

  void clear() {
    _profile = null;
    _userPosts = [];
    _savedPosts = [];
    _error = null;
    notifyListeners();
  }
}