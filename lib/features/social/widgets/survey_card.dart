// =============================================================================
// lib/features/social/widgets/survey_card.dart  (v2)
// -----------------------------------------------------------------------------
// PHASE 11 — IN-FEED SURVEY CARD (embedded + cached)
// =============================================================================
//
// WHAT CHANGED vs v1 (and WHY) — this fixes three real UX bugs:
//
//   #1  NO WATERFALL: the survey now arrives INSIDE the feed post
//       (`post.survey`, embedded by the backend `attachSurveys`). So the card
//       renders the moment the post renders — no skeleton, no second wait. We
//       only ever hit the network as a FALLBACK (an endpoint that hasn't been
//       updated to embed yet), or to fetch RESULTS once.
//
//   #2  NO REFETCH ON SCROLL: a feed is a recycling list — scrolling away and
//       back rebuilds this widget and re-runs initState. v1 re-fetched every
//       time. v2 reads from `SurveyCache` (a tiny session-lived store), so a
//       card you've already seen/voted on shows instantly with zero network.
//
//   #4  TIGHTER PADDING: the inset panel now spans almost the full post width
//       (horizontal margin 2 instead of 16) so it doesn't look cramped.
//
// THE CACHE
// ---------
// SurveyCache is an in-memory singleton (lives for the app session). It stores:
//   - surveys  : latest known Survey per surveyId (seeded from the embed)
//   - results  : fetched SurveyResults per surveyId (so we fetch results once)
//   - voted    : surveyIds the user has answered THIS session
// It does not persist across restarts (the feed re-embeds fresh state on next
// load); it just stops the wasteful refetch while scrolling.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../core/auth/guest_helper.dart';
import '../models/post_model.dart';
import '../models/survey_model.dart';
import '../services/survey_api_service.dart';
import 'survey_results_view.dart';
import 'survey_share_card.dart';

/// Session-lived cache (see header). Plain singleton — read on every card build.
class SurveyCache {
  SurveyCache._();
  static final SurveyCache I = SurveyCache._();

  final Map<String, Survey> surveys = {};
  final Map<String, SurveyResults> results = {};
  final Set<String> voted = {};

  void seed(Survey s) => surveys[s.surveyId] = s;
  bool hasVoted(Survey s) => voted.contains(s.surveyId) || s.hasResponded;
}

class SurveyCard extends StatefulWidget {
  final Post post;
  const SurveyCard({super.key, required this.post});

  @override
  State<SurveyCard> createState() => _SurveyCardState();
}

enum _View { loading, error, voting, results, locked, blocked }

class _SurveyCardState extends State<SurveyCard> {
  final _api = SurveyApiService();

  _View _view = _View.loading;
  Survey? _survey;
  SurveyResults? _results;
  bool _submitting = false;
  bool _closing = false;

  final Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ── resolve the survey WITHOUT a network call when possible ─────────────────
  void _init() {
    // 1) Prefer the survey embedded in the feed post (the common path -> instant).
    final embedded = widget.post.survey;
    if (embedded != null) {
      SurveyCache.I.seed(embedded);
      _survey = SurveyCache.I.surveys[embedded.surveyId] ?? embedded;
      _decideView();
      return;
    }
    // 2) Fallback: no embed (an endpoint not yet updated). Fetch once by postId.
    _fetchByPost();
  }

  Future<void> _fetchByPost() async {
    setState(() => _view = _View.loading);
    try {
      final s = await _api.getSurveyByPost(widget.post.postId);
      SurveyCache.I.seed(s);
      _survey = s;
      _decideView();
    } catch (_) {
      if (mounted) setState(() => _view = _View.error);
    }
  }

