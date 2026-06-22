// lib/features/verification/kyc_verification_screen.dart
//
// PHASE 13 — Identity verification (the destination screen).
// ─────────────────────────────────────────────────────────────────────────────
// Where a user proves identity with a BVN or NIN. On success the backend flips
// Kyc.status = "verified", which cascades to: cash-out unlocked, vendor Level 1,
// and (with business/admin) the public badge. This screen is intentionally
// calm and trust-building — identity capture is a high-anxiety moment, so the
// copy reassures (we store only the last 4 digits) and the states are explicit.
//
// Opened by VerificationGate (or pushed directly from the wallet / vendor
// surfaces). Pops `true` on success so the caller can refresh + continue.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:everywhere/features/verification/verification_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:everywhere/constraints/vendor_theme.dart';
import 'package:everywhere/services/api_service.dart';

// The two identity methods Dojah supports for a cheap, instant check.
enum _IdMethod { nin, bvn }

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final _api = ApiService();
  final _numberCtrl = TextEditingController();

  _IdMethod _method = _IdMethod.nin; // NIN first — cheapest lookup.
  bool _loading = false;
  bool _success = false;
  String? _error;

  // Brand palette anchors (kept local so the screen reads cleanly).
  static const _bg = Color(0xFF0F172A);
  static const _accent = Color(0xFF21D3ED);

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  String get _methodLabel => _method == _IdMethod.nin ? 'NIN' : 'BVN';

  Future<void> _submit() async {
    final number = _numberCtrl.text.trim();
    // Client-side mirror of the server rule (both NIN and BVN are 11 digits).
    if (number.length != 11) {
      setState(() => _error = 'Your $_methodLabel must be 11 digits.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.verifyIdentity(
        method: _method == _IdMethod.nin ? 'nin' : 'bvn',
        number: number,
      );
      await VerificationCache.set(true); // cache so the gate stops asking
      if (!mounted) return;
      setState(() => _success = true);
    } catch (e) {
      if (!mounted) return;
      // ApiService surfaces the backend `message` (name mismatch, invalid
      // number, "not configured" 503, etc.) — show it verbatim, it's user-safe.
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // resizeToAvoidBottomInset + a scroll view = the keyboard never covers the
      // field or the button (one of the keyboard issues flagged for the app).
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text('Verify your identity',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        iconTheme: const IconThemeData(color: VendorTheme.textPrimary),
      ),
      body: SafeArea(
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: _success ? _successView() : _formView())),
      ),
    );
  }

  // ── Form state ──────────────────────────────────────────────────────────────
  Widget _formView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero icon + one-line "why".
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.idCard,
                  color: _accent, size: 34),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'One quick check to unlock cash-out and selling',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.3),
          ),
          const SizedBox(height: 8),
          Text(
            'We verify your $_methodLabel instantly with the national registry. '
                'It takes a few seconds.',
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // Method toggle — segmented control (NIN | BVN).
          _MethodToggle(
            method: _method,
            onChanged: (m) => setState(() {
              _method = m;
              _error = null;
            }),
          ),
          const SizedBox(height: 20),

          // Number field.
          Text(_methodLabel,
              style: GoogleFonts.inter(
                  color: VendorTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _numberCtrl,
            keyboardType: TextInputType.number,
            maxLength: 11,
            cursorColor: _accent,
            style: GoogleFonts.inter(
                color: VendorTheme.textPrimary,
                fontSize: 16,
                letterSpacing: 2),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '', // hide the 0/11 counter; the helper line covers it
              hintText: 'Enter your 11-digit $_methodLabel',
              hintStyle: GoogleFonts.inter(
                  color: VendorTheme.textSecondary.withOpacity(0.6),
                  fontSize: 15,
                  letterSpacing: 0),
              filled: true,
              fillColor: Colors.white.withOpacity(0.04),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent, width: 1.4),
              ),
            ),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),

          // Error line (inline, never a dialog — keeps the flow calm).
          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FaIcon(FontAwesomeIcons.circleExclamation,
                    color: Color(0xFFEF4444), size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: GoogleFonts.inter(
                          color: const Color(0xFFFCA5A5),
                          fontSize: 13,
                          height: 1.4)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Primary action with an inline loading state.
          _PrimaryButton(
            label: _loading ? 'Verifying…' : 'Verify $_methodLabel',
            loading: _loading,
            onTap: _loading ? null : _submit,
          ),
          const SizedBox(height: 16),

          // Privacy reassurance — material to reducing capture anxiety.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FaIcon(FontAwesomeIcons.lock,
                  color: VendorTheme.textSecondary, size: 13),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your number is checked once and never stored — we keep only the '
                      'last 4 digits and your verified status.',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textSecondary,
                      fontSize: 12,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Success state ────────────────────────────────────────────────────────────
  Widget _successView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: VendorTheme.accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.circleCheck,
                color: VendorTheme.accent, size: 44),
          ),
          const SizedBox(height: 20),
          Text('Identity verified',
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            'You can now cash out your earnings and sell on Amril.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                color: VendorTheme.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
            label: 'Done',
            loading: false,
            // Pop `true` so the opener can refresh state and continue the action.
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

// ── Segmented NIN | BVN toggle ──────────────────────────────────────────────────
class _MethodToggle extends StatelessWidget {
  final _IdMethod method;
  final ValueChanged<_IdMethod> onChanged;
  const _MethodToggle({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _seg('NIN', _IdMethod.nin),
          _seg('BVN', _IdMethod.bvn),
        ],
      ),
    );
  }

  Widget _seg(String label, _IdMethod value) {
    final selected = method == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF21D3ED).withOpacity(0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? const Color(0xFF21D3ED)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: selected
                  ? VendorTheme.textPrimary
                  : VendorTheme.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Self-contained primary button (no dependency on VButton's exact API) ────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              child: loading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.2, color: Color(0xFF0F172A)),
              )
                  : Text(label,
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