// lib/features/search/providers/search_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/search_model.dart';
import '../services/search_api_service.dart';
import '../../social/models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State enums
// ─────────────────────────────────────────────────────────────────────────────

enum SearchPhase {
  idle,        // empty search bar — show trending / history
  suggesting,  // user is typing, show suggestions dropdown
  results,     // results are loaded
}

enum LoadState { idle, loading, loadingMore, error }

// ─────────────────────────────────────────────────────────────────────────────
// SearchProvider
// ─────────────────────────────────────────────────────────────────────────────

class SearchProvider extends ChangeNotifier {
  final SearchApiService _api;
  SearchProvider({SearchApiService? api}) : _api = api ?? SearchApiService();

  // ── State ────────────────────────────────────────────────────────────────────

  SearchPhase phase = SearchPhase.idle;
  SearchTab   activeTab = SearchTab.top;

  String _query = '';
  String get query => _query;

  // Suggestions
  List<Suggestion>        suggestions    = [];
  List<SearchHistoryItem> recentSearches = [];

  // Trending (idle screen)
  List<HashtagResult> trendingHashtags    = [];
  List<UserResult>    suggestedUsers      = [];
  bool                trendingLoaded      = false;

  // Per-tab results
  List<UserResult>    userResults    = [];
  List<Post>          postResults    = [];
  List<HashtagResult> hashtagResults = [];
  TopResult?          topResult;

  // Pagination per tab
  final Map<SearchTab, String?> _cursors  = {};
  final Map<SearchTab, bool>    _hasMore  = {};

  // Load states per tab
  final Map<SearchTab, LoadState> _loadStates = {
    for (final t in SearchTab.values) t: LoadState.idle
  };

  // Errors per tab
  final Map<SearchTab, String?> _errors = {};

  LoadState loadState(SearchTab tab) => _loadStates[tab] ?? LoadState.idle;
  bool      hasMore(SearchTab tab)   => _hasMore[tab]    ?? false;
  String?   error(SearchTab tab)     => _errors[tab];