  // ── choose the sub-view from local + cached state (network only for results) ─
  void _decideView() {
    final s = _survey!;
    final voted = SurveyCache.I.hasVoted(s);

    // 1) Results take priority (voted / public / author).
    if (voted || s.canSeeResults || s.isAuthor) {
      final cached = SurveyCache.I.results[s.surveyId];
      if (cached != null) {
        setState(() {
          _results = cached;
          _view = _View.results;
        });
      } else {
        _loadResults();
      }
      return;
    }

    // 2) Open + answerable → vote. We show the questions when the backend says
    //    canRespond, OR when the audience is "everyone" — the latter lets GUESTS
    //    (and not-yet-evaluated viewers) see the questions and be enticed; the
    //    actual submit is gated by GuestHelper, which prompts sign-in.
    if (!s.isOver &&
        (s.canRespond || s.audience == SurveyAudience.everyone)) {
      setState(() => _view = _View.voting);
      return;
    }

    // 3) Open but audience-restricted (followers / Nigeria only) and not allowed
    //    → an explicit blocked note (not a generic "locked").
    if (!s.isOver && s.audience != SurveyAudience.everyone) {
      setState(() => _view = _View.blocked);
      return;
    }

    // 4) Otherwise (closed, results not visible to this viewer) → locked note.
    setState(() => _view = _View.locked);
  }

  Future<void> _loadResults() async {
    setState(() => _view = _View.loading);
    try {
      final r = await _api.getResults(_survey!.surveyId);
      if (!mounted) return;
      SurveyCache.I.results[_survey!.surveyId] = r;
      setState(() {
        _results = r;
        _view = _View.results;
      });
    } on SurveyApiException catch (e) {
      if (!mounted) return;
      setState(() =>
      _view = e.code == 'RESULTS_LOCKED' ? _View.locked : _View.error);
    } catch (_) {
      if (mounted) setState(() => _view = _View.error);
    }
  }

