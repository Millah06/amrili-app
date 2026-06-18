// =============================================================================
// lib/features/social/widgets/survey_results_view.dart
// -----------------------------------------------------------------------------
// PHASE 11 — SURVEY RESULTS & INSIGHTS (pure presentation)
// =============================================================================
//
// Given a `SurveyResults` (already fetched), render it. This widget holds NO
// state and makes NO network calls — it just draws. That separation keeps it
// trivial to reason about: the card decides WHEN to show results; this decides
// HOW they look.
//
// Each question type renders differently:
//   choice     → horizontal percentage bars (the classic poll result).
//   scale/nps  → a distribution of mini-bars + the average; nps also shows the
//                headline NPS score.
//   short_text → a stack of quoted answers.
//
// Then the "insight" breakdowns that make this a research tool, not a toy:
//   by country, and by follower vs non-follower — identity-free aggregates.
//
// All colours/fonts are VendorTheme so results look native to the feed card.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';
import '../models/survey_model.dart';

class SurveyResultsView extends StatelessWidget {
  final SurveyResults results;
  const SurveyResultsView({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // response count header
        Text(
          '${results.responseCount} ${results.responseCount == 1 ? "response" : "responses"}',
          style: GoogleFonts.inter(
              color: VendorTheme.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        // one block per question
        for (final q in results.questions) ...[
          _QuestionResult(q: q),
          const SizedBox(height: 16),
        ],

        // insight breakdowns
        if (results.byCountry.isNotEmpty || results.byFollower.isNotEmpty) ...[
          const Divider(color: VendorTheme.surfaceVariant, height: 1),
          const SizedBox(height: 12),
          Text('Who answered',
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (results.byFollower.isNotEmpty)
            _MiniBreakdown(title: 'Audience', rows: results.byFollower),
          if (results.byCountry.isNotEmpty) ...[
            const SizedBox(height: 10),
            _MiniBreakdown(
              title: 'Top countries',
              rows: _topN(results.byCountry, 5),
            ),
          ],
        ],
      ],
    );
  }

  // sort a breakdown desc and take N (results come unsorted)
  List<BreakdownRow> _topN(List<BreakdownRow> rows, int n) {
    final copy = [...rows]..sort((a, b) => b.count.compareTo(a.count));
    return copy.take(n).toList();
  }
}

// ─── one question's results ───────────────────────────────────────────────────

class _QuestionResult extends StatelessWidget {
  final SurveyResultQuestion q;
  const _QuestionResult({required this.q});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q.prompt,
            style: GoogleFonts.inter(
                color: VendorTheme.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        switch (q.type) {
          SurveyQuestionType.singleChoice ||
          SurveyQuestionType.multiChoice =>
              _choiceResult(),
          SurveyQuestionType.scale => _scaleResult(),
          SurveyQuestionType.nps => _npsResult(),
          SurveyQuestionType.shortText => _textResult(),
        },
      ],
    );
  }

  // choice → percentage bars
  Widget _choiceResult() {
    return Column(
      children: q.options.map((o) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PercentBar(
            label: o.label,
            percent: o.percent,
            trailing: '${o.percent.toStringAsFixed(o.percent % 1 == 0 ? 0 : 1)}%',
            sub: '${o.votes}',
          ),
        );
      }).toList(),
    );
  }

  // scale → distribution bars + average
  Widget _scaleResult() {
    final maxCount =
    q.distribution.fold<int>(1, (m, b) => b.count > m ? b.count : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Average ${q.average.toStringAsFixed(1)} · ${q.count} answers',
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        // vertical mini-bars, one per value
        SizedBox(
          height: 64,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: q.distribution.map((b) {
              final h = 8 + (b.count / maxCount) * 40;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xFF177E85), VendorTheme.primary],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${b.value}',
                          style: GoogleFonts.inter(
                              color: VendorTheme.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // nps → big score + same distribution
  Widget _npsResult() {
    final nps = q.npsScore ?? 0;
    // NPS ranges −100..100; colour it by the usual rough bands.
    final color = nps >= 50
        ? VendorTheme.accent
        : nps >= 0
        ? VendorTheme.primary
        : VendorTheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$nps',
                style: GoogleFonts.poppins(
                    color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('NPS',
                style: GoogleFonts.inter(
                    color: VendorTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text('· ${q.count} answers',
                style: GoogleFonts.inter(
                    color: VendorTheme.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        _scaleResult(),
      ],
    );
  }

  // short_text → quoted answers
  Widget _textResult() {
    if (q.answers.isEmpty) {
      return Text('No answers yet',
          style:
          GoogleFonts.inter(color: VendorTheme.textMuted, fontSize: 12));
    }
    return Column(
      children: q.answers.take(20).map((a) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: VendorTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: VendorTheme.primary.withOpacity(0.5), width: 3),
            ),
          ),
          child: Text(a,
              style: GoogleFonts.inter(
                  color: VendorTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.35)),
        );
      }).toList(),
    );
  }
}

// ─── reusable: a labelled percentage bar ──────────────────────────────────────

class _PercentBar extends StatelessWidget {
  final String label;
  final double percent; // 0..100
  final String trailing;
  final String sub;

  const _PercentBar({
    required this.label,
    required this.percent,
    required this.trailing,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: VendorTheme.textPrimary, fontSize: 12.5)),
            ),
            Text(trailing,
                style: GoogleFonts.inter(
                    color: VendorTheme.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
        // the bar: a full-width track with a cyan→teal fill animating to width.
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 8, color: VendorTheme.background),
              FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF177E85), VendorTheme.primary],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── reusable: a small breakdown block (count bars) ──────────────────────────

class _MiniBreakdown extends StatelessWidget {
  final String title;
  final List<BreakdownRow> rows;
  const _MiniBreakdown({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final max = rows.fold<int>(1, (m, r) => r.count > m ? r.count : m);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.inter(
                color: VendorTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(r.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          color: VendorTheme.textSecondary, fontSize: 12)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Stack(
                      children: [
                        Container(height: 7, color: VendorTheme.background),
                        FractionallySizedBox(
                          widthFactor: (r.count / max).clamp(0.05, 1.0),
                          child: Container(
                              height: 7, color: VendorTheme.primary.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${r.count}',
                    style: GoogleFonts.inter(
                        color: VendorTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }
}