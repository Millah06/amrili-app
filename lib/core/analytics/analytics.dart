// lib/core/analytics/analytics.dart
//
// PHASE 9 — Analytics baseline.
// ─────────────────────────────────────────────────────────────────────────────
// WHY: every strategic bet made in Phase 9 planning (which features retain,
// whether diaspora users convert, whether the scanner gets used) is currently
// a guess — there is no usage data. This is the cheapest, highest-leverage
// thing in the phase: a thin wrapper over Firebase Analytics that gives screen
// views automatically + a handful of named events for the moments that matter.
//
// DESIGN:
//  · One singleton (`Analytics.I`) so call sites are trivial:
//      Analytics.I.logScan();  Analytics.I.logRegionResolved(isNgTied: true);
//  · `observer` plugs into MaterialApp.router's navigatorObservers, so EVERY
//    pushed route auto-logs a screen_view with zero per-screen code. (For the
//    4 bottom-bar tabs, which are PageView pages and not routes, call
//    logTabView() from the tab switch — wired in bootom_bar.)
//  · Fails safe: if Analytics isn't available (web before config, or a future
//    platform), every call is a no-op swallowed in try/catch. Telemetry must
//    never crash the app.
//  · No PII. We log region as a boolean-ish 'NG'|'INTL', never phone/email.
//
// SETUP REQUIRED (one-time, see PHASE9_PART3 doc):
//   1. pubspec: firebase_analytics: ^11.3.3 (matches your firebase_core major)
//   2. flutterfire configure already generated firebase_options — Analytics
//      needs no extra keys on mobile. On web it needs the measurementId, which
//      flutterfire writes into firebase_options if GA is enabled in the console.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class Analytics {
  Analytics._();
  static final Analytics I = Analytics._();

  FirebaseAnalytics? _fa;

  /// Call once in main(), AFTER Firebase.initializeApp().
  void init() {
    try {
      _fa = FirebaseAnalytics.instance;
    } catch (e) {
      debugPrint('[Analytics] init skipped: $e');
      _fa = null;
    }
  }

  /// Plug into MaterialApp.router(navigatorObservers: [Analytics.I.observer]).
  /// Returns a no-op-safe observer even if Analytics failed to init.
  NavigatorObserver get observer {
    final fa = _fa;
    if (fa == null) return NavigatorObserver();
    return FirebaseAnalyticsObserver(analytics: fa);
  }

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    final fa = _fa;
    if (fa == null) return;
    try {
      await fa.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('[Analytics] $name failed: $e');
    }
  }

  // ── Named events for the moments Phase 9 cares about ──────────────────────

  /// Which of the 4 bottom-bar tabs the user is on (PageView pages aren't
  /// routes, so the observer can't see them).
  Future<void> logTabView(String tab) => _log('tab_view', {'tab': tab});

  /// The scanner FAB — the app's universal verb. Tracking taps tells us
  /// whether the QR-first thesis holds.
  Future<void> logScanOpen() => _log('scan_open');

  /// Resolved region for this user. The single most important Phase 9 metric:
  /// how much of the base is diaspora/international.
  Future<void> logRegionResolved({required bool isNgTied}) =>
      _log('region_resolved', {'region': isNgTied ? 'NG' : 'INTL'});

  /// User set their home country via HomeCountrySheet (diaspora fix usage).
  Future<void> logHomeCountrySet(String iso) =>
      _log('home_country_set', {'country': iso});

  /// Entered the bills/top-ups surface from the wallet hub.
  Future<void> logBillsOpen() => _log('bills_open');

  /// Entered the marketplace from the wallet hub.
  Future<void> logMarketplaceOpen() => _log('marketplace_open');

  /// Optional: set the region as a user property so ALL events can be sliced
  /// NG vs INTL in the console. Call once after region resolves.
  Future<void> setRegionProperty({required bool isNgTied}) async {
    final fa = _fa;
    if (fa == null) return;
    try {
      await fa.setUserProperty(
          name: 'region', value: isNgTied ? 'NG' : 'INTL');
    } catch (e) {
      debugPrint('[Analytics] setRegionProperty failed: $e');
    }
  }
}