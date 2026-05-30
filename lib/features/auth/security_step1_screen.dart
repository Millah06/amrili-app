import 'package:everywhere/features/auth/widgets/auth_ui_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constraints/constants.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../shared/utils/flush_bar_message.dart';
import '../../shared/widgets/country_code_picker_field.dart';
import 'security_step2_screen.dart';
import 'package:provider/provider.dart';

class SecurityStep1Screen extends StatefulWidget {
  const SecurityStep1Screen({super.key});

  @override
  State<SecurityStep1Screen> createState() => _SecurityStep1ScreenState();
}

class _SecurityStep1ScreenState extends State<SecurityStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _referralController = TextEditingController();

  String _dialCode = '+234';
  String _countryCode = 'NG';
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final api = ApiService();


      await api.post('/auth/complete-profile', {
        'phone': '$_dialCode${_phoneController.text.trim()}',
        'countryCode': _countryCode,
        'referralCode': _referralController.text.trim(),
      });

      context.read<UserProvider>().updatePhone('$_dialCode${_phoneController.text.trim()}');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SecurityStep2Screen()),
      );
    } catch (e) {
      if (!mounted) return;
      FlushBarMessage.showFlushBar(
        context: context,
        message: e.toString(),
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
        child: Form(
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
                      StepIndicator(current: 1, total: 2),
                      const SizedBox(height: 24),

                      Text('Almost there!',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          )),
                      const SizedBox(height: 8),
                      Text(
                          "Complete your profile — takes under a minute.",
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 14.5,
                            height: 1.5,
                          )),
                      const SizedBox(height: 36),

                      // ─── Phone label ───────────────────────────────────────
                      FieldLabel(label: 'Phone number'),
                      const SizedBox(height: 10),

                      // ─── Phone row: country picker + number field ──────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CountryCodePickerField(
                            initialCode: '+234',
                            onChanged: (dial, code) => setState(() {
                              _dialCode = dial;
                              _countryCode = code;
                            }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              cursorColor: Colors.white,
                              style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 15),
                              decoration: InputDecoration(
                                hintText: '8012345678',
                                hintStyle: GoogleFonts.inter(
                                    color: Colors.white30, fontSize: 15),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide:
                                  const BorderSide(color: kButtonColor),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 15),
                                errorStyle: GoogleFonts.inter(
                                    color: Colors.red.shade300, fontSize: 12),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone number is required';
                                }
                                if (v.trim().length < 7) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ─── Referral (optional) ───────────────────────────────
                      Row(
                        children: [
                          FieldLabel(label: 'Referral code'),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Optional',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _referralController,
                        style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 15),
                        cursorColor: Colors.white,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'e.g. JOHN2025',
                          hintStyle: GoogleFonts.inter(
                              color: Colors.white30, fontSize: 15),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          prefixIcon: const Icon(Icons.card_giftcard_rounded,
                              color: Colors.white38, size: 20),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: kButtonColor),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ─── Continue button ───────────────────────────────────
                      PrimaryButton(
                        label: _loading ? 'Saving...' : 'Continue',
                        loading: _loading,
                        onTap: _loading ? () {} : _submit,
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
    );
  }
}