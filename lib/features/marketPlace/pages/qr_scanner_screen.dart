// lib/features/marketPlace/pages/qr_scanner_screen.dart
//
// PHASE 2 — QR SCANNER (updated)
//
// Adds: pinch-to-zoom + a zoom slider, "scan from gallery", and haptic + sound
// feedback the moment a code is detected. Still routes only recognised
// amril.app store/product/table links through GoRouter; anything else gets a
// friendly snackbar. kIsWeb degrades gracefully.
//
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback + SystemSound
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../constraints/vendor_theme.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  static const Set<String> _ownHosts = {'amril.app', 'www.amril.app'};

  bool _handled = false;       // stop routing twice for the same valid code
  double _zoom = 0.0;          // 0..1 zoom scale
  double _zoomBase = 0.0;      // zoom at the start of a pinch gesture

  // Debounce so we don't buzz on every camera frame for the same code.
  String? _lastRaw;
  DateTime _lastFeedback = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Detection ───────────────────────────────────────────────────────────
  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    // Feedback once per distinct code (or after a short gap) — the "hit" buzz.
    final now = DateTime.now();
    final isNewCode =
        raw != _lastRaw || now.difference(_lastFeedback).inMilliseconds > 1500;
    if (isNewCode) {
      _lastRaw = raw;
      _lastFeedback = now;
      _feedbackHit();
    }

    final uri = Uri.tryParse(raw);
    final isOurs = uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        _ownHosts.contains(uri.host) &&
        _matches(uri.path);

    if (!isOurs) {
      if (isNewCode) _snack('That does not look like an Amril code.');
      return;
    }

    _handled = true;
    final location = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    if (context.canPop()) context.pop();
    context.go(location);
  }

  // Haptic + short system click when a code is hit.
  void _feedbackHit() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  bool _matches(String path) {
    return RegExp(r'^/store/[^/]+(/table/[^/]+)?$').hasMatch(path) ||
        RegExp(r'^/product/[^/]+$').hasMatch(path);
  }

  // ── Zoom ──────────────────────────────────────────────────────────────────
  void _setZoom(double value) {
    final z = value.clamp(0.0, 1.0);
    setState(() => _zoom = z);
    _controller.setZoomScale(z);
  }

  // ── Scan from gallery ───────────────────────────────────────────────────
  Future<void> _scanFromGallery() async {
    try {
      final XFile? file =
      await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;

      // mobile_scanner >=5: analyzeImage returns a BarcodeCapture? we can feed
      // straight into the same handler. (On older versions analyzeImage returns
      // bool and fires onDetect instead - tell me your version if so.)
      final BarcodeCapture? result = await _controller.analyzeImage(file.path);
      if (result != null && result.barcodes.isNotEmpty) {
        _onDetect(result);
      } else {
        _snack('No QR code found in that image.');
      }
    } catch (_) {
      _snack('Could not scan that image.');
    }
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
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: VendorTheme.background,
        appBar: AppBar(title: const Text('Scan')),
        body: Center(
          child: Text('Scanning is not available on web.',
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
            tooltip: 'Torch',
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera',
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Pinch-to-zoom wraps the live camera. onScaleUpdate maps the gesture
          // scale onto the 0..1 zoom range with a gentle sensitivity.
          GestureDetector(
            onScaleStart: (_) => _zoomBase = _zoom,
            onScaleUpdate: (details) {
              if (details.scale == 1.0) return; // pure pan, ignore
              _setZoom(_zoomBase + (details.scale - 1.0) * 0.5);
            },
            child: MobileScanner(controller: _controller, onDetect: _onDetect),
          ),

          // Viewfinder
          IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: VendorTheme.primary, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            top: 24,
            left: 32,
            right: 32,
            child: IgnorePointer(
              child: Text(
                'Point at an Amril store, product or table QR - or pinch to zoom',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13.5, height: 1.4),
              ),
            ),
          ),

          // Bottom controls: zoom slider + gallery button.
          Positioned(
            bottom: 28,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                    Expanded(
                      child: Slider(
                        value: _zoom,
                        activeColor: VendorTheme.primary,
                        inactiveColor: Colors.white24,
                        onChanged: _setZoom,
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VendorTheme.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.photo_library_outlined,
                        color: Colors.white, size: 20),
                    label: Text('Scan from gallery',
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    onPressed: _scanFromGallery,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}