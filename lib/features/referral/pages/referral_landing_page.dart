// lib/features/referral/pages/referral_landing_page.dart
//
// PHASE 1 — FOUNDATION
//
// Destination for `amril.app/join/{referralCode}`. This is intentionally a
// presentation-only landing in Phase 1: it captures the referral code, shows a
// warm invitation, and routes the visitor into the sign-up flow. Persisting /
// redeeming the code against an account is a backend concern handled when the
// referral redemption endpoint lands — here we simply hold the code in memory
// and hand control to the welcome/auth surface.
//
// The folder `lib/features/referral/pages/` is new; it follows the existing
// `features/<area>/pages/` convention used across the app.
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';

class ReferralLandingPage extends StatelessWidget {
  final String referralCode;
  const ReferralLandingPage({super.key, required this.referralCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // Soft brand glow, echoing WelcomeScreen so the invite feels native.
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    kButtonColor.withOpacity(0.18),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Icon(Icons.card_giftcard_rounded,
                      size: 64, color: kButtonColor),
                  const SizedBox(height: 24),
                  Text('You’ve been invited to Amril',
                      style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.15)),
                  const SizedBox(height: 12),
                  Text(
                      'Payments, a marketplace, bills and more — all in one app. '
                          'Create an account to claim your invite.',
                      style: GoogleFonts.inter(
                          fontSize: 15, height: 1.55, color: Colors.white70)),
                  const SizedBox(height: 28),

                  // Code pill — tappable to copy, with light haptic feedback.
                  _CodePill(code: referralCode),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kButtonColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      // Phase 1: route into the existing welcome/auth flow.
                      // The captured `referralCode` is available to wire into
                      // sign-up when the redemption endpoint is added.
                      onPressed: () => context.go('/welcome'),
                      child: Text('Create my account',
                          style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      child: Text('Maybe later',
                          style: GoogleFonts.inter(
                              color: VendorTheme.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodePill extends StatelessWidget {
  final String code;
  const _CodePill({required this.code});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: code));
        HapticFeedback.selectionClick();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite code copied')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kButtonColor.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Text('Invite code',
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(code,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
            ),
            const Icon(Icons.copy_rounded, size: 18, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}