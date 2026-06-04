import 'package:flutter/foundation.dart';
import 'package:everywhere/core/constant/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constraints/constants.dart';
import '../../core/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/security_step1_screen.dart';
import '../../providers/user_provider.dart';
import '../../services/session_service.dart';
// ADD
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AuthGateBottomSheet {
  static void show(BuildContext context, {String reason = 'do that'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthGateSheet(reason: reason),
    );
  }
}

class _AuthGateSheet extends StatefulWidget {
  final String reason;
  const _AuthGateSheet({required this.reason});

  @override
  State<_AuthGateSheet> createState() => _AuthGateSheetState();
}

class _AuthGateSheetState extends State<_AuthGateSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _handleSocialAuth(
      Future<SocialAuthResult> Function() authFn,
      ) async {
    setState(() { _loading = true; _error = null; });
    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authFn();
      if (!mounted) return;

      // Update session
      context.read<SessionProvider>().login(result.uid);

      context.read<UserProvider>()
          .seedFromAuth(authProvider.authUserData!);

      authProvider.exitGuest();

      Navigator.pop(context); // Close sheet


      if (result.isNewUser) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SecurityStep1Screen()), // ← updated
        );
      } else {

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSetupDone', true);
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled')) {
        setState(() { _loading = false; });
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Sign-in failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 28),
          // Lock icon with glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kButtonColor.withOpacity(0.12),
              border: Border.all(color: kButtonColor.withOpacity(0.3), width: 1.5),
            ),
            child: const Icon(Icons.lock_outline_rounded,
                color: kButtonColor, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            'Join to unlock',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a free account to ${widget.reason} and\naccess everything ${AppConstants.appName} has to offer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!,
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 28),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(color: kButtonColor),
            )
          else ...[
            // Google
            _SocialButton(
              label: 'Continue with Google',
              icon:   Image.asset('images/google.png', height: 20,),
              onTap: () => _handleSocialAuth(
                    () => context.read<AuthProvider>().signInWithGoogle(),
              ),
            ),
            // Apple — iOS only
            if (!kIsWeb &&
                (defaultTargetPlatform == TargetPlatform.iOS ||
                    defaultTargetPlatform == TargetPlatform.macOS)) ...[
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Continue with Apple',
                icon: Image.asset('images/apple.png', height: 20,),
                backgroundColor: Colors.white10,
                onTap: () => _handleSocialAuth(
                      () => context.read<AuthProvider>().signInWithApple(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Email
            _SocialButton(
              label: 'Continue with Email',
              icon: const Icon(Icons.email_outlined, color: Colors.white70, size: 20),
              backgroundColor: Colors.white.withOpacity(0.06),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
          const SizedBox(height: 18),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              'Maybe later',
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Internal helpers ───────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor = const Color(0xFF334155),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            child: Row(
              children: [
                SizedBox(width: 28, child: icon),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
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

/// Minimal Google "G" logo rendered with colored text (no asset needed).
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}