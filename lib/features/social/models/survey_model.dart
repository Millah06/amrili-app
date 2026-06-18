// =============================================================================
// lib/features/social/models/survey_model.dart
// -----------------------------------------------------------------------------
// PHASE 11 — SURVEY MODELS (Flutter side)
// =============================================================================
//
// These Dart classes mirror EXACTLY what the survey backend returns. Keeping the
// field names aligned with the JSON the controllers send (see surveyController.ts
// `shapeSurvey` and `getResults`) is what makes parsing trivial and bug-free.
//
// There are two families of model here:
//   1. The SURVEY itself (what you render to vote on): Survey → SurveyQuestion →
//      SurveyOption.
//   2. The RESULTS (what you render after voting / when results unlock):
//      SurveyResults → SurveyResultQuestion (shape varies by question type).
//
// WHY AN ENUM FOR THE QUESTION TYPE
// ---------------------------------
// The backend sends the type as a string ("single_choice", "scale", ...). On the
// client we convert it to a Dart enum the moment we parse, so the rest of the UI
// can `switch` on a type-safe value instead of string-matching everywhere. The
// `toApi()` / `fromApi()` pair is the single translation point.
// =============================================================================

// ─── Question type ────────────────────────────────────────────────────────────

enum SurveyQuestionType {
  singleChoice, // pick exactly one option
  multiChoice, // pick one or more options
  scale, // Likert 1..N slider/segments
  shortText, // free text answer
  nps; // 0..10 "how likely to recommend" (special scale)

  /// The exact string the backend uses (must match the Prisma enum).
  String toApi() {
    switch (this) {
      case SurveyQuestionType.singleChoice:
        return 'single_choice';
      case SurveyQuestionType.multiChoice:
        return 'multi_choice';
      case SurveyQuestionType.scale:
        return 'scale';
      case SurveyQuestionType.shortText:
        return 'short_text';
      case SurveyQuestionType.nps:
        return 'nps';
    }
  }

  static SurveyQuestionType fromApi(String? raw) {
    switch (raw) {
      case 'single_choice':
        return SurveyQuestionType.singleChoice;
      case 'multi_choice':
        return SurveyQuestionType.multiChoice;
      case 'scale':
        return SurveyQuestionType.scale;
      case 'short_text':
        return SurveyQuestionType.shortText;
      case 'nps':
        return SurveyQuestionType.nps;
      default:
        return SurveyQuestionType.singleChoice;
    }
  }

  /// Human label for the builder UI.
  String get label {
    switch (this) {
      case SurveyQuestionType.singleChoice:
        return 'Single choice';
      case SurveyQuestionType.multiChoice:
        return 'Multiple choice';
      case SurveyQuestionType.scale:
        return 'Rating scale';
      case SurveyQuestionType.shortText:
        return 'Short answer';
      case SurveyQuestionType.nps:
        return 'Recommend (0–10)';
    }
  }

  bool get isChoice =>
      this == SurveyQuestionType.singleChoice ||
          this == SurveyQuestionType.multiChoice;
  bool get isScaleLike =>
      this == SurveyQuestionType.scale || this == SurveyQuestionType.nps;
}

// ─── Audience / visibility (string-backed; small enough to keep as helpers) ───

class SurveyAudience {
  static const everyone = 'everyone';
  static const followers = 'followers';
  static const ngOnly = 'ng_only';

  static String label(String v) {
    switch (v) {
      case followers:
        return 'My followers only';
      case ngOnly:
        return 'Nigeria only';
      default:
        return 'Everyone';
    }
  }

  static const all = [everyone, followers, ngOnly];
}

class SurveyResultVisibility {
  static const afterVote = 'after_vote';
  static const afterClose = 'after_close';
  static const authorOnly = 'author_only';
  static const always = 'always';

  static String label(String v) {
    switch (v) {
      case afterClose:
        return 'After the survey closes';
      case authorOnly:
        return 'Only me (the author)';
      case always:
        return 'Always visible';
      default:
        return 'After they vote';
    }
  }

  static const all = [afterVote, afterClose, authorOnly, always];
}

// ─── SurveyOption ─────────────────────────────────────────────────────────────

class SurveyOption {
  final String optionId;
  final String label;