  // ── submit ──────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final s = _survey!;
    for (final q in s.questions) {
      if (!q.required) continue;
      if (!_isAnswered(q)) {
        _snack('Please answer: "${q.prompt}"', isError: true);
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final res = await _api.submitResponse(
        surveyId: s.surveyId,
        answers: _buildAnswers(s),
      );
      if (!mounted) return;
      _snack(
        res.rewarded
            ? 'Thanks! You earned ${res.coinsAwarded} coins'
            : 'Thanks for answering',
        isError: false,
      );
      SurveyCache.I.voted.add(s.surveyId);
      SurveyCache.I.results.remove(s.surveyId); // fresh tally incl. ours
      await _loadResults();
    } on SurveyApiException catch (e) {
      if (!mounted) return;
      _snack(e.message, isError: true);
      if (e.statusCode == 409) {
        SurveyCache.I.voted.add(s.surveyId);
        await _loadResults();
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Could not submit. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _isAnswered(SurveyQuestion q) {
    final a = _answers[q.questionId];
    if (q.type == SurveyQuestionType.multiChoice) return a is Set && a.isNotEmpty;
    if (q.type == SurveyQuestionType.shortText) {
      return a is String && a.trim().isNotEmpty;
    }
    return a != null;
  }

  List<Map<String, dynamic>> _buildAnswers(Survey s) {
    final out = <Map<String, dynamic>>[];
    for (final q in s.questions) {
      if (!_isAnswered(q)) continue;
      final a = _answers[q.questionId];
      switch (q.type) {
        case SurveyQuestionType.singleChoice:
          out.add({'questionId': q.questionId, 'optionIds': [a as String]});
          break;
        case SurveyQuestionType.multiChoice:
          out.add({
            'questionId': q.questionId,
            'optionIds': (a as Set).cast<String>().toList(),
          });
          break;
        case SurveyQuestionType.scale:
        case SurveyQuestionType.nps:
          out.add({'questionId': q.questionId, 'scaleValue': a as int});
          break;
        case SurveyQuestionType.shortText:
          out.add(
              {'questionId': q.questionId, 'textValue': (a as String).trim()});
          break;
      }
    }
    return out;
  }

  // ── author: close ─────────────────────────────────────────────────────────--
  Future<void> _close() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VendorTheme.surface,
        title: Text('Close survey?',
            style: GoogleFonts.poppins(color: VendorTheme.textPrimary)),
        content: Text(
          'No new responses will be accepted. Any unused reward coins are '
              'refunded to you.',
          style: GoogleFonts.inter(color: VendorTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: VendorTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Close survey',
                style: GoogleFonts.inter(
                    color: VendorTheme.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _closing = true);
    try {
      final refunded = await _api.closeSurvey(_survey!.surveyId);
      if (!mounted) return;
      _snack(
        refunded > 0 ? 'Survey closed · $refunded coins refunded' : 'Survey closed',
        isError: false,
      );
      SurveyCache.I.results.remove(_survey!.surveyId);
      await _loadResults();
    } catch (_) {
      if (!mounted) return;
      _snack('Could not close the survey.', isError: true);
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  // ── build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      // #4: near-full width (was fromLTRB(16,4,16,12) -> felt cramped).
      margin: const EdgeInsets.fromLTRB(2, 4, 2, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.primary.withOpacity(0.20)),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    switch (_view) {
      case _View.loading:
        return _skeleton();
      case _View.error:
        return _errorRow();
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 12),
            if (_view == _View.voting) _votingBody(),
            if (_view == _View.results && _results != null) ...[
              SurveyResultsView(results: _results!),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      showSurveyShareSheet(context, _survey!, _results!),
                  icon: const Icon(Icons.ios_share,
                      size: 16, color: VendorTheme.primary),
                  label: Text('Share results',
                      style: GoogleFonts.inter(
                          color: VendorTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            if (_view == _View.locked) _lockedNote(),
            if (_view == _View.blocked) _blockedNote(),
            if (_survey!.isAuthor) _authorBar(),
          ],
        );
    }
  }

  Widget _header() {
    final s = _survey!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _pill('Survey', VendorTheme.primary, Icons.insights_rounded),
            if (s.paysReward) ...[
              const SizedBox(width: 8),
              _pill('Earn ${s.rewardCoins}', VendorTheme.gold,
                  Icons.stars_rounded),
            ],
            const Spacer(),
            if (s.isOver)
              Text('Closed',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
          ],
        ),
        if (s.title.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(s.title,
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.3)),
        ],
      ],
    );
  }

  Widget _votingBody() {
    final s = _survey!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final q in s.questions) ...[
          _QuestionVote(
            question: q,
            answer: _answers[q.questionId],
            onChanged: (v) => setState(() => _answers[q.questionId] = v),
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting
                ? null
                : () => GuestHelper.guardAction(context,
                action: _submit, reason: 'answer surveys'),
            style: ElevatedButton.styleFrom(
              backgroundColor: VendorTheme.primary,
              foregroundColor: VendorTheme.background,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: VendorTheme.background),
            )
                : Text(
                s.paysReward
                    ? 'Submit & earn ${s.rewardCoins} coins'
                    : 'Submit',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ),
        if (s.anonymous) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.lock_outline,
                  size: 13, color: VendorTheme.textMuted),
              const SizedBox(width: 5),
              Text('Anonymous — the author sees totals only',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _authorBar() {
    final s = _survey!;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text('${s.responseCount} responses',
              style: GoogleFonts.inter(
                  color: VendorTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const Spacer(),
          if (!s.isOver)
            TextButton(
              onPressed: _closing ? null : _close,
              child: _closing
                  ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VendorTheme.error))
                  : Text('Close survey',
                  style: GoogleFonts.inter(
                      color: VendorTheme.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5)),
            ),
        ],
      ),
    );
  }

  Widget _lockedNote() {
    final s = _survey!;
    final msg = s.resultVisibility == SurveyResultVisibility.afterClose
        ? 'Results unlock when the survey closes.'
        : s.resultVisibility == SurveyResultVisibility.authorOnly
        ? 'Only the author can see these results.'
        : 'Results unlock after you answer.';
    return _noteRow(Icons.lock_outline, msg);
  }

  Widget _blockedNote() {
    final s = _survey!;
    final msg = s.audience == SurveyAudience.followers
        ? 'Only the author\'s followers can answer this survey.'
        : s.audience == SurveyAudience.ngOnly
        ? 'This survey is for Nigeria-based users.'
        : 'You can\'t answer this survey.';
    return _noteRow(Icons.info_outline, msg);
  }

  Widget _noteRow(IconData icon, String msg) => Row(
    children: [
      Icon(icon, size: 16, color: VendorTheme.textMuted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(msg,
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 12.5)),
      ),
    ],
  );

  Widget _errorRow() => Row(
    children: [
      const Icon(Icons.cloud_off, size: 18, color: VendorTheme.textMuted),
      const SizedBox(width: 8),
      Text('Couldn\'t load survey',
          style: GoogleFonts.inter(
              color: VendorTheme.textSecondary, fontSize: 13)),
      const Spacer(),
      TextButton(
        onPressed: _fetchByPost,
        child: Text('Retry',
            style: GoogleFonts.inter(
                color: VendorTheme.primary, fontWeight: FontWeight.w600)),
      ),
    ],
  );

  Widget _skeleton() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _bar(90, 14),
      const SizedBox(height: 10),
      _bar(double.infinity, 36),
      const SizedBox(height: 8),
      _bar(double.infinity, 36),
    ],
  );

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: VendorTheme.surfaceVariant.withOpacity(0.4),
      borderRadius: BorderRadius.circular(8),
    ),
  );

  Widget _pill(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(text,
            style: GoogleFonts.inter(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      ],
    ),
  );

  void _snack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? VendorTheme.error : VendorTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// =============================================================================
