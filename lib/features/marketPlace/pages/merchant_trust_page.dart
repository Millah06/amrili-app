// lib/features/marketPlace/pages/merchant_trust_page.dart
//
// PHASE 4 — Merchant Trust System (flagship vendor screen)
// ─────────────────────────────────────────────────────────────────────────────
// Reached from Vendor Center → Profile tab. Surfaces the merchant's current
// trust level and the path to the next one, and hosts every upgrade action:
//
//   Level 0 (Unverified) → upload a government ID (auto-approves to Level 1).
//   Level 1 (Identity)   → automatic progress to Trusted (read-only checklist).
//   Level 2 (Trusted)    → upgrade to Business: CAC upload + ₦2,500 fee + review.
//   Level 3 (Business)    → celebratory "you're verified" state + benefits.
//
// Design intent (matches VendorTheme dark + Inter, like edit_vendor_profile and
// verified_merchant_page):
//   • A gradient hero whose colour encodes the level, with a circular progress
//     ring showing completion toward the next level — the single focal point.
//   • A compact 3-stat strip (settlement speed, daily limit, selling status) so
//     the merchant immediately understands what their level *buys* them.
//   • A horizontal level ladder (0→3) for a sense of journey/progress.
//   • One adaptive action card — never more than one primary CTA on screen.
//   • Real states: skeleton while loading, friendly error with retry, success
//     snackbars. No raw spinners on first paint.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import 'business_documents_screen.dart';
import '../../verification/email_verification_sheet.dart';
import '../../verification/kyc_verification_screen.dart';
import '../models/merchant_trust_model.dart';
import '../providers/vendor_center_provider.dart';
import '../widgets/navigation.dart';
import '../widgets/shared_widgets.dart'; // VButton
import '../widgets/trust_badge.dart';

class MerchantTrustPage extends StatefulWidget {
  const MerchantTrustPage({super.key});

  @override
  State<MerchantTrustPage> createState() => _MerchantTrustPageState();
}

