import 'package:everywhere/features/auth/widgets/auth_ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constraints/constants.dart';
import '../../screens/community_screen.dart';
import '../../services/api_service.dart';
import '../../services/brain.dart';
import '../../shared/utils/flush_bar_message.dart';
import '../auth/profile_picture.dart';

class SecurityStep2Screen extends StatefulWidget {
  const SecurityStep2Screen({super.key});

  @override
  State<SecurityStep2Screen> createState() => _SecurityStep2ScreenState();
}

class _SecurityStep2ScreenState extends State<SecurityStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _passcode1 = TextEditingController();
  final _passcode2 = TextEditingController();
  final _pin1 = TextEditingController();
  final _pin2 = TextEditingController();

  bool _obscureP1 = true, _obscureP2 = true;
  bool _obscurePin1 = true, _obscurePin2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _passcode1.dispose();
    _passcode2.dispose();
    _pin1.dispose();
    _pin2.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black.withOpacity(0.7),
      builder: (_) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kButtonColor),
          const SizedBox(height: 16),
          Text('Setting up your account...',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );

    try {
      // Save passcode locally (app re-open lock)
      final prefs = await SharedPreferences.getInstance();
      // await prefs.setString('loginPassCode', _passcode1.text);
      await prefs.setBool('isSetupDone', true);

      // Send transaction PIN to backend (hashed server-side)
      final api = ApiService();
      await api.post('/auth/set-pin', {'pin': _pin1.text});

      await Brain().getData();

      if (!mounted) return;
      Navigator.pop(context); // close bottom sheet

      // Profile picture — optional, shown for all new users
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const CommunityScreen(
            isLogInOut: true,
          ),
        ),
            (route) => false,
      );
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(builder: (_) => const ProfilePicture()),
      //       (route) => false,
      // );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close bottom sheet
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Something went wrong. Please try again.',
        title: 'Error',
        icon: const Icon(Icons.error_outline, color: kErrorIconColor, size: 28),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: BButton(onTap: () => Navigator.pop(context)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),

                      // ─── Progress ──────────────────────────────────────────
                      StepIndicator(current: 2, total: 2),
                      const SizedBox(height: 24),

                      Text('Secure your\naccount.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          )),
                      const SizedBox(height: 8),

                      Text(
                          'Set a PIN to authorize your transactions.',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14,
                            height: 1.55,
                          )),
                      const SizedBox(height: 32),
                      //
                      // // ─── Passcode section ──────────────────────────────────
                      // _SectionHeader(
                      //   icon: Icons.shield_outlined,
                      //   label: '6-digit app passcode',
                      //   sublabel: 'Used to access the app',
                      // ),
                      // const SizedBox(height: 14),
                      //
                      // _PinField(
                      //   controller: _passcode1,
                      //   label: 'Set passcode',
                      //   maxLength: 6,
                      //   obscure: _obscureP1,
                      //   suffixIcon: EyeToggle(
                      //     obscure: _obscureP1,
                      //     onTap: () =>
                      //         setState(() => _obscureP1 = !_obscureP1),
                      //   ),
                      //   validator: (v) {
                      //     if (v == null || v.trim().isEmpty) {
                      //       return 'Passcode is required';
                      //     }
                      //     if (v.length != 6) return 'Must be exactly 6 digits';
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(height: 14),
                      // _PinField(
                      //   controller: _passcode2,
                      //   label: 'Confirm passcode',
                      //   maxLength: 6,
                      //   obscure: _obscureP2,
                      //   suffixIcon: EyeToggle(
                      //     obscure: _obscureP2,
                      //     onTap: () =>
                      //         setState(() => _obscureP2 = !_obscureP2),
                      //   ),
                      //   validator: (v) {
                      //     if (v == null || v.trim().isEmpty) {
                      //       return 'Please confirm your passcode';
                      //     }
                      //     if (v != _passcode1.text) {
                      //       return 'Passcodes do not match';
                      //     }
                      //     return null;
                      //   },
                      // ),
                      // const SizedBox(height: 28),

                      // ─── PIN section ───────────────────────────────────────
                      _SectionHeader(
                        icon: Icons.payments_outlined,
                        label: '4-digit transaction PIN',
                        sublabel: 'Used to authorize payments & withdrawals',
                      ),
                      const SizedBox(height: 14),

                      _PinField(
                        controller: _pin1,
                        label: 'Set transaction PIN',
                        maxLength: 4,
                        obscure: _obscurePin1,
                        suffixIcon: EyeToggle(
                          obscure: _obscurePin1,
                          onTap: () =>
                              setState(() => _obscurePin1 = !_obscurePin1),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Transaction PIN is required';
                          }
                          if (v.length != 4) return 'Must be exactly 4 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _PinField(
                        controller: _pin2,
                        label: 'Confirm transaction PIN',
                        maxLength: 4,
                        obscure: _obscurePin2,
                        suffixIcon: EyeToggle(
                          obscure: _obscurePin2,
                          onTap: () =>
                              setState(() => _obscurePin2 = !_obscurePin2),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please confirm your PIN';
                          }
                          if (v != _pin1.text) return 'PINs do not match';
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      PrimaryButton(
                        label: 'Finish Setup',
                        loading: _loading,
                        onTap: _loading ? () {} : _finish,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }
}

// ─── Shared helper: section header with icon ─────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kButtonColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kButtonColor.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kButtonColor, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  )),
              Text(sublabel,
                  style: GoogleFonts.inter(
                    color: Colors.white38,
                    fontSize: 12,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// Numeric pin/passcode field
class _PinField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLength;
  final bool obscure;
  final Widget suffixIcon;
  final String? Function(String?) validator;

  const _PinField({
    required this.controller,
    required this.label,
    required this.maxLength,
    required this.obscure,
    required this.suffixIcon,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      cursorColor: Colors.white,
      obscureText: obscure,
      maxLength: maxLength,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15,
          letterSpacing: 4),
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
      null, // hide char counter
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kButtonColor),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 15),
        errorStyle:
        GoogleFonts.inter(color: Colors.red.shade300, fontSize: 12),
      ),
      validator: validator,
    );
  }
}