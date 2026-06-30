// lib/features/legal/legal_document_page.dart
//
// Generic in-app legal renderer. Loads the bundled HTML fragment from
// assets/legal/ and renders it with flutter_html, dark-themed.
//
// flutter_html can't use external CSS, so the polish lives in the Style map
// below (_legalHtmlStyle) — section dividers, accent hierarchy, cyan callouts,
// and bordered tables — to bring the in-app pages much closer to the styled
// web pages at /legal/*. Same copy, nicer presentation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, Clipboard, ClipboardData;
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';

import 'legal_docs.dart';

class LegalDocumentPage extends StatefulWidget {
  final LegalDoc? doc;
  final String? assetPath;
  final String? title;

  const LegalDocumentPage({super.key, this.doc, this.assetPath, this.title})
      : assert(doc != null || (assetPath != null && title != null),
  'Provide either a LegalDoc or an assetPath + title.');

  factory LegalDocumentPage.of(String slug, {Key? key}) =>
      LegalDocumentPage(key: key, doc: legalDocBySlug(slug));

  @override
  State<LegalDocumentPage> createState() => _LegalDocumentPageState();
}

class _LegalDocumentPageState extends State<LegalDocumentPage> {
  String? _html;
  bool _error = false;

  String get _assetPath => widget.doc?.assetPath ?? widget.assetPath!;
  String get _title => widget.doc?.title ?? widget.title!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final content = await rootBundle.loadString(_assetPath);
      if (!mounted) return;
      setState(() => _html = content);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  void _onLinkTap(String? url) {
    if (url == null) return;
    final legalMatch = RegExp(r'/legal/([a-z\-]+)').firstMatch(url);
    if (legalMatch != null) {
      final slug = legalMatch.group(1)!;
      if (kLegalDocs.any((d) => d.slug == slug)) {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => LegalDocumentPage.of(slug)));
        return;
      }
    }
    // External / mailto → clipboard fallback (no url_launcher dependency).
    // If url_launcher is in your pubspec, swap this for launchUrl(Uri.parse(url)).
    final display = url.replaceFirst('mailto:', '');
    Clipboard.setData(ClipboardData(text: display));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Copied: $display'),
      backgroundColor: const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(_title,
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: _error
          ? _ErrorState(onRetry: () {
        setState(() => _error = false);
        _load();
      })
          : _html == null
          ? const _LoadingSkeleton()
          : Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 56),
            child: Html(
              data: _html!,
              // v3 signature: (url, attributes, element).
              // On v2 use: (url, context, attributes, element).
              onLinkTap: (url, _, __) => _onLinkTap(url),
              style: _legalHtmlStyle(),
            ),
          ),
        ),
      ),
    );
  }
}

// Rich dark styling for the rendered legal HTML. Keys map to the plain semantic
// tags emitted by build_legal.py (h1/h2/h3/p/em/strong/ul/li/a/blockquote/table).
Map<String, Style> _legalHtmlStyle() {
  final inter = GoogleFonts.inter().fontFamily;
  final poppins = GoogleFonts.poppins().fontFamily;
  const ink = Color(0xFFBFCAD9);     // body
  const faint = Color(0x14FFFFFF);   // hairline dividers

  return {
    'body': Style(
      color: ink,
      fontSize: FontSize(15.5),
      lineHeight: const LineHeight(1.72),
      fontFamily: inter,
      margin: Margins.zero,
    ),
    // Title
    'h1': Style(
      color: Colors.white,
      fontSize: FontSize(28),
      fontWeight: FontWeight.w700,
      fontFamily: poppins,
      lineHeight: const LineHeight(1.15),
      margin: Margins.only(top: 4, bottom: 12),
    ),
    // Section heading with a hairline divider above (mirrors the web rhythm).
    'h2': Style(
      color: Colors.white,
      fontSize: FontSize(19.5),
      fontWeight: FontWeight.w700,
      fontFamily: poppins,
      margin: Margins.only(top: 36, bottom: 12),
      padding: HtmlPaddings.only(top: 22),
      border: const Border(top: BorderSide(color: faint, width: 1)),
    ),
    'h3': Style(
      color: const Color(0xFFE2E8F0),
      fontSize: FontSize(16),
      fontWeight: FontWeight.w600,
      fontFamily: inter,
      margin: Margins.only(top: 20, bottom: 6),
    ),
    'p': Style(margin: Margins.only(bottom: 14)),
    // The meta lines (updated / entity) are <em>; render them muted.
    'em': Style(color: const Color(0xFF8597B0), fontStyle: FontStyle.italic),
    'strong': Style(color: Colors.white, fontWeight: FontWeight.w600),
    'a': Style(
      color: const Color(0xFF21D3ED),
      textDecoration: TextDecoration.none,
      fontWeight: FontWeight.w600,
    ),
    'ul': Style(margin: Margins.only(bottom: 14, top: 2, left: 2)),
    'li': Style(margin: Margins.only(bottom: 8), color: ink),
    // "note" callouts are <blockquote> → cyan-accented panel.
    'blockquote': Style(
      backgroundColor: const Color(0xFF13203A),
      border: const Border(left: BorderSide(color: Color(0xFF21D3ED), width: 3)),
      padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 12),
      margin: Margins.only(top: 6, bottom: 18),
      color: const Color(0xFFD3DEEC),
      fontSize: FontSize(15),
    ),
    // Processor / data tables.
    'table': Style(
      margin: Margins.only(bottom: 20),
      border: const Border.fromBorderSide(BorderSide(color: faint, width: 1)),
    ),
    'th': Style(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      backgroundColor: const Color(0xFF1E293B),
      padding: HtmlPaddings.all(10),
      border: const Border(bottom: BorderSide(color: faint, width: 1)),
    ),
    'td': Style(
      padding: HtmlPaddings.all(10),
      color: ink,
      border: const Border(bottom: BorderSide(color: faint, width: 1)),
    ),
  };
}

// ── Loading + error states ───────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w) => Container(
      width: w,
      height: 14,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(220),
              const SizedBox(height: 12),
              bar(double.infinity),
              bar(double.infinity),
              bar(280),
              const SizedBox(height: 24),
              bar(double.infinity),
              bar(double.infinity),
              bar(200),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, color: Color(0xFF334155), size: 48),
            const SizedBox(height: 16),
            Text('We couldn\'t load this document',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Check your connection and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14)),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF21D3ED),
                side: const BorderSide(color: Color(0xFF21D3ED)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}