  /// Vote count is ONLY present when the viewer is allowed to see results
  /// (the backend strips it otherwise), so it is nullable.
  final int? votes;

  const SurveyOption({required this.optionId, required this.label, this.votes});

  factory SurveyOption.fromJson(Map<String, dynamic> j) => SurveyOption(
    optionId: j['optionId'] ?? '',
    label: j['label'] ?? '',
    votes: j['votes'], // null when results are hidden
  );
}

// ─── SurveyQuestion ───────────────────────────────────────────────────────────

class SurveyQuestion {
  final String questionId;
  final SurveyQuestionType type;
  final String prompt;
  final bool required;

  // scale / nps config (null for choice & text)
  final int? scaleMin;
  final int? scaleMax;
  final String? scaleMinLabel;
  final String? scaleMaxLabel;

  final List<SurveyOption> options;

  const SurveyQuestion({
    required this.questionId,
    required this.type,
    required this.prompt,
    this.required = true,
    this.scaleMin,
    this.scaleMax,
    this.scaleMinLabel,
    this.scaleMaxLabel,
    this.options = const [],
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> j) => SurveyQuestion(
    questionId: j['questionId'] ?? '',
    type: SurveyQuestionType.fromApi(j['type']),
    prompt: j['prompt'] ?? '',
    required: j['required'] ?? true,
    scaleMin: j['scaleMin'],
    scaleMax: j['scaleMax'],
    scaleMinLabel: j['scaleMinLabel'],
    scaleMaxLabel: j['scaleMaxLabel'],
    options: (j['options'] as List<dynamic>? ?? [])
        .map((o) => SurveyOption.fromJson(o))
        .toList(),
  );
}

// ─── Survey (the thing you render to vote on) ─────────────────────────────────

class Survey {
  final String surveyId;
  final String postId;
  final String authorId;
  final String title;
  final String description;
  final bool anonymous;
  final String audience;
  final String resultVisibility;
  final DateTime? closesAt;
  final bool isClosed;
  final bool isOver; // closed OR past closesAt
  final int responseCount;
  final int rewardCoins;
  final int rewardBudgetRemaining;

  // viewer-specific state (from the backend, per request)
  final bool isAuthor;
  final bool canRespond;
  final bool canSeeResults;
  final bool hasResponded;

  final List<SurveyQuestion> questions;

  const Survey({
    required this.surveyId,
    required this.postId,
    required this.authorId,
    required this.title,
    required this.description,
    required this.anonymous,
    required this.audience,
    required this.resultVisibility,
    required this.closesAt,
    required this.isClosed,
    required this.isOver,
    required this.responseCount,
    required this.rewardCoins,
    required this.rewardBudgetRemaining,
    required this.isAuthor,
    required this.canRespond,
    required this.canSeeResults,
    required this.hasResponded,
    required this.questions,
  });

  /// Does answering this survey pay coins (and is there budget left)?
  bool get paysReward => rewardCoins > 0 && rewardBudgetRemaining >= rewardCoins;

  factory Survey.fromJson(Map<String, dynamic> j) {
    final closesMs = j['closesAt'];
    return Survey(
      surveyId: j['surveyId'] ?? '',
      postId: j['postId'] ?? '',
      authorId: j['authorId'] ?? '',
      title: j['title'] ?? '',
      description: j['description'] ?? '',
      anonymous: j['anonymous'] ?? true,
      audience: j['audience'] ?? SurveyAudience.everyone,
      resultVisibility:
      j['resultVisibility'] ?? SurveyResultVisibility.afterVote,
      closesAt: closesMs is int
          ? DateTime.fromMillisecondsSinceEpoch(closesMs)
          : null,
      isClosed: j['isClosed'] ?? false,
      isOver: j['isOver'] ?? false,
      responseCount: j['responseCount'] ?? 0,
      rewardCoins: j['rewardCoins'] ?? 0,
      rewardBudgetRemaining: j['rewardBudgetRemaining'] ?? 0,
      isAuthor: j['isAuthor'] ?? false,
      canRespond: j['canRespond'] ?? false,
      canSeeResults: j['canSeeResults'] ?? false,
      hasResponded: j['hasResponded'] ?? false,
      questions: (j['questions'] as List<dynamic>? ?? [])
          .map((q) => SurveyQuestion.fromJson(q))
          .toList(),
    );
  }
}

// =============================================================================
// RESULTS MODELS (the insight payload — shape varies per question type)
// =============================================================================

/// One choice option's tally in the results view.
class ResultOption {
  final String optionId;
  final String label;
  final int votes;
  final double percent; // 0..100, one decimal

