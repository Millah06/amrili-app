// lib/features/marketPlace/pages/qr_scanner_screen.dart
//
// PHASE 2 — QR SYSTEM
//
// The in-app scanner (the "Scan" buttons in Services/Chats were TODOs). Uses the
// existing `mobile_scanner` dependency. On a detected code:
//   • parse the raw value as a URI,
//   • if it's an amril.app link we recognise, pop the scanner and `context.go`
//     to the matching route (store / product / table),
//   • otherwise show a friendly snackbar — never crash, never navigate blindly.
//
// Routing goes through GoRouter (same as DeepLinkService), so a scanned link
// behaves identically to one opened from outside the app.
//
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../constraints/vendor_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();

  // Guards against the scanner firing onDetect repeatedly for the same frame.
  bool _handled = false;

  /// Hosts we own. A scanned link must match to be routed in-app.
  static const Set<String> _ownHosts = {'amril.app', 'www.amril.app'};

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    final uri = Uri.tryParse(raw);
    final isOurs = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        _ownHosts.contains(uri.host) &&
        _matches(uri.path);

    if (!isOurs) {
      // Not an Amril link — tell the user, keep scanning.
      _snack('That doesn’t look like an Amril code.');
      return;
    }

    _handled = true;
    final location = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    // Close the scanner first, then route on top of whatever was underneath.
    if (context.canPop()) context.pop();
    context.go(location);
  }

  // Accept only the deep-link shapes we actually route.
  bool _matches(String path) {
    return RegExp(r'^/store/[^/]+(/table/[^/]+)?$').hasMatch(path) ||
        RegExp(r'^/product/[^/]+$').hasMatch(path);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VendorTheme.surface),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // mobile_scanner on web needs a different setup (handled in the Phase 3
    // kIsWeb audit). Degrade gracefully rather than crash.
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: VendorTheme.background,
        appBar: AppBar(title: const Text('Scan')),
        body: Center(
          child: Text('Scanning isn’t available on web.',
              style: GoogleFonts.inter(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Scan QR',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Simple viewfinder overlay so the user knows where to aim.
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: VendorTheme.primary, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 32,
            right: 32,
            child: Text(
              'Point at an Amril store, product or table QR',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}