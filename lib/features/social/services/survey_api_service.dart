// =============================================================================
// lib/features/social/services/survey_api_service.dart
// -----------------------------------------------------------------------------
// PHASE 11 — SURVEY API CLIENT
// =============================================================================
//
// One thin HTTP client per survey endpoint. It mirrors SocialApiService exactly
// (same baseUrl, same Firebase-token header helpers) so it behaves identically
// to the rest of the social layer — auth-required calls send a Bearer token,
// read calls send it only if signed in (so guests can still view).
//
// Each method maps 1:1 to a backend route from PHASE11_PASS2_BACKEND_EDITS.md:
//   createSurvey   → POST   /social/surveys
//   getSurvey      → GET    /social/surveys/:id
//   submitResponse → POST   /social/surveys/:id/respond
//   getResults     → GET    /social/surveys/:id/results
//   closeSurvey    → POST   /social/surveys/:id/close
//
// Methods THROW on failure with the server's error message where possible, so
// the UI can show a precise reason (e.g. "Not enough coins", "already answered",
// "Only followers can answer"). We surface `code` too where the backend sends it.
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/survey_model.dart';

/// Thrown for any non-2xx survey response. Carries the human message + optional
/// machine `code` (e.g. INSUFFICIENT_COINS, RESULTS_LOCKED) so the UI can branch.
class SurveyApiException implements Exception {
  final String message;
  final String? code;
  final int statusCode;
  SurveyApiException(this.message, {this.code, required this.statusCode});
  @override
  String toString() => message;
}

class SurveyApiService {
  static const String baseUrl = 'https://api.amril.app';

  // ─── token helpers (identical pattern to SocialApiService) ──────────────────
  Future<String> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return await user.getIdToken() ?? '';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getOptionalHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken() ?? '';
    final headers = {'Content-Type': 'application/json'};
    if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Decode a response or throw a typed exception carrying the server message.
  Map<String, dynamic> _decodeOrThrow(http.Response res) {
    final body = res.body.isNotEmpty
        ? jsonDecode(res.body) as Map<String, dynamic>
        : <String, dynamic>{};
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    print(body);
    throw SurveyApiException(
      body['error']?.toString() ?? 'Request failed (${res.statusCode})',
      code: body['code']?.toString(),
      statusCode: res.statusCode,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CREATE — returns the created Survey (already shaped, isAuthor = true).
  // `questions` is the raw builder payload (see CreateSurveyScreen._toPayload).
  // ───────────────────────────────────────────────────────────────────────────
  Future<Survey> createSurvey({
    required String title,
    String description = '',
    bool anonymous = true,
    String audience = SurveyAudience.everyone,
    String resultVisibility = SurveyResultVisibility.afterVote,
    DateTime? closesAt,
    int rewardCoins = 0,
    int rewardBudget = 0,
    String text = '',
    List<String> hashtags = const [],
    required List<Map<String, dynamic>> questions,
  }) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/social/surveys'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'anonymous': anonymous,
        'audience': audience,
        'resultVisibility': resultVisibility,
        'closesAt': closesAt?.toIso8601String(),
        'rewardCoins': rewardCoins,
        'rewardBudget': rewardBudget,
        'text': text,
        'hashtags': hashtags,
        'questions': questions,
      }),
    );
    final body = _decodeOrThrow(res);
    return Survey.fromJson(body['survey'] as Map<String, dynamic>);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GET one survey (with viewer-specific state). Optional-auth.
  // ───────────────────────────────────────────────────────────────────────────
  Future<Survey> getSurvey(String surveyId) async {
    final headers = await _getOptionalHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/social/surveys/$surveyId'),
      headers: headers,
    );
    final body = _decodeOrThrow(res);
    return Survey.fromJson(body['survey'] as Map<String, dynamic>);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GET one survey BY ITS POST ID. The feed only knows a post's id, so the in-
  // feed SurveyCard uses this. Optional-auth.
  // ───────────────────────────────────────────────────────────────────────────
  Future<Survey> getSurveyByPost(String postId) async {
    final headers = await _getOptionalHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/social/surveys/by-post/$postId'),
      headers: headers,
    );
    final body = _decodeOrThrow(res);
    return Survey.fromJson(body['survey'] as Map<String, dynamic>);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RESPOND — submit answers. Returns { rewarded, coinsAwarded }.
  // `answers` is a list of { questionId, optionIds?, scaleValue?, textValue? }.
  // ───────────────────────────────────────────────────────────────────────────
  Future<({bool rewarded, int coinsAwarded})> submitResponse({
    required String surveyId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/social/surveys/$surveyId/respond'),
      headers: headers,
      body: jsonEncode({'answers': answers}),
    );
    final body = _decodeOrThrow(res);
    return (
    rewarded: (body['rewarded'] ?? false) as bool,
    coinsAwarded: (body['coinsAwarded'] ?? 0) as int,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // RESULTS — may throw SurveyApiException(code: 'RESULTS_LOCKED') if the
  // viewer isn't allowed to see them yet; the UI uses that to show the right
  // "results unlock after you vote / after it closes" message.
  // ───────────────────────────────────────────────────────────────────────────
  Future<SurveyResults> getResults(String surveyId) async {
    final headers = await _getOptionalHeaders();
    final res = await http.get(
      Uri.parse('$baseUrl/social/surveys/$surveyId/results'),
      headers: headers,
    );
    final body = _decodeOrThrow(res);
    return SurveyResults.fromJson(body);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CLOSE — author ends the survey; returns coins refunded (unspent budget).
  // ───────────────────────────────────────────────────────────────────────────
  Future<int> closeSurvey(String surveyId) async {
    final headers = await _getHeaders();
    final res = await http.post(
      Uri.parse('$baseUrl/social/surveys/$surveyId/close'),
      headers: headers,
    );
    final body = _decodeOrThrow(res);
    return (body['refunded'] ?? 0) as int;
  }
}