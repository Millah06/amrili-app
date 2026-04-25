// lib/providers/feed_provider.dart - COMPLETE WITH ALL METHODS

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../services/social_api_service.dart';
import '../models/post_model.dart';

enum FeedType { forYou, following }

class FeedProvider with ChangeNotifier {

  final SocialApiService _apiService = SocialApiService();


  FeedType _currentFeedType = FeedType.forYou;
  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastPostId;
  double? _lastScore;
  String? _error;

  // CACHE MANAGEMENT
  DateTime? _lastLoadTime;
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  FeedType get currentFeedType => _currentFeedType;
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;




  // Check if cache is still valid
  bool get _isCacheValid {
    if (_lastLoadTime == null || _posts.isEmpty) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  void switchFeedType(FeedType type) {
    if (_currentFeedType == type) return;

    _currentFeedType = type;
    // Clear cache when switching feed type
    _lastLoadTime = null;
    loadFeed(refresh: true);
  }

  Future<void> loadFeed({bool refresh = false, bool force = false}) async {
    // If cache is valid and not forcing refresh, skip
    if (!force && !refresh && _isCacheValid) {
      print('✅ Using cached feed data (${_posts.length} posts)');
      return;
    }

    if (_isLoading) return;

    if (refresh) {
      _posts = [];
      _lastPostId = null;
      _lastScore = null;
      _hasMore = true;
      _error = null;
      _lastLoadTime = null;
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = _currentFeedType == FeedType.forYou
          ? await _apiService.getForYouFeed(
        limit: 20,
        lastPostId: _lastPostId,
        lastScore: _lastScore,
      )
          : await _apiService.getFollowingFeed(
        limit: 20,
        lastPostId: _lastPostId,
      );

      final newPosts = (response['posts'] as List)
          .map((json) => Post.fromJson(json))
          .toList();

      if (refresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      _hasMore = response['hasMore'] ?? false;
      if (newPosts.isNotEmpty) {
        _lastPostId = newPosts.last.postId;
        if (_currentFeedType == FeedType.forYou) {
          _lastScore = newPosts.last.score;
        }
      }

      // Update cache timestamp
      _lastLoadTime = DateTime.now();
      print('✅ Feed loaded and cached (${_posts.length} posts)');
    } catch (e) {
      _error = e.toString();
      debugPrint('Feed load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh method
  Future<void> forceRefresh() async {
    print('🔄 Force refreshing feed...');
    await loadFeed(refresh: true, force: true);
  }

  // Invalidate cache (call when user creates/deletes post)
  void invalidateCache() {
    _lastLoadTime = null;
    print('🗑️ Cache invalidated');
  }

  void removePost(String postId) {
    _posts.removeWhere((p) => p.postId == postId);
    notifyListeners();
  }

  void updatePost(String postId, Post updatedPost) {
    final postIndex = _posts.indexWhere((p) => p.postId == postId);
    if (postIndex != -1) {
      _posts[postIndex] = updatedPost;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      final postIndex = _posts.indexWhere((p) => p.postId == postId);
      if (postIndex == -1) return;

      final post = _posts[postIndex];
      final wasLiked = post.isLikedByCurrentUser;

      // Optimistic update
      _posts[postIndex] = post.copyWith(
        isLikedByCurrentUser: !wasLiked,
        likeCount: wasLiked ? post.likeCount - 1 : post.likeCount + 1,
      );
      notifyListeners();

      // Call API
      await _apiService.likePost(postId);
    } catch (e) {
      // Revert on error
      final postIndex = _posts.indexWhere((p) => p.postId == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          isLikedByCurrentUser: !post.isLikedByCurrentUser,
          likeCount: post.isLikedByCurrentUser
              ? post.likeCount - 1
              : post.likeCount + 1,
        );
        notifyListeners();
      }

      debugPrint('Toggle like error: $e');
      rethrow;
    }
  }

  Future<void> toggleFollow(String userId) async {
    try {
      final wasFollowing = _posts.firstWhere((p) => p.userId == userId).isFollowing;

      // Optimistic update - update all posts by this user
      for (var i = 0; i < _posts.length; i++) {
        if (_posts[i].userId == userId) {
          _posts[i] = _posts[i].copyWith(isFollowing: !wasFollowing);
        }
      }
      notifyListeners();

      // Call API
      if (wasFollowing) {
        await _apiService.unfollowUser(userId);
      } else {
        await _apiService.followUser(userId);
      }
    } catch (e) {
      // Revert on error
      final wasFollowing = _posts.firstWhere((p) => p.userId == userId).isFollowing;
      for (var i = 0; i < _posts.length; i++) {
        if (_posts[i].userId == userId) {
          _posts[i] = _posts[i].copyWith(isFollowing: !wasFollowing);
        }
      }
      notifyListeners();

      debugPrint('Toggle follow error: $e');
      rethrow;
    }
  }

  Future<void> toggleSave(String postId) async {
    try {
      final postIndex = _posts.indexWhere((p) => p.postId == postId);
      if (postIndex == -1) return;

      final post = _posts[postIndex];
      final wasSaved = post.isSaved;

      // Optimistic update
      _posts[postIndex] = post.copyWith(isSaved: !wasSaved);
      notifyListeners();

      // Call API
      if (wasSaved) {
        await _apiService.unsavePost(postId);
      } else {
        await _apiService.savePost(postId);
      }
    } catch (e) {
      // Revert on error
      final postIndex = _posts.indexWhere((p) => p.postId == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          isSaved: !_posts[postIndex].isSaved,
        );
        notifyListeners();
      }

      debugPrint('Toggle save error: $e');
      rethrow;
    }
  }

  // State
  Map<String, List<Comment>> comments = {};
  Map<String, String?> _nextCursors = {};
  Map<String, bool> _loadingComments = {};
  Map<String, bool> _hasMoreComments = {};
  String? commentError;

// Accessors (used by the sheet)
  bool isLoadingCommentsFor(String postId) => _loadingComments[postId] ?? false;
  bool hasMoreCommentsFor(String postId) => _hasMoreComments[postId] ?? true;

  Future<void> fetchComments(String postId, {bool refresh = false}) async {
    if (_loadingComments[postId] == true) return;

    if (refresh) {
      _hasMoreComments[postId] = true;
      _nextCursors[postId] = null;
      comments[postId] = [];
      notifyListeners();
    }

    if (_hasMoreComments[postId] == false) return;

    _loadingComments[postId] = true;
    notifyListeners();

    try {
      final response = await _apiService.fetchComments(
        postId,
        cursor: _nextCursors[postId], // ✅ per-post cursor
      );

      final newComments = (response['comments'] as List)
          .map((e) => Comment.fromJson(e))
          .toList();

      // ✅ Append instead of replace
      comments[postId] = [...(comments[postId] ?? []), ...newComments];
      _nextCursors[postId] = response['nextCursor'];
      _hasMoreComments[postId] = response['hasMore'] ?? false;
    } catch (e) {
      commentError = e.toString();
    } finally {
      _loadingComments[postId] = false; // ✅ was _isLoading = false
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String text) async {
    try {
      final data = await _apiService.commentOnPost(postId: postId, text: text);

      // Update comment count
      final postIndex = _posts.indexWhere((p) => p.postId == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(
          commentCount: _posts[postIndex].commentCount + 1,
        );
      }

      // ✅ Prepend the new comment directly — no need for a full refresh
      final newComment = Comment.fromJson(data['comment']);
      comments[postId] = [newComment, ...(comments[postId] ?? [])];
      notifyListeners();
    } catch (e) {
      debugPrint('Add comment error: $e');
      rethrow;
    }
  }

  void updatePostAfterReward(String postId, int newRewardCount, double newTotal) {
    final postIndex = _posts.indexWhere((p) => p.postId == postId);
    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(
        rewardCount: newRewardCount,
        rewardPointsTotal: newTotal,
      );
      notifyListeners();
    }
  }

  void updatePostAfterBoost(String postId) {
    final postIndex = _posts.indexWhere((p) => p.postId == postId);
    if (postIndex != -1) {
      _posts[postIndex] = _posts[postIndex].copyWith(isBoosted: true);
      notifyListeners();
    }
  }

  void addNewPost(Post post) {
    _posts.insert(0, post);
    notifyListeners();
  }


}

