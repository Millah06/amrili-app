// ─────────────────────────────────────────────────────────────────────────────
// responsive_center.dart  — Phase 3 (Flutter Web) layout helpers.
//
// The deep-link landing pages (store / product / post / profile / 404) were
// built mobile-first. On a wide browser, full-bleed mobile layouts look stranded
// in a sea of whitespace. These helpers let those pages stay UNCHANGED internally
// while presenting nicely across mobile / tablet / desktop:
//
//   • ResponsiveCenter  — caps content width and centres it on large screens;
//                         pass-through (full width) on phones.
//   • context.amrilBreakpoint / isWideScreen — cheap width checks for one-off
//                         tweaks (e.g. switching a Column to a Row).
//
// Brand-aligned: no new colours/fonts, just spacing + max-width discipline so it
// reads as the same product, only wider.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

/// App breakpoints. Kept small and intention-revealing rather than scattering
/// magic numbers across the landing pages.
enum AmrilBreakpoint { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  /// Current breakpoint from the layout width.
  AmrilBreakpoint get amrilBreakpoint {
    final w = MediaQuery.sizeOf(this).width;
    if (w >= 1024) return AmrilBreakpoint.desktop;
    if (w >= 600) return AmrilBreakpoint.tablet;
    return AmrilBreakpoint.mobile;
  }

  /// True on tablet/desktop — handy for `isWide ? Row(...) : Column(...)`.
  bool get isWideScreen => amrilBreakpoint != AmrilBreakpoint.mobile;
}

/// Centres [child] and caps its width on large screens so content stays
/// readable. On mobile it's a transparent pass-through (no behaviour change),
/// which is exactly what we want for the existing phone layouts.
///
/// Usage — wrap a landing page's body:
/// ```dart
/// body: ResponsiveCenter(child: existingColumn),
/// ```
class ResponsiveCenter extends StatelessWidget {
  /// Max content width on wide screens. 560 suits single-column reading
  /// surfaces (a post, a product); bump to 960 for two-column store layouts.
  final double maxWidth;

  /// Horizontal breathing room applied at all sizes.
  final EdgeInsetsGeometry padding;

  final Widget child;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 560,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A slim, dismissible-free banner promoting the native app on web pages.
/// Drop it at the top of a landing page so web visitors have a clear path to
/// the full experience. Mobile-web shows "Open app"; desktop shows store links.
///
/// Pass the store URLs once they exist; nulls hide the respective button.
class GetTheAppBanner extends StatelessWidget {
  final String? playStoreUrl;
  final String? appStoreUrl;

  /// Optional deep link to attempt opening the installed app first
  /// (e.g. the current page's https://amril.app/... URL).
  final VoidCallback? onOpenApp;

  const GetTheAppBanner({
    super.key,
    this.playStoreUrl,
    this.appStoreUrl,
    this.onOpenApp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(
          bottom: BorderSide(color: Color(0xFF21D3ED), width: 2),
        ),
      ),
      child: Row(
        children: [
          // Brand glyph chip — same treatment as the in-app icon tiles.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              'A',
              style: TextStyle(
                color: Color(0xFF21D3ED),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Get the full Amril experience',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          if (onOpenApp != null)
            TextButton(
              onPressed: onOpenApp,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF21D3ED),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Open app',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}