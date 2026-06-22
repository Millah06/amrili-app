// lib/constraints/vendor_theme.dart
//
// BACKWARD-COMPATIBILITY SHIM — Do not add new tokens here.
//
// All colour and theme constants are now authoritative in:
//   lib/constraints/app_theme.dart  →  class AppTheme
//
// This file exists so existing `VendorTheme.xxx` call sites across the whole
// app continue to compile without a big-bang import rewrite. The aliases are
// compile-time constants (pointing to other compile-time constants in AppTheme),
// so there is zero runtime cost.
//
// Migration path for new code
//   import 'package:everywhere/constraints/app_theme.dart';
//   Use AppTheme.primary  (not VendorTheme.primary), etc.
//   Once all call sites in a file are migrated, drop the VendorTheme import.

import 'package:flutter/material.dart';
import 'app_theme.dart';

class VendorTheme {
  VendorTheme._();

  // ─── Colour aliases → AppTheme ─────────────────────────────────────────────
  static const Color background         = AppTheme.background;
  static const Color surface            = AppTheme.surface;
  static const Color surfaceVariant     = AppTheme.surfaceVariant;
  static const Color primary            = AppTheme.primary;
  static const Color primaryVariant     = AppTheme.primaryVariant;
  static const Color circularProgressColor = AppTheme.primaryDark; // 0xFF177E85
  static const Color accent             = AppTheme.success;
  static const Color warning            = AppTheme.warning;
  static const Color error              = AppTheme.error;
  static const Color textPrimary        = AppTheme.textPrimary;
  static const Color textSecondary      = AppTheme.textSecondary;
  static const Color textMuted          = AppTheme.textMuted;
  static const Color divider            = AppTheme.divider;
  static const Color gold               = AppTheme.gold;

  // ─── ThemeData delegate ────────────────────────────────────────────────────
  // Any call to VendorTheme.theme now returns the same authoritative ThemeData
  // that MaterialApp.router uses. Applies to widget-level Theme(data:...) calls.
  static ThemeData get theme => AppTheme.data;
}

// ─────────────────────────────────────────────────────────────────────────────
// AppConfig and LocationHierarchy are domain models that ended up in this file
// for historical reasons. They stay here so no import paths break.
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  final double transactionFeePercent;
  final int autoReleaseHours;
  final int appealWindowHours;
  final int chatCloseHours;

  const AppConfig({
    required this.transactionFeePercent,
    required this.autoReleaseHours,
    required this.appealWindowHours,
    required this.chatCloseHours,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    transactionFeePercent:
        (json['transactionFeePercent'] as num).toDouble(),
    autoReleaseHours: json['autoReleaseHours'] ?? 24,
    appealWindowHours: json['appealWindowHours'] ?? 48,
    chatCloseHours: json['chatCloseHours'] ?? 72,
  );

  factory AppConfig.defaults() => const AppConfig(
    transactionFeePercent: 0,
    autoReleaseHours: 24,
    appealWindowHours: 48,
    chatCloseHours: 72,
  );
}

class LocationHierarchy {
  final List<String> states;
  final Map<String, List<String>> lgasByState;
  final Map<String, List<String>> areasByLga;
  final Map<String, List<String>> streetsByArea;

  const LocationHierarchy({
    required this.states,
    required this.lgasByState,
    required this.areasByLga,
    required this.streetsByArea,
  });

  List<String> lgasFor(String state) => lgasByState[state] ?? [];
  List<String> areasFor(String lga) => areasByLga[lga] ?? [];
  List<String> streetsFor(String area) => streetsByArea[area] ?? [];
}