class _MerchantTrustPageState extends State<MerchantTrustPage>
    with SingleTickerProviderStateMixin {
  MerchantTrustModel? _trust;
  bool _loading = true; // first-paint skeleton
  bool _busy = false; // an action (upload/pay) is in flight
  String? _error;

  // Drives the skeleton shimmer so the loading state feels alive, not frozen.
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  ApiClientShim get _api => context.read<VendorCenterProvider>().api as ApiClientShim;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<VendorCenterProvider>().api
          .get('/vendor/trust/status');
      if (!mounted) return;
      setState(() {
        _trust = MerchantTrustModel.fromJson(Map<String, dynamic>.from(data));
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _clean(e);
        _loading = false;
      });
    }
  }

  String _clean(Object e) => e.toString().replaceAll('Exception: ', '');

  void _toast(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? VendorTheme.accent : VendorTheme.error,
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  // Future<void> _submitIdentity() async {
  //   // Opens the KYC screen if needed; returns true once identity is verified.
  //
  //   if (!verified) return;
  //
  //   setState(() => _busy = true);
  //   try {
  //     // KYC is verified → flip vendor Level 1. submit-identity now keys off Kyc
  //     // (no file). Body is empty.
  //     final data = await context
  //         .read<VendorCenterProvider>()
  //         .api
  //         .post('/vendor/trust/submit-identity', {});
  //     setState(() =>
  //     _trust = MerchantTrustModel.fromJson(Map<String, dynamic>.from(data)));
  //     _toast('Identity verified — you can now sell.');
  //   } catch (e) {
  //     _toast(_clean(e), success: false);
  //   } finally {
  //     if (mounted) setState(() => _busy = false);
  //   }
  // }

  /// Level 0 → 1: pick a government ID and submit it. Auto-approves on success.
  // Future<void> _submitIdentity() async {
  //   final picked =
  //   await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
  //   if (picked == null) return;
  //
  //   setState(() => _busy = true);
  //   try {
  //     // Reuses the standard upload helper (multipart field "image").
  //     final data = await context.read<VendorCenterProvider>().api.submitIdentity(
  //       '/vendor/trust/submit-identity',
  //       File(picked.path),
  //       picked.name,
  //     );
  //     setState(() {
  //       _trust = MerchantTrustModel.fromJson(Map<String, dynamic>.from(data));
  //     });
  //     _toast('Identity verified — you can now sell on Amril.');
  //   } catch (e) {
  //     _toast(_clean(e), success: false);
  //   } finally {
  //     if (mounted) setState(() => _busy = false);
  //   }
  // }

  /// Level 2 → 3 step 1: open the multi-document upload screen.
  Future<void> _openDocumentUpload() async {
    final submitted = await vendorPush<bool>(
      context,
      BusinessDocumentsScreen(
        existingDocs: _trust?.businessDocuments ?? const {},
      ),
    );
    if (submitted == true) {
      _toast('Application submitted for review.');
      await _load();
    } else {
      // Docs may have been uploaded without submitting — refresh to show hasCacDocument.
      await _load();
    }
  }

  /// Level 2 → 3: submit for review (no fee required).
  Future<void> _payFeeAndApply() async {
    setState(() => _busy = true);
    try {
      final data = await context.read<VendorCenterProvider>().api.post(
        '/vendor/trust/pay-fee',
        {},
      );
      if (!mounted) return;
      setState(() {
        _trust = MerchantTrustModel.fromJson(Map<String, dynamic>.from(data));
      });
      _toast('Application submitted — your request is under review.');
    } catch (e) {
      _toast(_clean(e), success: false);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Opens the email verification sheet; refreshes trust status on success.
  Future<void> _verifyEmail() async {
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const EmailVerificationSheet(),
    );
    if (verified == true) {
      _toast('Email verified.');
      await _load();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('Verification & Trust',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 17)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: _loading
              ? _SkeletonBody(shimmer: _shimmer)
              : _error != null
              ? _ErrorBody(message: _error!, onRetry: _load)
              : _content(_trust!),
        ),
      ),
    );
  }

  Widget _content(MerchantTrustModel t) {
    return RefreshIndicator(
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _Hero(trust: t),
          const SizedBox(height: 16),
          _StatStrip(trust: t),
          const SizedBox(height: 16),
          _LevelLadder(current: t.level),
          const SizedBox(height: 20),
          // The single adaptive action card.
          _ActionCard(
            trust: t,
            busy: _busy,
            onSubmitIdentity: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const KycVerificationScreen()),
              );
            },
            onUploadCac: _openDocumentUpload,
            onPayFee: _payFeeAndApply,
            onVerifyEmail: _verifyEmail,
          ),
          const SizedBox(height: 20),
          // "Your benefits" — pulled from the catalog entry for the current
          // level (no hardcoding). Falls back silently if the backend predates
          // the catalog.
          _Benefits(current: _levelInfo(t, t.level)),
          const SizedBox(height: 24),
          // Full comparison of EVERY level — any merchant can open any tier to
          // see its requirements + benefits, with their own progress ticked.
          if (t.levels.isNotEmpty)
            _LevelComparison(levels: t.levels, currentLevel: t.level),
        ],
      ),
    );
  }

  /// Find the catalog entry for [level], or null if the list doesn't include it.
  TrustLevelInfo? _levelInfo(MerchantTrustModel t, int level) {
    for (final l in t.levels) {
      if (l.level == level) return l;
    }
    return null;
  }
}

// A tiny shim type alias so the analyzer doesn't complain about the unused
// getter pattern above; the real client is ApiService. (Kept private/local.)
typedef ApiClientShim = dynamic;

