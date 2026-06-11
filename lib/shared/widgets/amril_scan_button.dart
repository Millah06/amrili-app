// lib/shared/widgets/amril_scan_button.dart
//
// PHASE 8 — Branded scan affordance
//
// A reusable, on-brand "scan" button to drop anywhere a plain `Icon(Icons.…)`
// would otherwise look generic (Stores tab header, feed header, profile, etc.).
//
// Design intent
// ─────────────
// Instead of a flat icon, this draws a miniature *viewfinder*: four rounded
// corner brackets framing an animated scan line that sweeps top↕bottom. That
// motif reads instantly as "scan / QR" and gives the app a small, distinctive
// signature using the existing palette — cyan `VendorTheme.primary` brackets on
// a dark `surface→surfaceVariant` chip with a soft cyan glow.
//
// Everything is painted with a `CustomPainter` (no asset, no extra package), so
// it scales crisply at any `size` and tints from the theme.
//
// Usage
// ─────
//   AmrilScanButton(onTap: () => context.push('/scan'))         // 46px default
//   AmrilScanButton(size: 32, onTap: openScanner)               // inline / compact
//   AmrilScanButton(animate: false, onTap: ...)                 // static (lists)
//
// NOTE: `onTap` is intentionally left for the caller to wire to the scanner
// route — the widget owns presentation only.

import 'package:flutter/material.dart';
import 'package:everywhere/constraints/vendor_theme.dart';

class AmrilScanButton extends StatefulWidget {
  /// Edge length of the (square) button. Default 46 — a comfortable 44+ tap target.
  final double size;

  /// Tap handler. Leave null to wire later (the button still ripples).
  final VoidCallback? onTap;

  /// When false, the scan line holds still — use in long lists to avoid many
  /// simultaneous ticking animations. Default true.
  final bool animate;

  /// Accessibility / long-press label.
  final String tooltip;

  const AmrilScanButton({
    super.key,
    this.size = 46,
    this.onTap,
    this.animate = true,
    this.tooltip = 'Scan',
  });

  @override
  State<AmrilScanButton> createState() => _AmrilScanButtonState();
}

class _AmrilScanButtonState extends State<AmrilScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A gentle, continuous sweep. `reverse` makes it bounce up↕down rather than
    // snapping back to the top, which feels calmer.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AmrilScanButton old) {
    super.didUpdateWidget(old);
    // Respect runtime toggles of `animate`.
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.size * 0.30;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          // The chip: subtle vertical gradient + cyan hairline border + soft glow.
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [VendorTheme.surface, VendorTheme.surfaceVariant],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: VendorTheme.primary.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: VendorTheme.primary.withOpacity(0.22),
                  blurRadius: 12,
                  spreadRadius: -3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // Material + InkWell give a themed ripple clipped to the rounded chip.
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                splashColor: VendorTheme.primary.withOpacity(0.18),
                highlightColor: VendorTheme.primary.withOpacity(0.08),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => CustomPaint(
                    painter: _ViewfinderPainter(
                      progress: widget.animate ? _controller.value : 0.5,
                      bracketColor: VendorTheme.primary,
                      lineColor: VendorTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the viewfinder: four rounded L-brackets + a sweeping scan line.
class _ViewfinderPainter extends CustomPainter {
  /// 0..1 — vertical position of the scan line between the top and bottom insets.
  final double progress;
  final Color bracketColor;
  final Color lineColor;

  _ViewfinderPainter({
    required this.progress,
    required this.bracketColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final inset = w * 0.24; // distance of the frame from the chip edge
    final len = w * 0.18; // length of each bracket arm
    final r = w * 0.07; // bracket corner radius

    final bracket = Paint()
      ..color = bracketColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final left = inset;
    final right = w - inset;
    final top = inset;
    final bottom = size.height - inset;

    // Top-left ┌
    canvas.drawPath(
      Path()
        ..moveTo(left, top + len)
        ..lineTo(left, top + r)
        ..arcToPoint(Offset(left + r, top), radius: Radius.circular(r))
        ..lineTo(left + len, top),
      bracket,
    );
    // Top-right ┐
    canvas.drawPath(
      Path()
        ..moveTo(right - len, top)
        ..lineTo(right - r, top)
        ..arcToPoint(Offset(right, top + r), radius: Radius.circular(r))
        ..lineTo(right, top + len),
      bracket,
    );
    // Bottom-right ┘
    canvas.drawPath(
      Path()
        ..moveTo(right, bottom - len)
        ..lineTo(right, bottom - r)
        ..arcToPoint(Offset(right - r, bottom), radius: Radius.circular(r))
        ..lineTo(right - len, bottom),
      bracket,
    );
    // Bottom-left └
    canvas.drawPath(
      Path()
        ..moveTo(left + len, bottom)
        ..lineTo(left + r, bottom)
        ..arcToPoint(Offset(left, bottom - r), radius: Radius.circular(r))
        ..lineTo(left, bottom - len),
      bracket,
    );

    // Scan line — a soft cyan gradient bar, brightest in the middle, sweeping
    // between the brackets. A faint glow sits under it for depth.
    final travelTop = top + len * 0.35;
    final travelBottom = bottom - len * 0.35;
    final y = travelTop + (travelBottom - travelTop) * progress;
    final lineRect = Rect.fromLTWH(left + w * 0.02, y - 1, right - left - w * 0.04, 2);

    final glow = Paint()
      ..color = lineColor.withOpacity(0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect.inflate(1.5), const Radius.circular(2)),
      glow,
    );

    final line = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withOpacity(0.0),
          lineColor,
          lineColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(lineRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter old) =>
      old.progress != progress ||
          old.bracketColor != bracketColor ||
          old.lineColor != lineColor;
}