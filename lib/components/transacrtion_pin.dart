import 'dart:math';

import 'package:everywhere/components/pin_entry.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:everywhere/shared/utils/flush_bar_message.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

// Import your global navigator key so we can show sheets after pop
import '../app.dart';
import '../main.dart' show navigatorKey;

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET — use this everywhere you need PIN confirmation
// ─────────────────────────────────────────────────────────────────────────────

class TransactionPin extends StatefulWidget {
  /// Called only after the PIN has been successfully verified on the backend.
  /// The sheet closes itself before calling this — do NOT pop again.
  final VoidCallback onSuccess;

  const TransactionPin({super.key, required this.onSuccess});

  @override
  State<TransactionPin> createState() => _TransactionPinState();
}

class _TransactionPinState extends State<TransactionPin> {
  bool _verifying = false;
  String? _errorMessage;
  Key _pinKey = UniqueKey(); // changing this key resets PinEntryScreen dots

  // ─── Backend PIN verification ──────────────────────────────────────────────

  Future<void> _verifyPin(String pin) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _errorMessage = null;
    });
    try {
      final response = await ApiService().post('/auth/verify-pin', {'pin': pin});
      if (!mounted) return;
      if (response['verified'] == true) {
        Navigator.pop(context); // close this sheet first
        widget.onSuccess();     // then fire callback — do NOT pop in the callback
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('pin not set') || msg.contains('pin_not_set')) {
        _popAndAction(() => _showSetPinSheet(navigatorKey.currentContext!));
      } else {
        // Wrong PIN — show error and reset dots
        setState(() {
          _errorMessage = 'Incorrect PIN. Try again.';
          _pinKey = UniqueKey();
          _verifying = false;
        });
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  // ─── Biometric ────────────────────────────────────────────────────────────
  // Biometric = sufficient proof of identity — bypasses backend PIN check.

  Future<void> _handleBiometric() async {
    final auth = LocalAuthentication();
    final canAuth =
        await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (!canAuth || !mounted) return;

    try {
      final didAuth = await auth.authenticate(
        localizedReason: 'Confirm your transaction',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (didAuth && mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (_) {
      // Device doesn't support biometric — silently ignore
    }
  }

  // ─── Forgot PIN ────────────────────────────────────────────────────────────

  void _handleForgotPin() {
    _popAndAction(() => _showForgotPinSheet(navigatorKey.currentContext!));
  }

  /// Pops this sheet, then runs [action] in a post-frame callback
  /// so the navigator is fully settled before showing the next sheet.
  void _popAndAction(VoidCallback action) {
    Navigator.pop(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: _errorMessage != null ? 0.62 : 0.57,
      child: Stack(
        children: [
          Column(
            children: [
              // Error banner (shown when PIN is wrong)
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  color: Colors.red.withOpacity(0.12),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.red.shade300,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Expanded(
                child: PinEntryScreen(
                  key: _pinKey,
                  onCompleted: _verifyPin,
                  onForgotPin: _handleForgotPin,
                  onBiometricPressed: _handleBiometric,
                ),
              ),
            ],
          ),
          // Verifying overlay
          if (_verifying)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: kButtonColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PIN FLOW  (3 stacked sheets: Send OTP → Verify OTP → Set New PIN)
// ─────────────────────────────────────────────────────────────────────────────

void _showForgotPinSheet(BuildContext ctx) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ForgotPinSheet(),
  );
}

class _ForgotPinSheet extends StatefulWidget {
  const _ForgotPinSheet();
  @override
  State<_ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends State<_ForgotPinSheet> {
  bool _sending = false;
  String? _maskedEmail;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fetch masked email on open
    _fetchMaskedEmail();
  }

  Future<void> _fetchMaskedEmail() async {
    try {
      final res = await ApiService().post('/auth/request-pin-reset', {'preview': true});
      if (mounted) setState(() => _maskedEmail = res['maskedEmail']);
    } catch (_) {}
  }

  Future<void> _sendCode() async {
    setState(() { _sending = true; _error = null; });
    try {
      await ApiService().post('/auth/request-pin-reset', {});
      if (!mounted) return;
      // Stack the verify OTP sheet on top
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => const _VerifyOtpSheet(flowType: _OtpFlowType.pin),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not send code. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const SizedBox(height: 24),
          _SheetIcon(icon: Icons.lock_reset_rounded),
          const SizedBox(height: 18),
          Text('Forgot your PIN?',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            _maskedEmail != null
                ? "We'll send a 6-digit reset code to $_maskedEmail"
                : "We'll send a 6-digit reset code to your registered email.",
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                GoogleFonts.inter(color: Colors.red.shade300, fontSize: 13)),
          ],
          const SizedBox(height: 28),
          _FullButton(
            label: _sending ? 'Sending...' : 'Send Reset Code',
            loading: _sending,
            onTap: _sending ? () {} : _sendCode,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum _OtpFlowType { pin, password }

class _VerifyOtpSheet extends StatefulWidget {
  final _OtpFlowType flowType;
  final String? email; // only needed for password reset (unauthenticated)
  final String? newPassword; // carried through for password reset

  const _VerifyOtpSheet({
    required this.flowType,
    this.email,
    this.newPassword,
  });

  @override
  State<_VerifyOtpSheet> createState() => _VerifyOtpSheetState();
}

class _VerifyOtpSheetState extends State<_VerifyOtpSheet> {
  final _otpCtrl = TextEditingController();
  bool _verifying = false;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the full 6-digit code.');
      return;
    }
    setState(() { _verifying = true; _error = null; });

    try {
      if (widget.flowType == _OtpFlowType.pin) {
        await ApiService().post('/auth/verify-pin-otp', {'otp': otp});
        if (!mounted) return;
        // Stack next sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _SetNewPinSheet(otp: otp, flowType: _OtpFlowType.pin),
        );
      } else {
        // Password reset — verify OTP then set new password
        await ApiService().post('/auth/verify-password-otp', {
          'email': widget.email,
          'otp': otp,
        });
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF1E293B),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (_) => _SetNewPasswordSheet(email: widget.email!, otp: otp),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Invalid or expired code. Please try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const SizedBox(height: 24),
          _SheetIcon(icon: Icons.mark_email_read_outlined),
          const SizedBox(height: 18),
          Text('Enter the code',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Check your email for the 6-digit code.',
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 28),
          // OTP field
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            autofocus: true,
            cursorColor: kButtonColor,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: 14,
            ),
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              hintText: '• • • • • •',
              hintStyle: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 22,
                  letterSpacing: 10),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: kButtonColor, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
            onChanged: (v) {
              if (v.length == 6) _verify();
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                GoogleFonts.inter(color: Colors.red.shade300, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _FullButton(
            label: _verifying ? 'Verifying...' : 'Verify Code',
            loading: _verifying,
            onTap: _verifying ? () {} : _verify,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SetNewPinSheet extends StatefulWidget {
  final String otp;
  final _OtpFlowType flowType;
  const _SetNewPinSheet({required this.otp, required this.flowType});

  @override
  State<_SetNewPinSheet> createState() => _SetNewPinSheetState();
}

class _SetNewPinSheetState extends State<_SetNewPinSheet> {
  final _pin1Ctrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p1 = _pin1Ctrl.text.trim();
    final p2 = _pin2Ctrl.text.trim();
    if (p1.length != 4) {
      setState(() => _error = 'PIN must be exactly 4 digits.');
      return;
    }
    if (p1 != p2) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService().post('/auth/reset-pin', {
        'otp': widget.otp,
        'newPin': p1,
      });
      if (!mounted) return;
      // Pop all sheets back to root
      Navigator.of(navigatorKey.currentContext!)
          .popUntil((route) => route.isFirst);
      FlushBarMessage.showFlushBar(
        context: navigatorKey.currentContext!,
        message: 'Your transaction PIN has been updated.',
        title: 'PIN Changed',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to update PIN. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const SizedBox(height: 24),
          _SheetIcon(icon: Icons.pin_outlined),
          const SizedBox(height: 18),
          Text('Set new PIN',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Choose a new 4-digit transaction PIN.',
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          _PinInput(
              ctrl: _pin1Ctrl,
              label: 'New PIN',
              obscure: _obscure1,
              onToggle: () => setState(() => _obscure1 = !_obscure1)),
          const SizedBox(height: 14),
          _PinInput(
              ctrl: _pin2Ctrl,
              label: 'Confirm new PIN',
              obscure: _obscure2,
              onToggle: () => setState(() => _obscure2 = !_obscure2)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                GoogleFonts.inter(color: Colors.red.shade300, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _FullButton(
              label: _saving ? 'Saving...' : 'Change PIN',
              loading: _saving,
              onTap: _saving ? () {} : _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SET PIN SHEET — shown when user hasn't set a PIN yet
// ─────────────────────────────────────────────────────────────────────────────

void _showSetPinSheet(BuildContext ctx) {
  showModalBottomSheet(
    context: ctx,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _SetPinSheet(),
  );
}

class _SetPinSheet extends StatefulWidget {
  const _SetPinSheet();
  @override
  State<_SetPinSheet> createState() => _SetPinSheetState();
}

class _SetPinSheetState extends State<_SetPinSheet> {
  final _pin1Ctrl = TextEditingController();
  final _pin2Ctrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pin1Ctrl.dispose();
    _pin2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p1 = _pin1Ctrl.text.trim();
    final p2 = _pin2Ctrl.text.trim();
    if (p1.length != 4) {
      setState(() => _error = 'PIN must be exactly 4 digits.');
      return;
    }
    if (p1 != p2) {
      setState(() => _error = 'PINs do not match.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService().post('/auth/set-pin', {'pin': p1});
      if (!mounted) return;
      Navigator.pop(context);
      FlushBarMessage.showFlushBar(
        context: navigatorKey.currentContext!,
        message: 'Transaction PIN set. You can now complete your transaction.',
        title: 'PIN Set',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to set PIN. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const SizedBox(height: 24),
          _SheetIcon(icon: Icons.add_moderator_outlined),
          const SizedBox(height: 18),
          Text('Set your transaction PIN',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            "You haven't set a transaction PIN yet.\n"
                "Set one to authorize payments and withdrawals.",
            style: GoogleFonts.inter(
                color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          _PinInput(
              ctrl: _pin1Ctrl,
              label: 'Enter 4-digit PIN',
              obscure: _obscure1,
              onToggle: () => setState(() => _obscure1 = !_obscure1)),
          const SizedBox(height: 14),
          _PinInput(
              ctrl: _pin2Ctrl,
              label: 'Confirm PIN',
              obscure: _obscure2,
              onToggle: () => setState(() => _obscure2 = !_obscure2)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                GoogleFonts.inter(color: Colors.red.shade300, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _FullButton(
              label: _saving ? 'Saving...' : 'Set PIN',
              loading: _saving,
              onTap: _saving ? () {} : _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD FLOW — used by LoginScreen
// ─────────────────────────────────────────────────────────────────────────────

/// Call this from LoginScreen instead of the old Firebase-only sheet.
void showForgotPasswordFlow(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ForgotPasswordSheet(),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await ApiService().post('/auth/request-password-reset', {'email': email});
      if (!mounted) return;
      // Stack OTP sheet on top
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _VerifyOtpSheet(
          flowType: _OtpFlowType.password,
          email: email,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() => _error = msg.contains('not found')
          ? 'No account found with this email.'
          : 'Could not send code. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const SizedBox(height: 24),
          _SheetIcon(icon: Icons.email_outlined),
          const SizedBox(height: 18),
          Text('Reset your password',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text("Enter your email — we'll send a 6-digit reset code.",
              style: GoogleFonts.inter(
                  color: Colors.white54, fontSize: 14, height: 1.5)),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            cursorColor: kButtonColor,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'your@email.com',
              hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 15),
              prefixIcon: const Icon(Icons.email_outlined,
                  color: Colors.white38, size: 20),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: kButtonColor, width: 1.5),
                borderRadius: BorderRadius.circular(14),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 15),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                GoogleFonts.inter(color: Colors.red.shade300, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _FullButton(
              label: _sending ? 'Sending...' : 'Send Reset Code',
              loading: _sending,
              onTap: _sending ? () {} : _sendCode),
        ],
      ),
    );
  }
}

class _SetNewPasswordSheet extends StatefulWidget {
  final String email;
  final String otp;
  const _SetNewPasswordSheet({required this.email, required this.otp});
  @override
  State<_SetNewPasswordSheet> createState() => _SetNewPasswordSheetState();
}

class _SetNewPasswordSheetState extends State<_SetNewPasswordSheet> {
  final _pw1Ctrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pw1Ctrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pw = _pw1Ctrl.text;
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pw != _pw2Ctrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ApiService().post('/auth/reset-password', {
        'email': widget.email,
        'otp': widget.otp,
        'newPassword': pw,
      });
      if (!mounted) return;
      Navigator.of(navigatorKey.currentContext!)
          .popUntil((route) => route.isFirst);
      FlushBarMessage.showFlushBar(
        context: navigatorKey.currentContext!,
        message: 'Password updated. You can now sign in.',
        title: 'Password Changed',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to reset password. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DragHandle(),
          const SizedBox(height: 24),
          _SheetIcon(icon: Icons.lock_outline_rounded),
          const SizedBox(height: 18),
          Text('Set new password',
              style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Choose a strong password.',
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 24),
          _PasswordInput(
              ctrl: _pw1Ctrl,
              label: 'New password',
              obscure: _obscure1,
              onToggle: () => setState(() => _obscure1 = !_obscure1)),
          const SizedBox(height: 14),
          _PasswordInput(
              ctrl: _pw2Ctrl,
              label: 'Confirm password',
              obscure: _obscure2,
              onToggle: () => setState(() => _obscure2 = !_obscure2)),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style:
                GoogleFonts.inter(color: Colors.red.shade300, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _FullButton(
              label: _saving ? 'Saving...' : 'Change Password',
              loading: _saving,
              onTap: _saving ? () {} : _save),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL PRIVATE HELPERS (keep at bottom of file)
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(99)),
    ),
  );
}

class _SheetIcon extends StatelessWidget {
  final IconData icon;
  const _SheetIcon({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: kButtonColor.withOpacity(0.12),
      border: Border.all(color: kButtonColor.withOpacity(0.3), width: 1.5),
    ),
    child: Icon(icon, color: kButtonColor, size: 24),
  );
}

class _FullButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  const _FullButton(
      {required this.label, required this.onTap, this.loading = false});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: kButtonColor,
        disabledBackgroundColor: kButtonColor.withOpacity(0.45),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: loading
          ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.black45))
          : Text(label,
          style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 15)),
    ),
  );
}

class _PinInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PinInput(
      {required this.ctrl,
        required this.label,
        required this.obscure,
        required this.onToggle});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    maxLength: 4,
    obscureText: obscure,
    cursorColor: kButtonColor,
    style: GoogleFonts.inter(
        color: Colors.white, fontSize: 18, letterSpacing: 6),
    buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
              obscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
              size: 15,
              color: Colors.white38)),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kButtonColor, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
  );
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordInput(
      {required this.ctrl,
        required this.label,
        required this.obscure,
        required this.onToggle});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    obscureText: obscure,
    cursorColor: kButtonColor,
    style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
              obscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
              size: 15,
              color: Colors.white38)),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kButtonColor, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
  );
}