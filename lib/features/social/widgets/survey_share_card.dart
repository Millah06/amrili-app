// =============================================================================
// lib/features/social/widgets/survey_share_card.dart
// -----------------------------------------------------------------------------
// PHASE 11 — SHAREABLE SURVEY RESULT CARD (the virality loop)
// =============================================================================
//
// People share RESULTS, and every shared result is an ad for the survey. This
// file builds a polished branded card from a survey's results, renders it to a
// PNG, and shares it (with the post deep link) via the OS share sheet.
//
// HOW THE CAPTURE WORKS (the one non-obvious bit)
// -----------------------------------------------
// Flutter can rasterise any widget that's wrapped in a `RepaintBoundary`:
//   1. wrap the card in RepaintBoundary with a GlobalKey,
//   2. `boundary.toImage(pixelRatio: 3)` → a high-res ui.Image,
//   3. encode to PNG bytes, write to a temp file,
//   4. hand that file to the share sheet.
// We render the card on-screen (in a bottom sheet) so it's laid out and painted
// before we capture — capturing an off-screen widget is fiddly and error-prone.
//
// USAGE
//   showSurveyShareSheet(context, survey, results);
// (survey_card calls this from a "Share results" button when results are shown.)
// =============================================================================

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constraints/vendor_theme.dart';
import '../models/survey_model.dart';

/// Opens a bottom sheet previewing the share card with a Share button.
Future<void> showSurveyShareSheet(
    BuildContext context,
    Survey survey,
    SurveyResults results,
    ) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SurveyShareSheet(survey: survey, results: results),
  );
}

class _SurveyShareSheet extends StatefulWidget {
  final Survey survey;
  final SurveyResults results;
  const _SurveyShareSheet({required this.survey, required this.results});

  @override
  State<_SurveyShareSheet> createState() => _SurveyShareSheetState();
}

class _SurveyShareSheetState extends State<_SurveyShareSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      // 1) rasterise the RepaintBoundary that wraps the card.
      final boundary = _cardKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? bytes =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw Exception('encode failed');

      // 2) write to a temp file.
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/amril_survey_${widget.survey.surveyId}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      // 3) share image + deep link to the survey post.
      final link = 'https://amril.app/post/${widget.survey.postId}';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'What do you think? Answer my survey on Amril 👇\n$link',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Couldn\'t share. Try again.',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: VendorTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [VendorTheme.surface, VendorTheme.background],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),
          // The actual card to capture, wrapped in a RepaintBoundary.
          RepaintBoundary(
            key: _cardKey,
            child: SurveyShareCard(
              survey: widget.survey,
              results: widget.results,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sharing ? null : _share,
              icon: _sharing
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VendorTheme.background))
                  : const Icon(Icons.ios_share, size: 18),
              label: Text('Share',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorTheme.primary,
                foregroundColor: VendorTheme.background,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The branded card itself (pure visual — no state, no network). Designed at a
/// fixed width so the rasterised PNG is crisp and consistently composed.
class SurveyShareCard extends StatelessWidget {
  final Survey survey;
  final SurveyResults results;
  const SurveyShareCard({super.key, required this.survey, required this.results});

  @override
  Widget build(BuildContext context) {
    // Pick a headline: the first CHOICE question's leading option (the most
    // "shareable" stat). Fall back to the title + response count if none.
    final headline = _headline();

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VendorTheme.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header band (cyan → teal) ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [VendorTheme.primary, Color(0xFF177E85)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('SURVEY RESULTS',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
                const Spacer(),
                Text('Amril',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title
                Text(survey.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        color: VendorTheme.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
                const SizedBox(height: 4),
                Text(
                  '${results.responseCount} ${results.responseCount == 1 ? "response" : "responses"}',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),

                // headline stat
                if (headline != null) ...[
                  Text(headline.question,
                      style: GoogleFonts.inter(
                          color: VendorTheme.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (final opt in headline.options) ...[
                    _bar(opt.label, opt.percent),
                    const SizedBox(height: 8),
                  ],
                ] else
                  Text('Tap to see the full results.',
                      style: GoogleFonts.inter(
                          color: VendorTheme.textSecondary, fontSize: 13)),

                const SizedBox(height: 14),
                const Divider(color: VendorTheme.surfaceVariant, height: 1),
                const SizedBox(height: 12),

                // call to action
                Row(
                  children: [
                    const Icon(Icons.touch_app_outlined,
                        size: 16, color: VendorTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('Answer it yourself on Amril',
                          style: GoogleFonts.inter(
                              color: VendorTheme.textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(String label, double percent) {
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
            Text('${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}%',
                style: GoogleFonts.inter(
                    color: VendorTheme.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 5),
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
                        colors: [Color(0xFF177E85), VendorTheme.primary]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// First choice question + its top 3 options, or null if the survey has no
  /// choice questions to visualise.
  _Headline? _headline() {
    for (final q in results.questions) {
      if (q.type == SurveyQuestionType.singleChoice ||
          q.type == SurveyQuestionType.multiChoice) {
        if (q.options.isEmpty) continue;
        final sorted = [...q.options]..sort((a, b) => b.votes.compareTo(a.votes));
        return _Headline(question: q.prompt, options: sorted.take(3).toList());
      }
    }
    return null;
  }
}

class _Headline {
  final String question;
  final List<ResultOption> options;
  _Headline({required this.question, required this.options});
}