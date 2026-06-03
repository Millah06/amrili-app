// lib/core/constant/api_constants.dart
//
// PHASE 1 — FOUNDATION
//
// Single source of truth for the two base URLs the app talks to. Today every
// service (`ApiService`, `DioClient`, `WithdrawalApiServices`, `SocialApiService`)
// hardcodes the Render URL inline. We are NOT mass-rewriting those services in
// Phase 1 (that would be a large, risky blast radius). Instead we introduce this
// class so that:
//   • all NEW code (deep-link landing pages, QR builder, payment engine) reads
//     its base URL from ONE place, and
//   • when DNS cutover to `api.amril.app` happens, you flip a single line here
//     and migrate the legacy services over to `ApiConstants.baseUrl` gradually.
//
// ──────────────────────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._(); // never instantiated — static-only holder

  /// REST API origin.
  ///
  /// CURRENT: live Render deployment (matches what the legacy services already
  /// point at, so nothing breaks the moment new code starts using this).
  ///
  /// AFTER DNS CUTOVER: change the value below to `https://api.amril.app`
  /// once the `api.amril.app` CNAME → Render is verified and serving.
  /// That single edit migrates every consumer of `ApiConstants.baseUrl`.
  static const String baseUrl = 'https://api.amril.app';

  /// Public web origin (Flutter Web on Cloudflare Pages). This is the host that
  /// appears in every shareable deep link: `https://amril.app/store/123`, etc.
  /// It must match the host declared in the Android App Links intent-filter and
  /// the iOS AASA file, otherwise universal links will not verify.
  static const String webBaseUrl = 'https://amril.app';

  // ── Shareable deep-link builders ──────────────────────────────────────────
  // Kept here (not in the share helper) so both the share sheet AND the QR code
  // generator (Phase 2) build identical URLs from the same rules. QR codes MUST
  // encode HTTPS web URLs — never a custom `amril://` scheme — so that scanning
  // works in any camera app even when Amril is not installed.

  static String storeUrl(String vendorId) => '$webBaseUrl/store/$vendorId';

  static String productUrl(String menuItemId) =>
      '$webBaseUrl/product/$menuItemId';

  static String tableUrl(String vendorId, String tableId) =>
      '$webBaseUrl/store/$vendorId/table/$tableId';

  static String postUrl(String postId) => '$webBaseUrl/post/$postId';

  static String profileUrl(String userHandle) => '$webBaseUrl/u/$userHandle';

  static String referralUrl(String referralCode) =>
      '$webBaseUrl/join/$referralCode';
}