// ─────────────────────────────────────────────────────────────────────────────
// Hero — gradient card, level badge, progress ring to next level
// ─────────────────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  final MerchantTrustModel trust;
  const _Hero({required this.trust});

  // Each level gets its own gradient so the hero "feels" like the tier.
  List<Color> _gradient(int level) {
    switch (level) {
      case 3:
        return const [Color(0xFF1D4ED8), Color(0xFF7C3AED)]; // business blue→violet
      case 2:
        return const [Color(0xFF0F766E), Color(0xFF10B981)]; // trusted teal→emerald
      case 1:
        return const [Color(0xFF334155), Color(0xFF475569)]; // identity slate
      default:
        return const [Color(0xFF475569), Color(0xFF64748B)]; // unverified grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = trust.nextLevel;
    final progress = next?.progress ?? 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradient(trust.level),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Progress ring around the level number.
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    value: trust.level >= 3 ? 1.0 : progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.white24,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text('L${trust.level}',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(trust.levelLabel,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 18)),
                    ),
                    if (trust.level >= 1) ...[
                      const SizedBox(width: 8),
                      TrustBadge(level: trust.level),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  trust.level >= 3
                      ? "You've reached the highest trust level."
                      : next != null
                      ? '${(progress * 100).round()}% toward Level ${next.level}'
                      : 'Verification complete.',
                  style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat strip — settlement speed · daily limit · selling status
// ─────────────────────────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  final MerchantTrustModel trust;
  const _StatStrip({required this.trust});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _stat(Icons.bolt_rounded, 'Settlement', trust.settlementLabel),
        const SizedBox(width: 10),
        _stat(Icons.account_balance_wallet_outlined, 'Daily limit',
            trust.dailyLimitLabel),
        const SizedBox(width: 10),
        _stat(
          trust.canSell ? Icons.storefront : Icons.lock_outline,
          'Selling',
          trust.canSell ? 'Active' : 'Locked',
          highlight: !trust.canSell,
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? VendorTheme.warning.withOpacity(0.4)
                : VendorTheme.divider,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 18,
                color: highlight ? VendorTheme.warning : VendorTheme.primary),
            const SizedBox(height: 8),
            Text(value,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: VendorTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level ladder — 0 → 1 → 2 → 3 with the current level highlighted
// ─────────────────────────────────────────────────────────────────────────────

class _LevelLadder extends StatelessWidget {
  final int current;
  const _LevelLadder({required this.current});

  static const _labels = ['Unverified', 'Identity', 'Trusted', 'Business'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(4, (i) {
        final reached = i <= current;
        final isCurrent = i == current;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  // Connector line on the left (except the first node).
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= current
                            ? VendorTheme.primary
                            : VendorTheme.divider,
                      ),
                    )
                  else
                    const Spacer(),
                  // Node.
                  Container(
                    width: isCurrent ? 22 : 16,
                    height: isCurrent ? 22 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached
                          ? VendorTheme.primary
                          : VendorTheme.surfaceVariant,
                      border: Border.all(
                        color: isCurrent ? Colors.white : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: reached
                        ? const Icon(Icons.check,
                        size: 11, color: VendorTheme.background)
                        : null,
                  ),
                  // Connector line on the right (except the last node).
                  if (i < 3)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: (i + 1) <= current
                            ? VendorTheme.primary
                            : VendorTheme.divider,
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
              const SizedBox(height: 6),
              Text(_labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isCurrent
                        ? VendorTheme.textPrimary
                        : VendorTheme.textMuted,
                    fontSize: 10,
                    fontWeight:
                    isCurrent ? FontWeight.w600 : FontWeight.normal,
                  )),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adaptive action card — exactly one primary CTA, chosen by level + state
// ─────────────────────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final MerchantTrustModel trust;
  final bool busy;
  final VoidCallback onSubmitIdentity;
  final VoidCallback onUploadCac;
  final VoidCallback onPayFee;
  final VoidCallback onVerifyEmail;

  const _ActionCard({
    required this.trust,
    required this.busy,
    required this.onSubmitIdentity,
    required this.onUploadCac,
    required this.onPayFee,
    required this.onVerifyEmail,
  });

  @override
  Widget build(BuildContext context) {
    switch (trust.level) {
      case 0:
        return _level0(context);
      case 1:
        return _autoProgress(
          context,
          title: 'On your way to Trusted',
          subtitle:
          'Trusted status is granted automatically once you meet the targets below.',
        );
      case 2:
        return _level2(context);
      default:
        return _level3(context);
    }
  }

  // Level 0 — verify identity to start selling.
  Widget _level0(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.badge_outlined, 'Verify your identity',
              'Verify with your BVN or NIN to unlock selling. It takes a few seconds.'),
          const SizedBox(height: 16),
          VButton(
            label: busy ? 'Verifying…' : 'Verify identity',
            loading: busy,
            onTap: busy ? null : onSubmitIdentity,
          ),
        ],
      ),
    );
  }

  // Level 2 — multi-step Business upgrade, but only ONE button visible at a time.
  Widget _level2(BuildContext context) {
    final next = trust.nextLevel;
    final reqs = next?.requirements ?? const [];
    // Performance gate = the order/dispute requirements (everything except the
    // manual cac/fee/admin steps).
    final perfMet = reqs
        .where((r) => r.key == 'orders' || r.key == 'disputes')
        .every((r) => r.met);

    Widget cta;
    if (trust.isPendingReview) {
      cta = _pendingBanner();
    } else if (!perfMet) {
      cta = _lockedNote(
          'Keep going — Business unlocks after you meet the order and dispute targets above.');
    } else if (!trust.hasCacDocument) {
      cta = VButton(
        label: 'Upload business documents',
        loading: busy,
        onTap: busy ? null : onUploadCac,
      );
    } else {
      cta = VButton(
        label: busy ? 'Submitting…' : 'Submit for review',
        loading: busy,
        onTap: busy ? null : onPayFee,
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.workspace_premium_outlined, 'Upgrade to Business',
              'Get the blue verified badge, instant settlements, unlimited withdrawals and priority support.'),
          const SizedBox(height: 14),
          if (next != null) _Checklist(requirements: next.requirements),
          const SizedBox(height: 16),
          cta,
        ],
      ),
    );
  }

  // Level 3 — celebratory verified state.
  Widget _level3(BuildContext context) {
    return _card(
      accent: VendorTheme.primaryVariant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 14),
          Text('Business Verified',
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'Your store carries the blue badge. Settlements are instant and withdrawals are unlimited.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  // Read-only progress card (Level 1), with inline "Verify email" CTA if needed.
  Widget _autoProgress(BuildContext context,
      {required String title, required String subtitle}) {
    final next = trust.nextLevel;
    final emailUnmet = next?.requirements.any(
            (r) => r.key == 'email' && !r.met) ?? false;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.trending_up_rounded, title, subtitle),
          const SizedBox(height: 14),
          if (next != null) _Checklist(requirements: next.requirements),
          if (emailUnmet) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onVerifyEmail,
                icon: const Icon(Icons.mark_email_read_outlined, size: 16),
                label: const Text('Verify email'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VendorTheme.primary,
                  side: const BorderSide(color: VendorTheme.primary, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── small building blocks ──────────────────────────────────────────────────

  Widget _pendingBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: VendorTheme.warning.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: VendorTheme.warning.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.hourglass_top_rounded,
            color: VendorTheme.warning, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Your Business verification is under review. We’ll notify you within 1–3 business days.',
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _lockedNote(String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: VendorTheme.surfaceVariant.withOpacity(0.4),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline,
            color: VendorTheme.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  color: VendorTheme.textSecondary,
                  fontSize: 12,
                  height: 1.4)),
        ),
      ],
    ),
  );

  Widget _cardHeader(IconData icon, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: VendorTheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: VendorTheme.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: GoogleFonts.poppins(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.inter(
                    color: VendorTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.45)),
          ],
        ),
      ),
    ],
  );

  Widget _card({required Widget child, Color? accent}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: VendorTheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: accent ?? VendorTheme.divider),
    ),
    child: child,
  );
}

