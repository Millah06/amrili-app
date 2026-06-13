// lib/core/region/region_provider.dart
//
// PHASE 9 — Region / country-gating layer.
// ─────────────────────────────────────────────────────────────────────────────
// One question, answered in one place: is this user "NG-tied"?
//
//   NG-tied  → full app: NGN wallet, Bills & Top-ups, marketplace entry.
//   Not tied → global surfaces only (feed, chats, scanner, profile) and the
//              wallet "coming to your region" preview.
//
// THE RULE (binding, Phase 9):
//   NG-tied  =  phone starts with '+234'
//            OR User.country == 'NG'
//            OR country is missing  (legacy accounts predate region capture —
//                                    the entire pre-Phase-9 user base is Nigerian)
//
// Phone is checked FIRST and independently: a diaspora Nigerian registering
// with their +234 number stays NG-tied even if their IP/country says CN/US.
// The reverse case (Nigerian abroad on a foreign SIM) is handled by the
// Home-country setting (HomeCountrySheet → PATCH /users/me/region), which
// updates User.country server-side; the next UserProvider sync flows through
// here automatically.
//
// TIMING: gating decisions are needed on the very first frame (wallet tab),
// before any network call. So the resolved value is persisted in
// SharedPreferences and main.dart hands it to the constructor synchronously.
// Default for a fresh install is NG — identical to pre-Phase-9 behavior, so
// existing users see zero change until a fresh /users/me proves otherwise.
//
// WIRING: ChangeNotifierProxyProvider<UserProvider, RegionProvider> in
// main.dart calls syncFromUser() on every UserProvider notification.
//
// HARD RULE (binding): QR scans and deep links BYPASS this gate entirely.
// Nothing in deep-link routing may consult RegionProvider — the QR identifies
// the vendor; region only shapes what the default UI promotes.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../analytics/analytics.dart';
import '../../models/user_model.dart';

class RegionProvider extends ChangeNotifier {
  /// SharedPreferences key. Public so main.dart can read it before runApp.
  /// Values: 'NG' | 'INTL'.
  static const String prefsKey = 'amril_region_v1';

  bool _isNgTied;

  /// Last phone seen from a real user sync — kept so an optimistic
  /// country override can still honor the +234 rule.
  String _lastPhone = '';

  RegionProvider({required bool initialIsNgTied}) : _isNgTied = initialIsNgTied;

  /// True → NGN wallet, bills, marketplace. False → global surfaces only.
  bool get isNgTied => _isNgTied;

  /// The pure gating rule. Static so other layers / tests can evaluate it
  /// without a provider instance.
  static bool computeIsNgTied({String? phone, String? country}) {
    final p = (phone ?? '').trim();
    if (p.startsWith('+234')) return true;

    final c = (country ?? '').trim().toUpperCase();
    if (c.isEmpty) return true; // legacy account → NG by definition
    return c == 'NG';
  }

  /// Called by the ProxyProvider on every UserProvider notification.
  ///
  /// Guards:
  ///  - null user (guest / logged out): keep the persisted value. Guests get
  ///    the NG default; gated tabs already auth-gate them anyway.
  ///  - claims-only partial seed (UserProvider.getUserId builds a User from
  ///    just {'id': postgresId} — email is empty): skip, otherwise a non-NG
  ///    user would flash NG-tied until /users/me lands.
  void syncFromUser(User? user) {
    if (user == null) return;
    if (user.email.isEmpty) return; // partial seed — not a real /users/me load

    _lastPhone = user.phone;
    _apply(computeIsNgTied(phone: user.phone, country: user.country));
  }

  /// Optimistic local apply for the Home-country setting (instant UI while the
  /// server write + UserProvider.loadUser() round-trip completes — which then
  /// re-syncs through syncFromUser and confirms or corrects this).
  void applyHomeCountry(String isoCountryCode) {
    _apply(computeIsNgTied(phone: _lastPhone, country: isoCountryCode));
  }

  void _apply(bool value) {
    if (value == _isNgTied) return;
    _isNgTied = value;
    notifyListeners();
    _persist();
    // Telemetry: the single most important Phase 9 metric — how much of the
    // base is diaspora/international. Fire-and-forget, never blocks UI.
    Analytics.I.logRegionResolved(isNgTied: value);
    Analytics.I.setRegionProperty(isNgTied: value);
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, _isNgTied ? 'NG' : 'INTL');
    } catch (e) {
      debugPrint('[RegionProvider] persist failed: $e');
    }
  }
}