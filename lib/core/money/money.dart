// lib/core/money/money.dart
//
// PHASE 9 — Money formatting foundation.
// ─────────────────────────────────────────────────────────────────────────────
// WHY THIS EXISTS: the codebase hardcodes ₦ / kNaira / 'en_NG' everywhere.
// Phase 10 (coins + global users) needs a single seam where currency display
// is decided. This file IS that seam — behavior today is intentionally
// NGN-only (no FX, no conversion; the wallet economy is NGN, binding Phase 9
// decision), but every call site migrated onto Money/MoneyText becomes
// currency-ready for free.
//
// MIGRATION POLICY (Phase 9): new and redesigned surfaces use Money/MoneyText.
// Existing screens keep kNaira until touched — a big-bang sweep is not worth
// the regression risk. kNaira remains valid; it is simply no longer the
// pattern for new code.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Money {
  Money._(); // static-only

  /// Default currency of the entire Amril economy (binding until Phase 10).
  static const String defaultCurrency = 'NGN';

  /// Symbols for currencies the app can DISPLAY. Display ≠ transact:
  /// transacting stays NGN-only. Unknown codes fall back to the code itself
  /// ("GHS 500.00") which is always unambiguous.
  static const Map<String, String> _symbols = {
    'NGN': '₦',
    'USD': r'$',
    'CNY': '¥',
    'EUR': '€',
    'GBP': '£',
  };

  /// Symbol for [currency]; defaults to ₦.
  static String symbol([String? currency]) {
    final code = (currency ?? defaultCurrency).toUpperCase();
    return _symbols[code] ?? code;
  }

  /// "₦12,500.00". Single place where grouping/decimal rules live.
  static String format(num amount, {String? currency, int decimals = 2}) {
    final f = NumberFormat.currency(
      // en_NG grouping (1,234,567.89) matches every existing screen; safe for
      // the displayable symbols above too.
      locale: 'en_NG',
      symbol: symbol(currency),
      decimalDigits: decimals,
    );
    return f.format(amount);
  }

  /// "12,500.00" — number only, for layouts that style the symbol separately
  /// (the BalanceText pattern used across wallet/services screens).
  static String formatBare(num amount, {int decimals = 2}) {
    final f = NumberFormat.currency(
        locale: 'en_NG', symbol: '', decimalDigits: decimals);
    return f.format(amount).trim();
  }
}

/// Drop-in money label. Prefer this over `Text('₦...')` in all new code —
/// when Phase 10 introduces per-user display currency, every MoneyText
/// updates from one place.
class MoneyText extends StatelessWidget {
  final num amount;
  final String? currency;
  final int decimals;
  final TextStyle? style;

  const MoneyText(
      this.amount, {
        super.key,
        this.currency,
        this.decimals = 2,
        this.style,
      });

  @override
  Widget build(BuildContext context) {
    return Text(
      Money.format(amount, currency: currency, decimals: decimals),
      style: style,
    );
  }
}