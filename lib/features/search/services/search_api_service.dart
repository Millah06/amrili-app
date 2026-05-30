// lib/features/search/services/search_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/search_model.dart';
import '../../social/models/post_model.dart'; // your existing Post model

// ─────────────────────────────────────────────────────────────────────────────
// Centralise your base URL (already done in your codebase presumably)
// ─────────────────────────────────────────────────────────────────────────────

const _kBaseUrl = 'https://everywhere-data-app.onrender.com'; // replace with your constant

class SearchApiService {
  final _client = http.Client();

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Main search ─────────────────────────────────────────────────────────────

  Future<_SearchRawResult> search({
    required String q,
    required SearchTab tab,
    String? cursor,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_kBaseUrl/search').replace(queryParameters: {
      'q':     q,
      'tab':   tab.key,
      'limit': '$limit',
      if (cursor != null) 'cursor': cursor,
    });

    final res = await _client.get(uri, headers: await _headers());
    _checkStatus(res);

    final body = json.decode(res.body) as Map<String, dynamic>;
    return _SearchRawResult(
      body: body,
      meta: PageMeta.fromJson(body['meta'] ?? {}),
    );
  }

  // ── Suggestions ─────────────────────────────────────────────────────────────

  Future<({List<Suggestion> suggestions, List<SearchHistoryItem> recentSearches})>
  getSuggestions(String q) async {
    final uri = Uri.parse('$_kBaseUrl/search/suggestions').replace(
      queryParameters: {'q': q, 'limit': '6'},
    );
    final res = await _client.get(uri, headers: await _headers());
    _checkStatus(res);

    final body = json.decode(res.body) as Map<String, dynamic>;
    final suggestions    = (body['suggestions']    as List? ?? []).map((e) => Suggestion.fromJson(e)).toList();
    final recentSearches = (body['recentSearches'] as List? ?? []).map((e) => SearchHistoryItem.fromJson(e)).toList();

    return (suggestions: suggestions, recentSearches: recentSearches);
  }

  // ── Trending ─────────────────────────────────────────────────────────────────

  Future<({List<HashtagResult> hashtags, List<UserResult> suggestedUsers})>
  getTrending() async {
    final uri = Uri.parse('$_kBaseUrl/search/trending');
    final res = await _client.get(uri, headers: await _headers());
    _checkStatus(res);

    final body = json.decode(res.body) as Map<String, dynamic>;
    final hashtags = (body['hashtags'] as List? ?? []).map((e) => HashtagResult.fromJson(e)).toList();
    final users    = (body['suggestedUsers'] as List? ?? []).map((e) => UserResult.fromJson(e)).toList();

    return (hashtags: hashtags, suggestedUsers: users);
  }

  // ── Search history ──────────────────────────────────────────────────────────

  Future<List<SearchHistoryItem>> getHistory() async {
    final uri = Uri.parse('$_kBaseUrl/search/history');
    final res = await _client.get(uri, headers: await _headers());
    _checkStatus(res);
    final body = json.decode(res.body) as Map<String, dynamic>;
    return (body['data'] as List? ?? []).map((e) => SearchHistoryItem.fromJson(e)).toList();
  }

  Future<void> deleteHistoryItem(String id) async {
    final uri = Uri.parse('$_kBaseUrl/search/history/$id');
    await _client.delete(uri, headers: await _headers());
  }

  Future<void> clearHistory() async {
    final uri = Uri.parse('$_kBaseUrl/search/history');
    await _client.delete(uri, headers: await _headers());
  }

  // ── Followers / Following ───────────────────────────────────────────────────

  Future<({List<UserResult> users, PageMeta meta})> getFollowers({
    required String userId,
    String? cursor,
    String? q,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_kBaseUrl/users/$userId/followers').replace(
      queryParameters: {
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    final res = await _client.get(uri, headers: await _headers());
    _checkStatus(res);
    return _parseUserList(json.decode(res.body));
  }

  Future<({List<UserResult> users, PageMeta meta})> getFollowing({
    required String userId,
    String? cursor,
    String? q,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_kBaseUrl/users/$userId/following').replace(
      queryParameters: {
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    final res = await _client.get(uri, headers: await _headers());
    _checkStatus(res);
    return _parseUserList(json.decode(res.body));
  }

  // ── Internals ───────────────────────────────────────────────────────────────

  ({List<UserResult> users, PageMeta meta}) _parseUserList(Map<String, dynamic> body) {
    final users = (body['data'] as List? ?? []).map((e) => UserResult.fromJson(e)).toList();
    final meta  = PageMeta.fromJson(body['meta'] ?? {});
    return (users: users, meta: meta);
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      final body = json.decode(res.body);
      throw Exception(body['message'] ?? 'Request failed (${res.statusCode})');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal raw result — decoded by provider
// ─────────────────────────────────────────────────────────────────────────────

class _SearchRawResult {
  final Map<String, dynamic> body;
  final PageMeta meta;
  const _SearchRawResult({required this.body, required this.meta});
}

// Public helper to parse typed results from the raw body
extension SearchRawResultX on _SearchRawResult {
  List<UserResult> get users =>
      (body['data'] as List? ?? []).map((e) => UserResult.fromJson(e)).toList();

  List<HashtagResult> get hashtags =>
      (body['data'] as List? ?? []).map((e) => HashtagResult.fromJson(e)).toList();

  List<Post> get posts =>
      (body['data'] as List? ?? []).map((e) => Post.fromJson(e)).toList();

  TopResult get topResult {
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final rawPosts = (data['posts'] as List? ?? []).map((e) => Post.fromJson(e)).toList();
    return TopResult.fromJson(data, rawPosts);
  }
}