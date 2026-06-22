// lib/constraints/app_theme.dart
//
// Phase 12 (Track B) — SINGLE source of truth for all visual design tokens.
//
// Before this file was expanded, colours were declared in three places
// that told different stories:
//   • lib/constraints/vendor_theme.dart — VendorTheme.*
//   • lib/constraints/constants.dart    — kButtonColor, kCardColor, …
//   • lib/app.dart                      — ThemeData built inline in build()
// Any change required hunting across all three; new screens landed on
// slightly different colours depending on which file the session read.
//
// NOW THERE IS ONE DECLARATION.
//   • VendorTheme is a thin backward-compat shim that re-exports from here.
//   • Constants colour aliases point here.
//   • app.dart calls AppTheme.data directly.
//
// ─── TYPOGRAPHY CONTRACT ─────────────────────────────────────────────────────
//   Display / Headline → Poppins  (confident, brand-weight headings)
//   Title / Body / Label → Inter  (legible, neutral reading text)
//   Exception: money figures use "DejaVu Sans" (already in pubspec);
//   those usages stay at their call sites with explicit fontFamily.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._(); // static-only; never instantiated

  // ─── COLOUR PALETTE ───────────────────────────────────────────────────────
  // The exact same hex values previously scattered across the app, now named
  // so readers know the intent of each slot.

  // Backgrounds
  static const Color background     = Color(0xFF0F172A); // scaffold, page bg
  static const Color surface        = Color(0xFF1E293B); // cards, panels, bottom sheets
  static const Color surfaceVariant = Color(0xFF334155); // chips, divider rings, disabled

  // Brand
  static const Color primary        = Color(0xFF21D3ED); // cyan — buttons, active nav, links
  static const Color primaryDark    = Color(0xFF177E85); // teal — secondary CTA, success snack
  static const Color primaryVariant = Color(0xFF1D4ED8); // deep blue — rarely used

  // Semantic status
  static const Color success        = Color(0xFF10B981); // green
  static const Color warning        = Color(0xFFF59E0B); // amber — boost badge, alerts
  static const Color error          = Color(0xFFEF4444); // red — errors, destructive
  static const Color gold           = Color(0xFFFFD700); // coin icon, leaderboard

  // Text hierarchy
  static const Color textPrimary    = Color(0xFFF8FAFC); // headings, primary body
  static const Color textSecondary  = Color(0xFF94A3B8); // subtitles, metadata
  static const Color textMuted      = Color(0xFF64748B); // timestamps, placeholders, disabled

  // Structural
  static const Color divider        = Color(0xFF1E293B); // hairline border (== surface)
  static const Color snackSuccess   = Color(0xFF177E85); // SnackBar success background

  // Chat semantics
  static const Color chatMyBubble    = Color(0xFF1F8A70);
  static const Color chatOtherBubble = Color(0xFF1E293B); // == surface

  // ─── TEXT THEME ───────────────────────────────────────────────────────────
  // Google Fonts factories produce a complete TextTheme where every role uses
  // the specified typeface, then we override per-role for the mixed scale.
  // Callers should use Theme.of(context).textTheme.bodyLarge etc. rather than
  // hard-coding GoogleFonts.inter(...) at every call site; DefaultTextStyle
  // propagates the right font automatically through the widget tree.
  static TextTheme get _textTheme => GoogleFonts.interTextTheme().copyWith(

    // ── Display: hero copy, big onboarding screens ─────────────────────────
    displayLarge: GoogleFonts.poppins(
      fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary,
      letterSpacing: -0.4,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary,
      letterSpacing: -0.3,
    ),

    // ── Headline: screen / section headings ────────────────────────────────
    headlineLarge: GoogleFonts.poppins(
      fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
    ),

    // ── Title: card headers, list tile primaries, toolbar ─────────────────
    titleLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary,
    ),

    // ── Body: post text, list content, form fields ─────────────────────────
    bodyLarge: GoogleFonts.inter(
      fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 13, fontWeight: FontWeight.w400, color: textMuted,
      height: 1.4,
    ),

    // ── Label: button text, badge text, navigation labels ─────────────────
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w600, color: textMuted,
      letterSpacing: 0.2,
    ),
  );

  // ─── FULL ThemeData ────────────────────────────────────────────────────────
  // The single object passed to MaterialApp.router(theme:). Every widget that
  // inherits DefaultTextStyle, ColorScheme, or ButtonStyle automatically picks
  // up the right font and colour without per-widget overrides.
  // Lazily initialised so Google Fonts doesn't run at import time.
  static final ThemeData data = ThemeData(
    // Keep Material 2 — M3 changes BottomAppBar notch geometry, card shapes,
    // and navigation rail defaults in ways that would break the existing shell.
    useMaterial3: false,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,

    // ColorScheme feeds ColorScheme.of(context).* calls across the whole tree.
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: primary,
      secondary: primaryDark,
      error: error,
      onPrimary: background,   // readable dark text on the cyan primary
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textPrimary,
    ),

    // Typography — full role-based scale; no more scattered GoogleFonts.xxx().
    textTheme: _textTheme,
    primaryTextTheme: _textTheme,

    // ── AppBar ─────────────────────────────────────────────────────────────
    // Teal background for all AppBars; Poppins 700 title mirrors headlineSmall.
    appBarTheme: AppBarTheme(
      backgroundColor: primaryDark,
      elevation: 0,
      iconTheme: const IconThemeData(color: textPrimary),
      titleTextStyle: GoogleFonts.poppins(
        color: textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    ),

    // ── Icons ──────────────────────────────────────────────────────────────
    iconTheme: const IconThemeData(color: textPrimary),

    // ── Input / form fields ────────────────────────────────────────────────
    // Used by auth screens, checkout, search, settings — everywhere.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      floatingLabelStyle: GoogleFonts.inter(color: textPrimary),
      labelStyle: GoogleFonts.inter(
        color: textPrimary.withValues(alpha: 0.54),
        fontSize: 13,
      ),
      hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 14),
      helperStyle: GoogleFonts.inter(color: textPrimary),
      prefixIconColor: textPrimary,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: primary),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: error),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: error),
        borderRadius: BorderRadius.circular(10),
      ),
    ),

    // ── Buttons ────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: background,  // dark text reads clearly on cyan
        disabledBackgroundColor: surfaceVariant,
        disabledForegroundColor: textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        disabledForegroundColor: textMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    // ── Bottom sheet ───────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      dragHandleSize: Size(70, 5),
      backgroundColor: background,
      dragHandleColor: Colors.white,
    ),

    // ── Bottom nav bar (legacy — kept for any residual BottomNavigationBar) ─
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
    ),

    // ── Divider ────────────────────────────────────────────────────────────
    dividerColor: divider,

    // ── Chip ───────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariant,
      selectedColor: primary.withValues(alpha: 0.2),
      disabledColor: surfaceVariant,
      labelStyle: GoogleFonts.inter(
        color: textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      brightness: Brightness.dark,
    ),

    // ── Dialog ─────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: GoogleFonts.poppins(
        color: textPrimary, fontWeight: FontWeight.w700, fontSize: 18,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: textSecondary, fontSize: 14,
      ),
    ),

    // ── SnackBar ───────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),

    // ── Scrollbar (auto-injected on web/desktop by MaterialScrollBehavior) ─
    // Teal thumb on the brand background; transparent border keeps it elegant.
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        primaryDark.withValues(alpha: 0.65),
      ),
      trackColor: WidgetStateProperty.all(
        primary.withValues(alpha: 0.08),
      ),
      trackBorderColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(4),
      crossAxisMargin: 2,
      mainAxisMargin: 4,
    ),
  );
}
