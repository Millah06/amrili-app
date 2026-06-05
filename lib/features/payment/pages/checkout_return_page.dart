// lib/features/payment/pages/checkout_return_page.dart
//
// Landing page for the OPay return URL (https://amril.app/checkout-success).
//
// When OPay finishes, it sends the browser/app to this URL. On mobile that's a
// universal/app link that re-opens Amril at `/checkout-success`; on web it's a
// normal page load. Either way we DO NOT trust the redirect — we look up the
// user's in-flight payment and let the PaymentSheet verify it with the backend
// (which is the source of truth), then return the user home.
//
// This makes the return path "complete": even if the user paid in the OPay app
// and tapped a return link instead of swiping back, they land here, see
// "Verifying…", and get the real result.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/payment_service.dart';
import '../widgets/payment_sheet.dart';

class CheckoutReturnPage extends StatefulWidget {
  const CheckoutReturnPage({super.key});
  @override
  State<CheckoutReturnPage> createState() => _CheckoutReturnPageState();
}

class _CheckoutReturnPageState extends State<CheckoutReturnPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    try {
      final pending = await PaymentService.instance.pending();
      if (!mounted) return;
      if (pending.isNotEmpty) {
        final p = pending.first;
        // Re-open the sheet straight into verification; backend confirms.
        await PaymentSheet.show(
          context,
          amount: p.amount,
          entityType: p.entityType,
          entityId: p.entityId,
          recoverPaymentId: p.paymentId,
        );
      }
    } catch (_) {
      // Network hiccup — the recovery cron still finishes it server-side.
    } finally {
      if (mounted) context.go('/'); // never strand the user on this page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF21D3ED), strokeWidth: 3),
            const SizedBox(height: 18),
            Text('Finishing up…',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}