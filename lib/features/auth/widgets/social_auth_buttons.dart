import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/bootom_bar.dart';
import '../../../constraints/constants.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/session_service.dart';
import '../../../services/brain.dart';
import '../security_screen.dart';
import '../../marketPlace/widgets/shared_widgets.dart'; // for FlushBarMessage
import '../../../shared/utils/flush_bar_message.dart';
import '../../../screens/community_screen.dart';
import '../security_step1_screen.dart';
// ADD
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Renders Google + Apple (iOS) buttons, handles the full auth flow,
/// and calls [onAuthSuccess] with the result on completion.
class SocialAuthButtons extends StatefulWidget {
  /// Called after a successful auth. Use this to navigate / update session.
  final void Function(SocialAuthResult result)? onAuthSuccess;
  final EdgeInsets padding;

  const SocialAuthButtons({
    super.key,
    this.onAuthSuccess,
    this.padding = const EdgeInsets.symmetric(horizontal: 15),
  });

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  bool _loading = false;

  Future<void> _handleAuth(
      Future<SocialAuthResult> Function() authFn,
      BuildContext context,
      ) async {
    setState(() => _loading = true);
    try {
      final authProvider =  context.read<AuthProvider>();
      final result = await authFn();
      if (!mounted) return;

      context.read<SessionProvider>().login(result.uid);

      context.read<UserProvider>()
          .seedFromAuth(authProvider.authUserData!);

     authProvider.exitGuest();

      FlushBarMessage.showFlushBar(
        context: context,
        message: result.isNewUser ? 'Welcome to Amril!' : 'Welcome back!',
        title: 'Success',
      );

      widget.onAuthSuccess?.call(result);

      if (result.isNewUser) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SecurityStep1Screen()), // ← updated
        );
      } else {

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSetupDone', true);

        await Brain().getData();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const BottomBar()),
              (r) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (!msg.contains('cancelled')) {
        FlushBarMessage.showFlushBar(
          context: context,
          message: 'Sign-in failed. Please try again.',
          title: 'Error',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: kButtonColor),
        ),
      );
    }

    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          // Google
          _SocialAuthButton(
            label: 'Continue with Google',
            icon: Image.asset('images/google.png', height: 20,),
            onTap: () => _handleAuth(
                  () => context.read<AuthProvider>().signInWithGoogle(),
              context,
            ),
          ),
          // Apple — iOS only
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS)) ...[
            const SizedBox(height: 12),
            _SocialAuthButton(
              label: 'Continue with Apple',
              icon: Image.asset('images/apple.png', height: 20,),
              backgroundColor: Colors.white12,
              onTap: () => _handleAuth(
                    () => context.read<AuthProvider>().signInWithApple(),
                context,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.backgroundColor = const Color(0xFF1E293B),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 26, child: icon),
            const SizedBox(width: 12),
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
    );
  }
}