// Requirements checklist — green check / muted circle, with current/target hint.
class _Checklist extends StatelessWidget {
  final List<TrustRequirement> requirements;
  const _Checklist({required this.requirements});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: requirements.map((r) {
        final showProgress =
            r.current != null && r.target != null && !r.met;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Icon(
                r.met ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: r.met ? VendorTheme.accent : VendorTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(r.label,
                    style: TextStyle(
                        color: r.met
                            ? VendorTheme.textPrimary
                            : VendorTheme.textSecondary,
                        fontSize: 13)),
              ),
              if (showProgress)
                Text('${r.current}/${r.target}',
                    style: const TextStyle(
                        color: VendorTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Benefits list for the CURRENT level — sourced from the backend catalog entry,
// so nothing is hardcoded here. If the entry is null (older backend) we render
// nothing rather than fall back to stale copy.
// ─────────────────────────────────────────────────────────────────────────────

class _Benefits extends StatelessWidget {
  final TrustLevelInfo? current;
  const _Benefits({required this.current});

  // Map a level to a representative leading icon. Icons are purely decorative
  // (not content), so a tiny per-level lookup is fine and keeps copy on the
  // backend. Benefit TEXT always comes from the catalog.
  IconData _iconFor(int level) {
    switch (level) {
      case 3:
        return Icons.verified;
      case 2:
        return Icons.trending_up;
      case 1:
        return Icons.storefront;
      default:
        return Icons.lock_open;
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = current;
    if (info == null || info.benefits.isEmpty) return const SizedBox.shrink();

    final heading = info.level >= 1 ? 'Your benefits' : 'What you’ll unlock';
    final icon = _iconFor(info.level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading,
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 10),
        ...info.benefits.map((b) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 17, color: VendorTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(b,
                    style: const TextStyle(
                        color: VendorTheme.textSecondary,
                        fontSize: 13,
                        height: 1.35)),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level comparison — every level (0→3) as an expandable card. A merchant on any
// level can open ANY tier (including ones above theirs) to read its
// requirements and benefits, with their own progress ticked against each.
//
// Design intent:
//   • One card per level; the current level is highlighted and expanded by
//     default, so the merchant lands on "where am I".
//   • A status pill per card (Current / Achieved / Locked) gives instant
//     orientation without reading the body.
//   • Tapping a header expands it with a smooth size+fade; multiple can be open.
//   • Settlement + daily-limit chips summarise the tier at a glance; the body
//     splits into Requirements (with met/unmet ticks) and Benefits.
//   • All copy/numbers come from `TrustLevelInfo` (backend catalog) — zero
//     hardcoded level data here.
// ─────────────────────────────────────────────────────────────────────────────

class _LevelComparison extends StatefulWidget {
  final List<TrustLevelInfo> levels;
  final int currentLevel;
  const _LevelComparison({required this.levels, required this.currentLevel});

  @override
  State<_LevelComparison> createState() => _LevelComparisonState();
}

class _LevelComparisonState extends State<_LevelComparison> {
  // Which level cards are expanded. Seed with the current level open.
  late final Set<int> _open = {widget.currentLevel};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.layers_outlined,
                size: 18, color: VendorTheme.primary),
            const SizedBox(width: 8),
            Text('Compare levels',
                style: GoogleFonts.poppins(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'See what every level requires and unlocks — including the ones ahead of you.',
          style: TextStyle(color: VendorTheme.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 14),
        // Highest tier first feels aspirational, but a 0→3 journey reads more
        // naturally top-down; keep ascending to match the ladder above.
        ...widget.levels.map((lvl) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _LevelCard(
            info: lvl,
            currentLevel: widget.currentLevel,
            expanded: _open.contains(lvl.level),
            onToggle: () => setState(() {
              if (!_open.remove(lvl.level)) _open.add(lvl.level);
            }),
          ),
        )),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final TrustLevelInfo info;
  final int currentLevel;
  final bool expanded;
  final VoidCallback onToggle;

  const _LevelCard({
    required this.info,
    required this.currentLevel,
    required this.expanded,
    required this.onToggle,
  });

  bool get _isCurrent => info.level == currentLevel;
  bool get _isAchieved => info.level < currentLevel;
  bool get _isLocked => info.level > currentLevel;

  // Accent colour encodes the tier, matching the hero gradients.
  Color get _accent {
    switch (info.level) {
      case 3:
        return VendorTheme.primaryVariant; // business blue
      case 2:
        return VendorTheme.accent; // trusted emerald
      case 1:
        return VendorTheme.primary; // identity cyan
      default:
        return VendorTheme.textMuted; // unverified grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          // The current level gets a coloured ring to stand out from the rest.
          color: _isCurrent ? _accent : VendorTheme.divider,
          width: _isCurrent ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header (tap target) ──────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Level number chip.
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('L${info.level}',
                        style: GoogleFonts.poppins(
                            color: _accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  // Label + tagline.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info.label,
                            style: GoogleFonts.poppins(
                                color: VendorTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          '${info.settlementLabel} settlement · ${info.dailyLimitLabel}',
                          style: const TextStyle(
                              color: VendorTheme.textMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusPill(),
                  const SizedBox(width: 6),
                  // Rotating chevron signals expandability.
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more,
                        color: VendorTheme.textMuted, size: 22),
                  ),
                ],
              ),
            ),
          ),
          // ── Expandable body ──────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _body(),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }

  Widget _statusPill() {
    final (String text, Color fg, Color bg) = _isCurrent
        ? ('Current', _accent, _accent.withOpacity(0.16))
        : _isAchieved
        ? ('Achieved', VendorTheme.accent,
    VendorTheme.accent.withOpacity(0.14))
        : ('Locked', VendorTheme.textMuted,
    VendorTheme.surfaceVariant.withOpacity(0.6));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAchieved
                ? Icons.check_circle
                : _isCurrent
                ? Icons.my_location
                : Icons.lock_outline,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: VendorTheme.divider, height: 1),
          const SizedBox(height: 12),
          if (info.requirements.isNotEmpty) ...[
            _sectionLabel('Requirements'),
            const SizedBox(height: 6),
            ...info.requirements.map(_requirementRow),
            const SizedBox(height: 12),
          ],
          if (info.benefits.isNotEmpty) ...[
            _sectionLabel('Benefits'),
            const SizedBox(height: 6),
            ...info.benefits.map(_benefitRow),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: VendorTheme.textMuted,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    ),
  );

  Widget _requirementRow(TrustRequirement r) {
    final showProgress = r.current != null && r.target != null && !r.met;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            r.met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 17,
            color: r.met ? VendorTheme.accent : VendorTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.label,
                style: TextStyle(
                    color: r.met
                        ? VendorTheme.textPrimary
                        : VendorTheme.textSecondary,
                    fontSize: 12.5)),
          ),
          if (showProgress)
            Text('${r.current}/${r.target}',
                style: const TextStyle(
                    color: VendorTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _benefitRow(String b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.auto_awesome,
            size: 15, color: _accent.withOpacity(0.9)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(b,
              style: const TextStyle(
                  color: VendorTheme.textSecondary,
                  fontSize: 12.5,
                  height: 1.35)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading + error states
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonBody extends StatelessWidget {
  final Animation<double> shimmer;
  const _SkeletonBody({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        final opacity = 0.35 + (shimmer.value * 0.35);
        Widget box(double h, {double? w, double r = 12}) => Opacity(
          opacity: opacity,
          child: Container(
            height: h,
            width: w,
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            box(96, r: 18), // hero
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: box(86)),
              const SizedBox(width: 10),
              Expanded(child: box(86)),
              const SizedBox(width: 10),
              Expanded(child: box(86)),
            ]),
            const SizedBox(height: 16),
            box(40), // ladder
            const SizedBox(height: 20),
            box(180, r: 14), // action card
            const SizedBox(height: 20),
            box(20, w: 120, r: 6),
            const SizedBox(height: 12),
            box(16, w: 220, r: 6),
            const SizedBox(height: 10),
            box(16, w: 200, r: 6),
          ],
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                color: VendorTheme.textMuted, size: 44),
            const SizedBox(height: 14),
            Text('Couldn’t load your trust status',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: VendorTheme.textMuted, fontSize: 12.5)),
            const SizedBox(height: 18),
            SizedBox(
              width: 160,
              child: VButton(label: 'Retry', onTap: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}