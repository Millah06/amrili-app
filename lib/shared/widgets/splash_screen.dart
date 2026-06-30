// lib/shared/widgets/splash_screen.dart
//
// Amril splash — the brand reveal shown while providers warm up (app.dart shows
// it during _isLoading / loadingUser). It performs NO navigation; app.dart swaps
// to the router when loading finishes. Replaces the old utility-styled splash.
//
// Visual: deep-navy canvas with a faint QR-module dot-grid, the animated Node-A
// mark, the "Amril." wordmark, and a quiet tagline — premium, calm, on-brand.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'amril_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _wordFade;   // wordmark fades + rises
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _tagFade;     // tagline fades in last

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Wordmark enters after the mark has mostly drawn (0.45 → 0.8).
    _wordFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    );
    _wordSlide = Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _c,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    // Tagline last (0.7 → 1.0).
    _tagFade = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Rich navy gradient, slightly brighter at top for depth.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF13203A), Color(0xFF0F172A), Color(0xFF0A1020)],
          ),
        ),
        child: CustomPaint(
          painter: _DotGridPainter(),       // faint QR-module texture
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated logomark.
                const AmrilMark(size: 116),
                const SizedBox(height: 26),
                // Wordmark "Amril." with the cyan signature dot.
                SlideTransition(
                  position: _wordSlide,
                  child: FadeTransition(
                    opacity: _wordFade,
                    child: Text.rich(
                      TextSpan(
                        text: 'Amril',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        children: const [
                          TextSpan(text: '.', style: TextStyle(color: Color(0xFF21D3ED))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tagline.
                FadeTransition(
                  opacity: _tagFade,
                  child: Text(
                    'Order · Connect · Gift',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8597B0),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Faint dot grid echoing the QR-module motif from the brand. Very low opacity
// so it reads as texture, never as content.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF7CEEFF).withOpacity(0.05);
    const gap = 26.0;
    for (double y = gap; y < size.height; y += gap) {
      for (double x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}