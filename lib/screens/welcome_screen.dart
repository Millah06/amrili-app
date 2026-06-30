// lib/screens/welcome_screen.dart
//
// Amril welcome / entry screen. Replaces the old VTU-styled screen. Premium,
// wedge-first (dine-in → social → gifting → marketplace), on the brand.
//
// NAVIGATION CONTRACT — UNCHANGED from the previous welcome screen:
//   • Create account  → SignUpScreen
//   • Sign in         → LoginScreen
//   • Continue guest  → context.read<AuthProvider>().continueAsGuest()
//                       then pushAndRemoveUntil(BottomBar)
//   • static const id = 'welcome'  (GoRouter '/welcome' depends on this)
//
// ⬇ VERIFY THESE IMPORTS against your current welcome_screen.dart and keep your
//   real paths. Every symbol below was already used by the old screen except
//   AmrilMark (new) and LegalDocumentPage (from the legal batch).
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // TapGestureRecognizer (legal links)
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:everywhere/features/auth/login_screen.dart';
import 'package:everywhere/features/auth/signup_screen.dart';
import 'package:everywhere/shared/widgets/amril_mark.dart';
import 'package:everywhere/features/legal/legal_document_page.dart';

import '../components/bottom_bar.dart';
import '../constraints/constants.dart';
import '../core/auth/auth_provider.dart' show AuthProvider;

class WelcomeScreen extends StatefulWidget {
  static const id = 'welcome';
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ── Navigation handlers (unchanged behaviour) ──────────────────────────────
  void _createAccount() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const SignUpScreen()));

  void _signIn() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const LoginScreen()));

  void _continueAsGuest() {
    context.read<AuthProvider>().continueAsGuest();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomBar()),
          (r) => false,
    );
  }

  void _openLegal(String slug) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => LegalDocumentPage.of(slug)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Brand canvas: navy gradient + cyan ambient glow top-right.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF13203A), Color(0xFF0F172A), Color(0xFF0A1020)],
          ),
        ),
        child: CustomPaint(
          painter: _GlowDotsPainter(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Brand row ──────────────────────────────────────────
                      Row(
                        children: [
                          const AmrilMark(size: 40),
                          const SizedBox(width: 10),
                          Text.rich(
                            TextSpan(
                              text: 'Amril',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                              children: const [
                                TextSpan(text: '.',
                                    style: TextStyle(color: Color(0xFF21D3ED))),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // ── Hero copy (wedge-first) ────────────────────────────
                      Text(
                        'Your favourite places,\nin one app.',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 34,
                          height: 1.12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scan to order at the table, follow and message the '
                            'spots you love, gift the creators you back, and shop '
                            'local — all in Amril.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFAFBDD4),
                          fontSize: 15.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Value pills ────────────────────────────────────────
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: const [
                          _Pill('QR dine-in'),
                          _Pill('Social feed'),
                          _Pill('Gifting'),
                          _Pill('Marketplace'),
                        ],
                      ),

                      const Spacer(flex: 2),

                      // ── Actions ────────────────────────────────────────────
                      // Primary: get started (new users → sign up).
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _createAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kButtonColor,
                            foregroundColor: const Color(0xFF06131C),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('Get started',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Secondary: returning users → sign in.
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _signIn,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.18)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('I already have an account',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Tertiary: browse as guest.
                      Center(
                        child: GestureDetector(
                          onTap: _continueAsGuest,
                          behavior: HitTestBehavior.opaque,
                          child: Text.rich(
                            TextSpan(
                              text: 'Continue as guest  ',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8597B0),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                              children: const [
                                TextSpan(text: '→',
                                    style: TextStyle(color: Color(0xFF21D3ED))),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Legal line ─────────────────────────────────────────
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'By continuing, you agree to our ',
                            style: GoogleFonts.inter(
                                color: const Color(0xFF64748B), fontSize: 12, height: 1.5),
                            children: [
                              _legalLink('Terms', 'terms'),
                              const TextSpan(text: ' and '),
                              _legalLink('Privacy Policy', 'privacy'),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A tappable inline legal link inside the agreement line.
  TextSpan _legalLink(String label, String slug) => TextSpan(
    text: label,
    style: const TextStyle(
        color: Color(0xFF21D3ED), fontWeight: FontWeight.w600),
    recognizer: (TapGestureRecognizer()..onTap = () => _openLegal(slug)),
  );
}

// Small rounded value chip.
class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// Background: faint dot-grid + a soft cyan glow, matching the splash/brand.
class _GlowDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ambient glow top-right
    canvas.drawCircle(
      Offset(size.width * 0.92, size.height * 0.08),
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF21D3ED).withOpacity(0.16),
            const Color(0xFF21D3ED).withOpacity(0.0),
          ],
        ).createShader(Rect.fromCircle(
            center: Offset(size.width * 0.92, size.height * 0.08),
            radius: size.width * 0.5)),
    );
    // dot grid
    final p = Paint()..color = const Color(0xFF7CEEFF).withOpacity(0.045);
    const gap = 26.0;
    for (double y = gap; y < size.height; y += gap) {
      for (double x = gap; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(_GlowDotsPainter oldDelegate) => false;
}