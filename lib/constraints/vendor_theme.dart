import 'package:flutter/material.dart';

// ─── THEME ────────────────────────────────────────────────────────────────────

class VendorTheme {
  VendorTheme._();

  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color surfaceVariant = Color(0xFF334155);

  static const Color primary = Color(0xFF21D3ED);

  static const Color circularProgressColor = Color(0xFF177E85);

  static const Color primaryVariant = Color(0xFF1D4ED8);
  static const Color accent = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color divider = Color(0xFF1E293B);
  static const Color gold = Color(0xFFFFD700);

  static ThemeData get theme => ThemeData(
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      background: background,
      surface: surface,
      primary: primary,
      error: error,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
      headlineMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
      titleLarge: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
      titleMedium: TextStyle(
          color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 14),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
      bodySmall: TextStyle(color: textMuted, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
          color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
    ),
    dividerColor: divider,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// ─── APP CONFIG MODEL ─────────────────────────────────────────────────────────

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

// ─── LOCATION HIERARCHY ───────────────────────────────────────────────────────

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