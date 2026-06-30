// lib/shared/widgets/amril_mark.dart
//
// The Amril "Node A" logomark, drawn in pure Flutter (no flutter_svg needed).
// Two ascending legs + an offset crossbar converging at a glowing cyan dot —
// the same mark as the app icon / web logo, rebuilt as a CustomPainter so we
// can animate it: the strokes draw themselves in, and the dot keeps a gentle
// glow pulse so it stays alive even on a slow cold-start.
//
// Use:
//   const AmrilMark(size: 120)                 // animated entrance + idle pulse
//   const AmrilMark(size: 64, animate: false)  // static (e.g. in a row/header)

import 'dart:math' as math;
import 'package:flutter/material.dart';

class AmrilMark extends StatefulWidget {
  final double size;
  final bool animate;
  const AmrilMark({super.key, this.size = 120, this.animate = true});

  @override
  State<AmrilMark> createState() => _AmrilMarkState();
}

class _AmrilMarkState extends State<AmrilMark> with TickerProviderStateMixin {
  late final AnimationController _draw;   // one-shot: strokes draw in + dot pops
  late final AnimationController _pulse;  // looping: dot glow breathing

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) {
      _draw.forward();
      _pulse.repeat(reverse: true);
    } else {
      _draw.value = 1.0; // fully drawn, no motion
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_draw, _pulse]),
        builder: (_, __) {
          // Strokes finish drawing over the first ~80% of the timeline…
          final drawT = Curves.easeOutCubic.transform(_draw.value.clamp(0, 1));
          // …the dot fades/scales in over the last stretch.
          final dotT = Curves.easeOutBack
              .transform(((_draw.value - 0.55) / 0.45).clamp(0, 1));
          // Idle glow breathing (only meaningful once drawn).
          final glow = widget.animate
              ? (0.6 + 0.4 * math.sin(_pulse.value * math.pi))
              : 0.85;
          return CustomPaint(
            painter: _AmrilMarkPainter(drawT: drawT, dotT: dotT, glow: glow),
          );
        },
      ),
    );
  }
}

class _AmrilMarkPainter extends CustomPainter {
  final double drawT; // 0..1 stroke draw progress
  final double dotT;  // 0..1 dot appearance
  final double glow;  // 0..1 glow intensity
  _AmrilMarkPainter({required this.drawT, required this.dotT, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    // Work in a 100×100 design space, then scale to the widget size.
    final s = size.width / 100.0;
    canvas.save();
    canvas.scale(s, s);

    // Cyan→teal gradient shared by all three strokes.
    final rect = const Rect.fromLTWH(20, 16, 60, 74);
    final shader = const LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [Color(0xFF177E85), Color(0xFF21D3ED), Color(0xFF7CEEFF)],
      stops: [0.0, 0.6, 1.0],
    ).createShader(rect);

    final stroke = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // The three strokes of the A as separate sub-paths.
    final path = Path()
      ..moveTo(24, 86)..lineTo(47, 30)   // left leg
      ..moveTo(76, 86)..lineTo(53, 30)   // right leg
      ..moveTo(36, 62)..lineTo(64, 62);  // offset crossbar

    // Draw each sub-path up to drawT of its length, so they "grow" in.
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * drawT), stroke);
    }

    // The signature dot at the apex, with a soft glow halo.
    if (dotT > 0) {
      const center = Offset(50, 18);
      final r = 9.0 * dotT;
      // halo
      canvas.drawCircle(
        center,
        r + 7 * glow,
        Paint()
          ..color = const Color(0xFF21D3ED).withOpacity(0.30 * glow * dotT)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // core
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFFD6FAFF), Color(0xFF21D3ED), Color(0xFF0FB8D4)],
            stops: [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmrilMarkPainter old) =>
      old.drawT != drawT || old.dotT != dotT || old.glow != glow;
}