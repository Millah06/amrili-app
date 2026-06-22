// lib/shared/widgets/web_app_banner.dart
//
// Phase 12 (Track B) — Platform-aware "Download Amril" banner shown only
// on the Flutter Web build.
//
// HOW IT WORKS
//   1. The MaterialApp.router `builder:` callback wraps the Navigator with
//      this widget. It is always constructed but bails out immediately on
//      native builds (kIsWeb == false).
//   2. Platform detection uses Theme.of(context).platform, which Flutter web
//      derives from the browser user-agent string:
//        Android phone/tablet → TargetPlatform.android
//        iPhone / iPad        → TargetPlatform.iOS
//        Mac / Windows / Linux browser → TargetPlatform.macOS / .windows / .linux
//   3. On mobile devices the CTA deep-links straight to the correct store.
//      On desktop browsers the copy says "Download for mobile" and links to
//      the Play Store (most common case for desktop → phone handoff).
//   4. The banner slides up 2 s after the first frame (so it doesn't compete
//      with the splash) and can be dismissed in-session via the × button.
//
// STORE URL PLACEHOLDERS
//   Play Store  — already uses the real bundle ID (com.amril.app).
//   App Store   — the ID placeholder below MUST be replaced once the iOS
//                 listing is live. Search "PLACEHOLDER" in this file.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constraints/app_theme.dart';

// ── Store deep-link constants ──────────────────────────────────────────────
const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=com.amril.app';

// PLACEHOLDER — replace with real Apple ID once the iOS listing is approved.
const String _appStoreUrl =
    'https://apps.apple.com/app/amril/id000000000';

// ─────────────────────────────────────────────────────────────────────────────
// WebAppBannerOverlay wraps the root Navigator produced by MaterialApp.router.
// It works by using a Stack so the banner floats above every page without
// interfering with navigation or theme.
// ─────────────────────────────────────────────────────────────────────────────
class WebAppBannerOverlay extends StatefulWidget {
  final Widget child;

  const WebAppBannerOverlay({super.key, required this.child});

  @override
  State<WebAppBannerOverlay> createState() => _WebAppBannerOverlayState();
}

class _WebAppBannerOverlayState extends State<WebAppBannerOverlay>
    with SingleTickerProviderStateMixin {

  bool _dismissed = false;

  // Slide-up entrance so the banner doesn't jarring-pop from nothing.
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1.4), // start below the viewport bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Delay 2 s so the banner doesn't compete with the Flutter first-frame
    // render or the navigation loading state.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _dismiss() {
    // Slide back down, then remove from tree.
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  Future<void> _openStore(TargetPlatform platform) async {
    final url = platform == TargetPlatform.iOS ? _appStoreUrl : _playStoreUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // ExternalApplication opens the Play/App Store app on mobile;
      // on desktop it opens a browser tab.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // On native platforms the overlay is invisible — return the child as-is.
    if (!kIsWeb || _dismissed) return widget.child;

    final platform = Theme.of(context).platform;
    final isMobileDevice =
        platform == TargetPlatform.android || platform == TargetPlatform.iOS;

    // Copy adapts to the visitor's device type.
    final String headline = isMobileDevice
        ? 'Better on the app — it\'s free'
        : 'Download Amril for your phone';
    final String subline = isMobileDevice
        ? 'Faster access, push alerts & more'
        : 'Shop, pay bills, stay connected';
    final String ctaLabel = platform == TargetPlatform.iOS
        ? 'App Store'
        : 'Google Play';

    return Stack(
      children: [
        // The real app content sits underneath — not clipped or dimmed.
        widget.child,

        // Banner anchored to the bottom of the screen.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: _BannerCard(
              headline: headline,
              subline: subline,
              ctaLabel: isMobileDevice ? 'Get on $ctaLabel' : 'Download ↓',
              onTap: () => _openStore(platform),
              onDismiss: _dismiss,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BannerCard — the visual card.
//
// Design intent: small, unobtrusive, dark-themed. The gradient Amril ring on
// the left acts as the brand stamp; the CTA chip uses the primary cyan-to-teal
// gradient so it reads as a button without needing heavy chrome. The dismiss
// × is small (18 px) so it doesn't compete with the CTA.
// ─────────────────────────────────────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final String headline;
  final String subline;
  final String ctaLabel;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _BannerCard({
    required this.headline,
    required this.subline,
    required this.ctaLabel,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // Top safe-area is already handled by the page above us.
      top: false,
      child: Semantics(
        // The whole card is interactive — announce that for screen readers.
        container: true,
        label: 'Download the Amril app. $headline.',
        child: GestureDetector(
          // Whole card taps through to the store.
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [

                // Brand ring — teal gradient circle with the "A" wordmark.
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 21,
                      height: 1,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Copy — headline + subline.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        headline,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subline,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // CTA pill — gradient so it stands out from the card.
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 2),

                // Dismiss button — small tap target padded to 36 × 36 for a11y.
                Semantics(
                  button: true,
                  label: 'Dismiss',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onDismiss,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
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