  // ── Debounce ─────────────────────────────────────────────────────────────────

  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 350);

  // ─────────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────────

  /// Called on every keystroke in the search field
  // ADD this new method to SearchProvider
  Future<void> _loadHistory() async {
    try {
      recentSearches = await _api.getHistory();
      notifyListeners();
    } catch (_) {}
  }

  void onQueryChanged(String value) {
    _query = value;

    if (value.trim().isEmpty) {
      _debounce?.cancel();
      phase = SearchPhase.idle;
      suggestions = [];
      notifyListeners();
      _ensureTrending();
      _loadHistory(); // ← ADD THIS
      return;
    }

    phase = SearchPhase.suggesting;
    notifyListeners();

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _fetchSuggestions(value));
  }

  /// Called when user submits search (keyboard action or taps suggestion)
  void submitSearch(String q) {
    _debounce?.cancel();
    _query = q;
    phase  = SearchPhase.results;
    _resetAllTabs();
    notifyListeners();
    _fetchTab(activeTab);
  }

  /// Tab switch
  void switchTab(SearchTab tab) {
    if (activeTab == tab) return;
    activeTab = tab;
    notifyListeners();

    // Only fetch if we haven't loaded this tab yet
    if (_isTabEmpty(tab)) {
      _fetchTab(tab);
    }
  }

  /// Load next page for the active tab (infinite scroll)
  void loadMore() {
    if (loadState(activeTab) == LoadState.loading ||
        loadState(activeTab) == LoadState.loadingMore) return;
    if (!hasMore(activeTab)) return;
    _fetchTab(activeTab, isLoadMore: true);
  }

  /// Pull-to-refresh for the active tab
  Future<void> refresh() async {
    _resetTab(activeTab);
    await _fetchTab(activeTab);
  }

  void clearSearch() {
    _debounce?.cancel();
    _query         = '';
    phase          = SearchPhase.idle;
    suggestions    = [];
    notifyListeners();
  }

  // ── Search history ──────────────────────────────────────────────────────────

  Future<void> deleteHistoryItem(String id) async {
    recentSearches.removeWhere((s) => s.id == id);
    notifyListeners();
    try { await _api.deleteHistoryItem(id); } catch (_) {}
  }

  Future<void> clearHistory() async {
    recentSearches = [];
    notifyListeners();
    try { await _api.clearHistory(); } catch (_) {}
  }

  // ── User follow toggle (optimistic) ──────────────────────────────────────────

  void toggleFollowUser(String userId, bool nowFollowing) {
    userResults = userResults.map((u) {
      if (u.userId == userId) return u.copyWith(isFollowing: nowFollowing);
      return u;
    }).toList();

    final tu = topResult;
    if (tu != null) {
      final updatedUsers = tu.users.map((u) {
        if (u.userId == userId) return u.copyWith(isFollowing: nowFollowing);
        return u;
      }).toList();
      topResult = TopResult(users: updatedUsers, posts: tu.posts, hashtags: tu.hashtags);
    }

    suggestedUsers = suggestedUsers.map((u) {
      if (u.userId == userId) return u.copyWith(isFollowing: nowFollowing);
      return u;
    }).toList();

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Private
  // ─────────────────────────────────────────────────────────────────────────────

  Future<void> _fetchSuggestions(String q) async {
    try {
      final result = await _api.getSuggestions(q);
      if (_query != q) return; // stale
      suggestions    = result.suggestions;
      recentSearches = result.recentSearches;
      notifyListeners();
    } catch (_) {
      // suggestions failure is silent
    }
  }

  Future<void> _ensureTrending() async {
    if (trendingLoaded) return;
    try {
      final result = await _api.getTrending();
      trendingHashtags = result.hashtags;
      suggestedUsers   = result.suggestedUsers;
    } catch (_) {
      // Fail gracefully — lists stay empty, UI still unblocks below
    } finally {
      trendingLoaded = true; // Always unblock the idle view
      notifyListeners();
    }
  }

  Future<void> _fetchTab(SearchTab tab, {bool isLoadMore = false}) async {
    if (_query.trim().isEmpty) return;

    _setLoadState(tab, isLoadMore ? LoadState.loadingMore : LoadState.loading);
    _errors[tab] = null;

    try {
      final cursor = isLoadMore ? _cursors[tab] : null;
      final raw    = await _api.search(q: _query, tab: tab, cursor: cursor);

      _cursors[tab] = raw.meta.nextCursor;
      _hasMore[tab] = raw.meta.hasMore;

      switch (tab) {
        case SearchTab.top:
          topResult = raw.topResult;

        case SearchTab.users:
          if (isLoadMore) {
            userResults = [...userResults, ...raw.users];
          } else {
            userResults = raw.users;
          }

        case SearchTab.posts:
          if (isLoadMore) {
            postResults = [...postResults, ...raw.posts];
          } else {
            postResults = raw.posts;
          }

        case SearchTab.hashtags:
          if (isLoadMore) {
            hashtagResults = [...hashtagResults, ...raw.hashtags];
          } else {
            hashtagResults = raw.hashtags;
          }
      }

      _setLoadState(tab, LoadState.idle);
    } catch (e) {
      _errors[tab] = e.toString().replaceFirst('Exception: ', '');
      _setLoadState(tab, LoadState.error);
    }
  }

  void _setLoadState(SearchTab tab, LoadState state) {
    _loadStates[tab] = state;
    notifyListeners();
  }

  void _resetTab(SearchTab tab) {
    _cursors[tab]    = null;
    _hasMore[tab]    = false;
    _loadStates[tab] = LoadState.idle;
    _errors[tab]     = null;
    switch (tab) {
      case SearchTab.top:      topResult      = null;
      case SearchTab.users:    userResults    = [];
      case SearchTab.posts:    postResults    = [];
      case SearchTab.hashtags: hashtagResults = [];
    }
  }

  void _resetAllTabs() {
    for (final t in SearchTab.values) _resetTab(t);
  }

  bool _isTabEmpty(SearchTab tab) {
    switch (tab) {
      case SearchTab.top:      return topResult == null;
      case SearchTab.users:    return userResults.isEmpty;
      case SearchTab.posts:    return postResults.isEmpty;
      case SearchTab.hashtags: return hashtagResults.isEmpty;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FollowListProvider — used by followers/following screens
// ─────────────────────────────────────────────────────────────────────────────

class FollowListProvider extends ChangeNotifier {
  final SearchApiService _api;
  final String userId;
  final bool isFollowers; // true = followers, false = following

  FollowListProvider({
    required this.userId,
    required this.isFollowers,
    SearchApiService? api,
  }) : _api = api ?? SearchApiService();

  List<UserResult> users    = [];
  bool             loading  = false;
  bool             loadingMore = false;
  bool             hasMore  = false;
  String?          error;
  String?          _cursor;

  final _searchCtrl = StreamController<String>.broadcast();
  Timer?            _debounce;
  String            _q = '';

  Future<void> init() => _fetch();

  Future<void> refresh() async {
    _cursor = null;
    users   = [];
    hasMore = false;
    await _fetch();
  }

  Future<void> loadMore() async {
    if (loadingMore || !hasMore) return;
    await _fetch(isLoadMore: true);
  }

  void onSearch(String q) {
    _q = q;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _cursor = null;
      users   = [];
      _fetch();
    });
  }

  void toggleFollow(String userId, bool nowFollowing) {
    users = users.map((u) {
      if (u.userId == userId) return u.copyWith(isFollowing: nowFollowing);
      return u;
    }).toList();
    notifyListeners();
  }

  Future<void> _fetch({bool isLoadMore = false}) async {
    if (isLoadMore) {
      loadingMore = true;
    } else {
      loading = true;
      error   = null;
    }
    notifyListeners();

    try {
      final result = isFollowers
          ? await _api.getFollowers(userId: userId, cursor: _cursor, q: _q)
          : await _api.getFollowing(userId: userId, cursor: _cursor, q: _q);

      _cursor = result.meta.nextCursor;
      hasMore = result.meta.hasMore;

      if (isLoadMore) {
        users = [...users, ...result.users];
      } else {
        users = result.users;
      }
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      loading     = false;
      loadingMore = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.close();
    super.dispose();
  }
}