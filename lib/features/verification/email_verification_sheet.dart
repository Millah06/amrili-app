// lib/features/verification/email_verification_sheet.dart
//
// PHASE 13 — Email verification (free, Level-0 account ownership).
// ─────────────────────────────────────────────────────────────────────────────
// A single bottom sheet with two steps: send code → enter the 6-digit OTP.
// Mirrors the existing PIN/password reset sheets (same look, same flow). Grants
// NO badge and unlocks no cash-out — it just confirms the user owns the email.
//
// Open it with:
//     showModalBottomSheet(
//       context: context, isScrollControlled: true,
//       backgroundColor: const Color(0xFF1E293B),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
//       builder: (_) => const EmailVerificationSheet(),
//     );
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:everywhere/constraints/vendor_theme.dart';
import 'package:everywhere/services/api_service.dart';

class EmailVerificationSheet extends StatefulWidget {
  const EmailVerificationSheet({super.key});

  @override
  State<EmailVerificationSheet> createState() => _EmailVerificationSheetState();
}

enum _Step { intro, code }

class _EmailVerificationSheetState extends State<EmailVerificationSheet> {
  final _api = ApiService();
  final _otpCtrl = TextEditingController();

  _Step _step = _Step.intro;
  String? _maskedEmail;
  bool _busy = false;
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefetchMasked(); // show j***@gmail.com without sending a code
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefetchMasked() async {
    try {
      final r = await _api.requestEmailVerification(preview: true);
      if (mounted) setState(() => _maskedEmail = r['maskedEmail']);
    } catch (_) {/* non-fatal — generic copy is used */}
  }

  Future<void> _sendCode() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await _api.requestEmailVerification();
      if (!mounted) return;
      // Already verified short-circuit.
      if (r['alreadyVerified'] == true) {
        setState(() => _verified = true);
        return;
      }
      setState(() => _step = _Step.code);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not send the code. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the full 6-digit code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.verifyEmail(otp);
      if (!mounted) return;
      setState(() => _verified = true);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
      _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 18, 24, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_verified)
            _successBody()
          else if (_step == _Step.intro)
            _introBody()
          else
            _codeBody(),
        ],
      ),
    );
  }

  Widget _icon(FaIconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF21D3ED).withOpacity(0.12),
      shape: BoxShape.circle,
    ),
    child: FaIcon(icon, color: const Color(0xFF21D3ED), size: 24),
  );

  Widget _introBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icon(FontAwesomeIcons.envelope),
        const SizedBox(height: 18),
        Text('Verify your email',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          _maskedEmail != null
              ? "We'll send a 6-digit code to $_maskedEmail."
              : "We'll send a 6-digit code to your registered email.",
          style: GoogleFonts.inter(
              color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.inter(
                  color: const Color(0xFFFCA5A5), fontSize: 13)),
        ],
        const SizedBox(height: 24),
        _cta(_busy ? 'Sending…' : 'Send code', _busy ? null : _sendCode),
      ],
    );
  }

  Widget _codeBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _icon(FontAwesomeIcons.shieldHalved),
        const SizedBox(height: 18),
        Text('Enter the code',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code we just sent to your email.',
          style: GoogleFonts.inter(
              color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          cursorColor: const Color(0xFF21D3ED),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
              color: VendorTheme.textPrimary,
              fontSize: 24,
              letterSpacing: 12,
              fontWeight: FontWeight.w700),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: Colors.white.withOpacity(0.04),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF21D3ED), width: 1.4),
            ),
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: GoogleFonts.inter(
                  color: const Color(0xFFFCA5A5), fontSize: 13)),
        ],
        const SizedBox(height: 18),
        _cta(_busy ? 'Verifying…' : 'Verify', _busy ? null : _verify),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _busy ? null : _sendCode,
            child: Text('Resend code',
                style: GoogleFonts.inter(
                    color: VendorTheme.textSecondary, fontSize: 13)),
          ),
        ),
      ],
    );
  }

  Widget _successBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: VendorTheme.accent.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const FaIcon(FontAwesomeIcons.circleCheck,
              color: VendorTheme.accent, size: 38),
        ),
        const SizedBox(height: 18),
        Text('Email verified',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 20),
        _cta('Done', () => Navigator.of(context).pop(true)),
      ],
    );
  }

  Widget _cta(String label, VoidCallback? onTap) {
    final disabled = onTap == null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: disabled
            ? const Color(0xFF21D3ED).withOpacity(0.4)
            : const Color(0xFF21D3ED),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Center(
              child: Text(label,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}