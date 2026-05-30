import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constraints/constants.dart';

/// Clean back button — replaces the old ListTile approach
class BButton extends StatelessWidget {
  final VoidCallback onTap;
  const BButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
      ),
    );
  }
}

/// Full-width primary button with optional loading state
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;

  const PrimaryButton({super.key,
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          disabledBackgroundColor: kButtonColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.black54),
        )
            : Text(label,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            )),
      ),
    );
  }
}

/// "or" divider between social and email
class OrDivider extends StatelessWidget {
  final String label;
  const OrDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(label,
              style: GoogleFonts.inter(
                color: Colors.white30,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              )),
        ),
        const Expanded(child: Divider(color: Colors.white12, thickness: 1)),
      ],
    );
  }
}

/// Small field label above inputs
class FieldLabel extends StatelessWidget {
  final String label;
  const FieldLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: GoogleFonts.inter(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ));
  }
}

/// Eye toggle for password fields
class EyeToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const EyeToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        obscure ? FontAwesomeIcons.eyeSlash : FontAwesomeIcons.eye,
        size: 16,
        color: Colors.white38,
      ),
    );
  }
}

/// Step progress dots for SecurityStep1 / Step2
class StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i + 1 == current;
        final done = i + 1 < current;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: done || active ? kButtonColor : Colors.white12,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}

/// Reusable styled text field for auth screens
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      cursorColor: Colors.white,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13.5),
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 15),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: kButtonColor, width: 1.5),
          borderRadius: BorderRadius.circular(14),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red.shade400),
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle:
        GoogleFonts.inter(color: Colors.red.shade300, fontSize: 12),
      ),
      validator: validator,
    );
  }
}