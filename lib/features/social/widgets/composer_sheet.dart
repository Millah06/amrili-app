// =============================================================================
// lib/features/social/widgets/composer_sheet.dart
// -----------------------------------------------------------------------------
// PHASE 11 — THE COMPOSER ENTRY POINT
// =============================================================================
//
// Before Phase 11 the feed's "+" button pushed straight to CreatePostScreen.
// Now there are TWO things you can create — a post or a survey — so the "+"
// first opens this little chooser. It is PURELY a chooser: it returns the user's
// choice ('post' | 'survey' | null) and lets the caller (feed_screen) do the
// navigation + feed refresh. Keeping navigation in the caller means the feed can
// refresh itself when the create screen pops `true`, exactly as it did before.
//
// Visual language is lifted from gift_bottom_sheet.dart (the slate gradient
// sheet with a grab handle) so it feels like the same family of surfaces. The
// two options are big tap targets — survey gets the cyan→teal gradient accent to
// signal it's the new, marquee action.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';

class ComposerSheet {
  /// Shows the chooser and resolves to 'post', 'survey', or null (dismissed).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent, // we draw our own rounded gradient
      isScrollControlled: true,
      builder: (_) => const _ComposerSheetBody(),
    );
  }
}

class _ComposerSheetBody extends StatelessWidget {
  const _ComposerSheetBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Same gradient as the gift sheet → cohesive surface family.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grab handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[700],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Create',
            style: GoogleFonts.poppins(
              color: VendorTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          // OPTION 1 — Post (quiet styling: it's the familiar action)
          _ComposerOption(
            icon: Icons.edit_outlined,
            iconBg: VendorTheme.surfaceVariant,
            iconColor: VendorTheme.textPrimary,
            title: 'Write a post',
            subtitle: 'Share a thought, a photo, or an update.',
            onTap: () => Navigator.pop(context, 'post'),
          ),
          const SizedBox(height: 12),

          // OPTION 2 — Survey (marquee styling: the new wedge)
          _ComposerOption(
            icon: Icons.insights_rounded,
            // cyan→teal gradient badge to mark it as the highlighted action
            iconGradient: const LinearGradient(
              colors: [VendorTheme.primary, Color(0xFF177E85)],
            ),
            iconColor: Colors.white,
            title: 'Create a survey',
            subtitle: 'Ask real people, get real answers — reward them in coins.',
            highlighted: true,
            onTap: () => Navigator.pop(context, 'survey'),
          ),
        ],
      ),
    );
  }
}

class _ComposerOption extends StatelessWidget {
  final IconData icon;
  final Color? iconBg;
  final Gradient? iconGradient;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _ComposerOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconBg,
    this.iconGradient,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: VendorTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              // Highlighted (survey) gets a subtle cyan ring.
              color: highlighted
                  ? VendorTheme.primary.withOpacity(0.45)
                  : VendorTheme.surfaceVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  gradient: iconGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: VendorTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: VendorTheme.textSecondary,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: VendorTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}