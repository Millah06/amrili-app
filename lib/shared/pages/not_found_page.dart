// lib/shared/pages/not_found_page.dart
//
// PHASE 1 — FOUNDATION
//
// GoRouter's `errorBuilder` target. Any unmatched location — a malformed QR
// code, a stale link to deleted content, a typo'd path — lands here instead of
// Flutter's red error screen. The single job of this page is to be calm and
// give one obvious way back into the app.
//
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constraints/vendor_theme.dart';

class NotFoundPage extends StatelessWidget {
  /// The location GoRouter failed to match — surfaced subtly for support/debug,
  /// never as a scary stack trace.
  final String? attemptedLocation;
  const NotFoundPage({super.key, this.attemptedLocation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_rounded,
                    size: 72, color: VendorTheme.textMuted),
                const SizedBox(height: 24),
                Text('We couldn’t find that page',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 10),
                Text(
                    'The link may be broken or the content may have moved. '
                        'Let’s get you back on track.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        fontSize: 14, height: 1.55, color: Colors.white60)),
                if (attemptedLocation != null &&
                    attemptedLocation!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(attemptedLocation!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.robotoMono(
                          fontSize: 12, color: Colors.white30)),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: VendorTheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    onPressed: () => context.go('/'),
                    child: Text('Back to home',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}