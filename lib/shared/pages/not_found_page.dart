// lib/shared/pages/not_found_page.dart
//
// In-app 404 for unknown SPA routes (GoRouter errorBuilder). Restyled to match
// the static amril-web/404.html exactly, so the experience is unified whether a
// bad URL is caught by Cloudflare (static 404) or by GoRouter (this page).
//
// NOTE on "two 404 pages": they live at different layers and BOTH are needed —
// the static 404.html handles unknown *files* at the site root; this handles
// unknown *routes* inside the Flutter app. Making them visually identical (done
// here) is the right kind of "one" — a single, consistent look.
//
// Constructor unchanged: NotFoundPage(attemptedLocation: ...).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NotFoundPage extends StatelessWidget {
  final String attemptedLocation;
  const NotFoundPage({super.key, required this.attemptedLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 404 · NOT FOUND (mono, cyan) — same as the web page.
                Text(
                  '404 · NOT FOUND',
                  style: GoogleFonts.jetBrainsMono(
                    color: const Color(0xFF21D3ED),
                    fontSize: 13,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    text: 'This page wandered off',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    children: const [
                      TextSpan(text: '.', style: TextStyle(color: Color(0xFF21D3ED))),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'The link may be broken or the page may have moved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFF7E8DA6), fontSize: 14.5),
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF21D3ED),
                    foregroundColor: const Color(0xFF06131C),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: Text('← Back to Amril',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}