  const ResultOption({
    required this.optionId,
    required this.label,
    required this.votes,
    required this.percent,
  });

  factory ResultOption.fromJson(Map<String, dynamic> j) => ResultOption(
    optionId: j['optionId'] ?? '',
    label: j['label'] ?? '',
    votes: j['votes'] ?? 0,
    percent: (j['percent'] ?? 0).toDouble(),
  );
}

/// One value-bucket in a scale/nps distribution chart.
class ResultBucket {
  final int value;
  final int count;
  const ResultBucket({required this.value, required this.count});
  factory ResultBucket.fromJson(Map<String, dynamic> j) =>
      ResultBucket(value: j['value'] ?? 0, count: j['count'] ?? 0);
}

/// A single question's results. Only the fields relevant to its `type` are set.
class SurveyResultQuestion {
  final String questionId;
  final SurveyQuestionType type;
  final String prompt;

  // choice
  final int totalVotes;
  final List<ResultOption> options;

  // scale / nps
  final int count;
  final double average;
  final List<ResultBucket> distribution;
  final int? npsScore; // only for nps

  // short_text
  final List<String> answers;

  const SurveyResultQuestion({
    required this.questionId,
    required this.type,
    required this.prompt,
    this.totalVotes = 0,
    this.options = const [],
    this.count = 0,
    this.average = 0,
    this.distribution = const [],
    this.npsScore,
    this.answers = const [],
  });

  factory SurveyResultQuestion.fromJson(Map<String, dynamic> j) =>
      SurveyResultQuestion(
        questionId: j['questionId'] ?? '',
        type: SurveyQuestionType.fromApi(j['type']),
        prompt: j['prompt'] ?? '',
        totalVotes: j['totalVotes'] ?? 0,
        options: (j['options'] as List<dynamic>? ?? [])
            .map((o) => ResultOption.fromJson(o))
            .toList(),
        count: j['count'] ?? 0,
        average: (j['average'] ?? 0).toDouble(),
        distribution: (j['distribution'] as List<dynamic>? ?? [])
            .map((d) => ResultBucket.fromJson(d))
            .toList(),
        npsScore: j['npsScore'],
        answers: (j['answers'] as List<dynamic>? ?? [])
            .map((a) => a.toString())
            .toList(),
      );
}

/// A breakdown row (country or follower-status), identity-free by design.
class BreakdownRow {
  final String label;
  final int count;
  const BreakdownRow({required this.label, required this.count});
}

class SurveyResults {
  final String surveyId;
  final String title;
  final int responseCount;
  final bool isClosed;
  final List<SurveyResultQuestion> questions;
  final List<BreakdownRow> byCountry;
  final List<BreakdownRow> byFollower;

  const SurveyResults({
    required this.surveyId,
    required this.title,
    required this.responseCount,
    required this.isClosed,
    required this.questions,
    required this.byCountry,
    required this.byFollower,
  });

  factory SurveyResults.fromJson(Map<String, dynamic> j) {
    final breakdowns = (j['breakdowns'] as Map<String, dynamic>? ?? {});
    return SurveyResults(
      surveyId: j['surveyId'] ?? '',
      title: j['title'] ?? '',
      responseCount: j['responseCount'] ?? 0,
      isClosed: j['isClosed'] ?? false,
      questions: (j['questions'] as List<dynamic>? ?? [])
          .map((q) => SurveyResultQuestion.fromJson(q))
          .toList(),
      byCountry: (breakdowns['byCountry'] as List<dynamic>? ?? [])
          .map((r) => BreakdownRow(
          label: r['country'] ?? 'Unknown', count: r['count'] ?? 0))
          .toList(),
      byFollower: (breakdowns['byFollower'] as List<dynamic>? ?? [])
          .map((r) => BreakdownRow(
          label: (r['follower'] == true) ? 'Followers' : 'Non-followers',
          count: r['count'] ?? 0))
          .toList(),
    );
  }
}