// lib/features/marketPlace/pages/qr_scanner_screen.dart
//
// PHASE 2 — QR SCANNER (Phase 8 visual polish)
//
// Functionality is unchanged from the previous version: pinch-to-zoom + slider,
// "scan from gallery", torch, camera flip, and haptic + sound feedback on a hit.
// Only recognised amril.app store/product/table links route through GoRouter;
// anything else gets a friendly snackbar. kIsWeb degrades gracefully.
//
// What changed is the chrome: a dimmed scrim with a rounded viewfinder cut-out,
// animated cyan corner brackets + a sweeping scan line (the same visual language
// as AmrilScanButton), and frosted-glass controls — so it reads as a deliberate,
// branded surface rather than a bare camera with a box on top.
//
import 'dart:ui' show ImageFilter;

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

  bool _handled = false; // stop routing twice for the same valid code
  bool _torchOn = false; // mirror torch state for the button icon
  double _zoom = 0.0; // 0..1 zoom scale
  double _zoomBase = 0.0; // zoom at the start of a pinch gesture

  // Debounce so we don't buzz on every camera frame for the same code.
  String? _lastRaw;
  DateTime _lastFeedback = DateTime.fromMillisecondsSinceEpoch(0);

  // ── Detection ─────────────────────────────────────────────────────────────
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
      if (isNewCode) _snack('That doesn’t look like an Amril code.');
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
        RegExp(r'^/product/[^/]+$').hasMatch(path) ||
        RegExp(r'^/chat-user/[^/]+$').hasMatch(path);
  }

  // ── Zoom ────────────────────────────────────────────────────────────────────
  void _setZoom(double value) {
    final z = value.clamp(0.0, 1.0);
    setState(() => _zoom = z);
    _controller.setZoomScale(z);
  }

  void _toggleTorch() {
    _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  // ── Scan from gallery ───────────────────────────────────────────────────────
  Future<void> _scanFromGallery() async {
    try {
      final XFile? file =
      await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final BarcodeCapture? result = await _controller.analyzeImage(file.path);
      if (result != null && result.barcodes.isNotEmpty) {
        _onDetect(result);
      } else {
        // A too-large centre logo overruns the QR's error correction and a single
        // still can't be decoded (live scanning is more forgiving). The fix lives
        // in the generator: High EC + logo ≤ ~25%.
        _snack('No QR code found — try the live camera, or a clearer image.');
      }
    } catch (_) {
      _snack('Could not scan that image.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: VendorTheme.surface,
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _webFallback();

    final media = MediaQuery.of(context).size;
    // Viewfinder geometry — computed once here and shared with the overlay
    // painter and the positioned UI so everything lines up exactly.
    final side = (media.width * 0.72).clamp(220.0, 320.0);
    final center = Offset(media.width / 2, media.height * 0.40);
    final window = Rect.fromCenter(center: center, width: side, height: side);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Live camera (pinch-to-zoom) ───────────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onScaleStart: (_) => _zoomBase = _zoom,
              onScaleUpdate: (d) {
                if (d.scale == 1.0) return; // pure pan, ignore
                _setZoom(_zoomBase + (d.scale - 1.0) * 0.5);
              },
              child:
              MobileScanner(controller: _controller, onDetect: _onDetect),
            ),
          ),

          // ── Scrim + viewfinder + brackets + scan line ─────────────────────
          Positioned.fill(
            child: IgnorePointer(child: _ScannerOverlay(window: window)),
          ),

          // ── Instruction pill (just above the window) ──────────────────────
          Positioned(
            left: 24,
            right: 24,
            top: window.top - 64,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Point at an Amril store, product, table or chat QR',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3),
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar: back · title · torch ─────────────────────────────────
          // NOTE: must be Positioned. A non-positioned child would make the
          // Stack shrink to its height and collapse the fills to the top.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () =>
                      context.canPop() ? context.pop() : null,
                    ),
                    const SizedBox(width: 4),
                    Text('Scan',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.white)),
                    const Spacer(),
                    _circleButton(
                      icon: _torchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      tooltip: 'Torch',
                      active: _torchOn,
                      onTap: _toggleTorch,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom frosted control panel: zoom · gallery · flip ───────────
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(22),
                      border:
                      Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Zoom
                        Row(
                          children: [
                            const Icon(Icons.zoom_out_rounded,
                                color: Colors.white70, size: 20),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 16),
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7),
                                ),
                                child: Slider(
                                  value: _zoom,
                                  activeColor: VendorTheme.primary,
                                  inactiveColor: Colors.white24,
                                  onChanged: _setZoom,
                                ),
                              ),
                            ),
                            const Icon(Icons.zoom_in_rounded,
                                color: Colors.white70, size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Gallery (primary) + flip
                        Row(
                          children: [
                            Expanded(
                              child: Material(
                                color: VendorTheme.primary,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _scanFromGallery,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                            Icons.photo_library_outlined,
                                            color: VendorTheme.background,
                                            size: 19),
                                        const SizedBox(width: 8),
                                        Text('Scan from gallery',
                                            style: GoogleFonts.inter(
                                                color: VendorTheme.background,
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _circleButton(
                              icon: Icons.cameraswitch_rounded,
                              tooltip: 'Switch camera',
                              filled: true,
                              onTap: () => _controller.switchCamera(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A circular frosted (or filled) icon button used across the chrome.
  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
    bool filled = false,
  }) {
    final bg = filled
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.35);
    final fg = active ? VendorTheme.primary : Colors.white;
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, color: fg, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webFallback() {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('Scan',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_scanner_rounded,
                  size: 56, color: VendorTheme.primary.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text('Scanning isn’t available on web',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      color: Colors.white70, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Overlay: scrim + viewfinder window + corner brackets + sweep line ────────
class _ScannerOverlay extends StatefulWidget {
  final Rect window;
  const _ScannerOverlay({required this.window});

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: Size.infinite,
        painter: _ScannerPainter(
          window: widget.window,
          progress: _c.value,
          accent: VendorTheme.primary,
        ),
      ),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  final Rect window;
  final double progress; // 0..1 scan-line position
  final Color accent;

  _ScannerPainter({
    required this.window,
    required this.progress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rWindow =
    RRect.fromRectAndRadius(window, const Radius.circular(26));

    // Dimmed scrim everywhere EXCEPT the viewfinder window (even-odd punches it).
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rWindow);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withOpacity(0.62));

    // Faint window edge.
    canvas.drawRRect(
      rWindow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withOpacity(0.12),
    );

    // Corner brackets (the AmrilScanButton motif, scaled up).
    final arm = window.width * 0.10;
    final r = 14.0;
    final bracket = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final l = window.left, t = window.top, rt = window.right, b = window.bottom;
    // ┌
    canvas.drawPath(
      Path()
        ..moveTo(l, t + arm)
        ..lineTo(l, t + r)
        ..arcToPoint(Offset(l + r, t), radius: Radius.circular(r))
        ..lineTo(l + arm, t),
      bracket,
    );
    // ┐
    canvas.drawPath(
      Path()
        ..moveTo(rt - arm, t)
        ..lineTo(rt - r, t)
        ..arcToPoint(Offset(rt, t + r), radius: Radius.circular(r))
        ..lineTo(rt, t + arm),
      bracket,
    );
    // ┘
    canvas.drawPath(
      Path()
        ..moveTo(rt, b - arm)
        ..lineTo(rt, b - r)
        ..arcToPoint(Offset(rt - r, b), radius: Radius.circular(r))
        ..lineTo(rt - arm, b),
      bracket,
    );
    // └
    canvas.drawPath(
      Path()
        ..moveTo(l + arm, b)
        ..lineTo(l + r, b)
        ..arcToPoint(Offset(l, b - r), radius: Radius.circular(r))
        ..lineTo(l, b - arm),
      bracket,
    );

    // Sweeping scan line, clipped to the window with a soft glow.
    canvas.save();
    canvas.clipRRect(rWindow);
    final pad = window.width * 0.06;
    final travelTop = t + arm * 0.6;
    final travelBottom = b - arm * 0.6;
    final y = travelTop + (travelBottom - travelTop) * progress;
    final lineRect =
    Rect.fromLTWH(l + pad, y - 1.5, window.width - pad * 2, 3);

    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect.inflate(2), const Radius.circular(3)),
      Paint()
        ..color = accent.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            accent.withOpacity(0.0),
            accent,
            accent.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(lineRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter old) =>
      old.progress != progress ||
          old.window != window ||
          old.accent != accent;
}