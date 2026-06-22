// lib/features/verification/verification_cache.dart
//
// PHASE 13 — Cached identity-verified flag.
// ─────────────────────────────────────────────────────────────────────────────
// Mirrors how `isGuest` is stored: one bool in SharedPreferences, written once,
// cleared on logout. The gate reads THIS — never the network — because the
// backend already re-verifies on every cash-out / sell call (the hard backstop),
// and Kyc is 1-1 with User so re-fetching it on every gated tap is wasteful.
//
// WIRE THESE FOUR CALL POINTS (the same spots you set/clear isGuest):
//   • LOGIN    → await VerificationCache.hydrateFromNetwork();   // fetch + cache
//   • SIGN-UP  → await VerificationCache.hydrateFromNetwork();   // (will be false)
//   • LOGOUT   → await VerificationCache.clear();
//   • ON VERIFY→ handled for you: the KYC screen calls set(true) on success.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:shared_preferences/shared_preferences.dart';
import 'package:everywhere/services/api_service.dart';

class VerificationCache {
  static const _key = 'isIdentityVerified';

  // In-memory mirror so widgets can read the last-known value synchronously.
  static bool _mem = false;
  static bool get cached => _mem;

  /// Async read (refreshes the in-memory mirror). The gate uses this.
  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    _mem = prefs.getBool(_key) ?? false;
    return _mem;
  }

  /// Persist the flag. Called after a successful KYC and by hydrateFromNetwork.
  static Future<void> set(bool verified) async {
    _mem = verified;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, verified);
  }

  /// Clear on logout.
  static Future<void> clear() async {
    _mem = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Fetch the verified status once and cache it. Call on login + sign-up.
  static Future<void> hydrateFromNetwork() async {
    try {
      final res = await ApiService().getKycStatus();
      await set(res['status'] == 'verified');
    } catch (_) {
      /* network/auth hiccup → keep whatever is already cached */
    }
  }
}