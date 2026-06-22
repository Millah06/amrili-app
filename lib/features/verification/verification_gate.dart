// lib/features/verification/verification_gate.dart
//
// PHASE 13 — The gate (cache-backed).
// ─────────────────────────────────────────────────────────────────────────────
// Reads the cached verified flag (VerificationCache) — NO network call per tap.
// If verified, proceed. If not, show a friendly sheet → KYC screen; the KYC
// screen writes the cache on success, so on return the flag is already true.
//
//     if (!await VerificationGate.ensureVerified(context, reason: 'to add products')) {
//       return; // not verified — the gate already showed the KYC path
//     }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:everywhere/constraints/vendor_theme.dart';
import 'package:everywhere/features/verification/kyc_verification_screen.dart';
import 'package:everywhere/features/verification/verification_cache.dart';

class VerificationGate {


  static void ensureVerified(
      BuildContext context, {
        String reason = 'to continue',
        required VoidCallback action,
      }

      ) async {

    bool isVerified = await VerificationCache.isVerified();

    if (isVerified) {
      action();
    }
    else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: const BoxConstraints(maxWidth: 480),
        builder: (_) => _GateSheet(reason: reason),
      );

    }



    // 2. Not verified → gate sheet → KYC. Returns true only if they verified.


  }
}

class _GateSheet extends StatelessWidget {
  final String reason;
  const _GateSheet({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 18, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF21D3ED).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.shieldHalved,
                color: Color(0xFF21D3ED), size: 26),
          ),
          const SizedBox(height: 18),
          Text('Verify your identity $reason',
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  height: 1.3)),
          const SizedBox(height: 8),
          Text(
            'A one-time check with your BVN or NIN. It takes a few seconds and '
                'unlocks cash-out, selling, and your verified status.',
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: const Color(0xFF21D3ED),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final ok = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                        builder: (_) => const KycVerificationScreen()),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(ok == true);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Text('Verify now',
                        style: GoogleFonts.inter(
                            color: const Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Not now',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textSecondary, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}