// _QuestionVote — the input control for ONE question, by type
// =============================================================================
class _QuestionVote extends StatelessWidget {
  final SurveyQuestion question;
  final dynamic answer;
  final ValueChanged<dynamic> onChanged;

  const _QuestionVote({
    required this.question,
    required this.answer,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: question.prompt,
            style: GoogleFonts.inter(
                color: VendorTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600),
            children: [
              if (!question.required)
                TextSpan(
                  text: '  optional',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w400),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        switch (question.type) {
          SurveyQuestionType.singleChoice => _single(),
          SurveyQuestionType.multiChoice => _multi(),
          SurveyQuestionType.scale => _scale(),
          SurveyQuestionType.nps => _scale(npsFull: true),
          SurveyQuestionType.shortText => _text(),
        },
      ],
    );
  }

  Widget _single() {
    return Column(
      children: question.options.map((o) {
        final selected = answer == o.optionId;
        return _optionRow(
          label: o.label,
          selected: selected,
          isRadio: true,
          onTap: () => onChanged(o.optionId),
        );
      }).toList(),
    );
  }

  Widget _multi() {
    final set = (answer is Set) ? (answer as Set).cast<String>() : <String>{};
    return Column(
      children: question.options.map((o) {
        final selected = set.contains(o.optionId);
        return _optionRow(
          label: o.label,
          selected: selected,
          isRadio: false,
          onTap: () {
            final next = {...set};
            selected ? next.remove(o.optionId) : next.add(o.optionId);
            onChanged(next);
          },
        );
      }).toList(),
    );
  }

  Widget _optionRow({
    required String label,
    required bool selected,
    required bool isRadio,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? VendorTheme.primary.withOpacity(0.12)
              : VendorTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? VendorTheme.primary : VendorTheme.surfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isRadio
                  ? (selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off)
                  : (selected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank),
              size: 19,
              color: selected ? VendorTheme.primary : VendorTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: VendorTheme.textPrimary, fontSize: 13.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scale({bool npsFull = false}) {
    final min = npsFull ? 0 : (question.scaleMin ?? 1);
    final max = npsFull ? 10 : (question.scaleMax ?? 5);
    final selected = answer is int ? answer as int : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (int v = min; v <= max; v++)
              GestureDetector(
                onTap: () => onChanged(v),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == v
                        ? VendorTheme.primary
                        : VendorTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected == v
                          ? VendorTheme.primary
                          : VendorTheme.surfaceVariant,
                    ),
                  ),
                  child: Text('$v',
                      style: GoogleFonts.poppins(
                          color: selected == v
                              ? VendorTheme.background
                              : VendorTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
          ],
        ),
        if ((question.scaleMinLabel ?? '').isNotEmpty ||
            (question.scaleMaxLabel ?? '').isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(question.scaleMinLabel ?? '',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted, fontSize: 11)),
              Text(question.scaleMaxLabel ?? '',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _text() {
    return TextField(
      onChanged: onChanged,
      maxLines: 3,
      maxLength: 2000,
      style: GoogleFonts.inter(color: VendorTheme.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'Type your answer…',
        hintStyle:
        GoogleFonts.inter(color: VendorTheme.textMuted, fontSize: 13),
        counterText: '',
        filled: true,
        fillColor: VendorTheme.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: VendorTheme.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: VendorTheme.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: VendorTheme.primary),
        ),
      ),
    );
  }
}