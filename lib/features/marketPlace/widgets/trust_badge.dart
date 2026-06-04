// lib/features/marketPlace/widgets/trust_badge.dart
//
// PHASE 4 — Merchant Trust System (reusable badge)
// ─────────────────────────────────────────────────────────────────────────────
// A small, self-contained pill that visualises a merchant's trust level on any
// surface (vendor card, store header, vendor center). It is intentionally
// LEVEL-DRIVEN with a graceful fallback to the legacy `verified` flag, so it can
// be dropped onto surfaces that only know `Vendor.verified` today and will light
// up automatically once those payloads start carrying the trust level.
//
// Visual hierarchy (matches VendorTheme dark palette):
//   • Level 3 Business  → solid blue, white check  (the flagship "verified" look)
//   • Level 2 Trusted   → emerald accent, shield
//   • Level 1 Identity  → muted slate, person check (subtle — most sellers)
//   • Level 0 / none    → nothing (no badge for unverified)
//
// Two builders:
//   TrustBadge(level: ...)        — full pill with label, for headers/detail.
//   TrustBadge.compact(level:)    — icon-only, for dense cards/lists.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/vendor_theme.dart';

class TrustBadge extends StatelessWidget {
  /// 0–3. If null, falls back to [verifiedFallback].
  final int? level;

  /// Legacy `Vendor.verified` flag. When true and [level] is null/<3 we still
  /// render the Business look, so existing verified vendors keep their badge.
  final bool verifiedFallback;

  /// Icon-only when true (use inside tight card rows).
  final bool compact;

  const TrustBadge({
    super.key,
    required this.level,
    this.verifiedFallback = false,
    this.compact = false,
  });

  /// Convenience constructor for dense surfaces.
  const TrustBadge.compact({
    super.key,
    required this.level,
    this.verifiedFallback = false,
  }) : compact = true;

  /// Resolve the effective level: an explicit level wins; otherwise a legacy
  /// `verified` vendor is treated as Business (3).
  int get _effectiveLevel {
    if (level != null && level! >= 1) return level!;
    if (verifiedFallback) return 3;
    return level ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final lvl = _effectiveLevel;
    // No badge for unverified merchants — keeps low-trust cards clean.
    if (lvl < 1) return const SizedBox.shrink();

    final spec = _specFor(lvl);

    // Icon-only pill for dense lists.
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: spec.bg,
          shape: BoxShape.circle,
          border: Border.all(color: spec.fg.withOpacity(0.4), width: 0.5),
        ),
        child: Icon(spec.icon, size: 11, color: spec.fg),
      );
    }

    // Full label pill.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: spec.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: spec.fg.withOpacity(0.35), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 12, color: spec.fg),
          const SizedBox(width: 4),
          Text(
            spec.label,
            style: GoogleFonts.inter(
              color: spec.fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeSpec _specFor(int lvl) {
    switch (lvl) {
      case 3:
      // Flagship verified look — solid blue, white check.
        return _BadgeSpec(
          label: 'Verified',
          icon: Icons.verified,
          fg: Colors.white,
          bg: VendorTheme.primaryVariant,
        );
      case 2:
        return _BadgeSpec(
          label: 'Trusted',
          icon: Icons.shield_rounded,
          fg: VendorTheme.accent,
          bg: VendorTheme.accent.withOpacity(0.12),
        );
      case 1:
      default:
        return _BadgeSpec(
          label: 'ID Verified',
          icon: Icons.how_to_reg_rounded,
          fg: VendorTheme.textSecondary,
          bg: VendorTheme.surfaceVariant.withOpacity(0.6),
        );
    }
  }
}

class _BadgeSpec {
  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;
  const _BadgeSpec({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });
}