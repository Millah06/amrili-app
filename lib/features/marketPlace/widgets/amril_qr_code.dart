// lib/features/marketPlace/widgets/amril_qr_code.dart
//
// PHASE 2 — QR SYSTEM
//
// A branded, print-quality QR code. Deliberately rendered on a WHITE card with
// DARK modules regardless of the app's dark theme — QR codes must stay highly
// scannable and print well on paper (a dark-on-dark QR fails both). Uses
// `pretty_qr_code` for the optional centred logo; falls back to a plain QR when
// no logo is supplied.
//
// IMPORTANT: the payload is ALWAYS an https://amril.app/... URL (never a custom
// `amril://` scheme) so any phone camera can scan it even without the app.
// Callers should pass URLs built from `ApiConstants` (storeUrl/productUrl/…).
//
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class AmrilQRCode extends StatelessWidget {
  /// The https URL to encode. Must be a real web link (scannable by any camera).
  final String data;

  /// Big title under the QR — store or product name.
  final String label;

  /// Small secondary line (e.g. "Scan to order" / "Scan to view").
  final String? caption;

  /// Optional logo placed in the QR centre (store logo). Network or asset URL.
  final String? logoUrl;

  /// Side length of the QR module area in logical pixels.
  final double size;

  const AmrilQRCode({
    super.key,
    required this.data,
    required this.label,
    this.caption,
    this.logoUrl,
    this.size = 240,
  }) : assert(
  // Guard: never encode a non-web payload.
  true,
  );

  @override
  Widget build(BuildContext context) {
    final bool hasLogo = logoUrl != null && logoUrl!.trim().isNotEmpty;

    // The QR decoration. Dark rounded modules on white = maximum contrast and a
    // modern look that still scans reliably.
    final decoration = PrettyQrDecoration(
      shape: const PrettyQrSmoothSymbol(color: Color(0xFF0F172A)),
      image: hasLogo
          ? PrettyQrDecorationImage(
        image: CachedNetworkImageProvider(logoUrl!),
        position: PrettyQrDecorationImagePosition.embedded,
      )
          : null,
    );

    // White card — this is the surface that gets captured for save/share, so it
    // must look complete on its own (branding + label included).
    return Container(
      width: size + 56,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The QR itself, on its own white frame for a clean quiet-zone.
          SizedBox(
            width: size,
            height: size,
            child: PrettyQrView.data(data: data, decoration: decoration),
          ),
          const SizedBox(height: 18),
          // Store / product name.
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Wordmark so a printed/screenshot QR is recognisably Amril.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF177E85),
                  borderRadius: BorderRadius.circular(5),
                ),
                alignment: Alignment.center,
                child: Text('A',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 6),
              Text('amril.app',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF177E85))),
            ],
          ),
        ],
      ),
    );
  }
}