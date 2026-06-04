// lib/core/router/app_router.dart
//
// PHASE 1 — FOUNDATION
//
// The single GoRouter that replaces the old `MaterialApp(routes:{...}, home:...)`
// setup. Design constraints that drove every decision below (all verified
// against the real codebase):
//
//   1. `navigatorKey` is declared in `app.dart` and is reused by PIN/biometric
//      bottom sheets and `PushNotificationService`. GoRouter MUST be given that
//      SAME key, or those flows lose their navigator. We import it, we do not
//      redeclare it.
//
//   2. `BottomBar` is a custom swipeable PageView + CurvedNavigationBar with its
//      own guest gating. It CANNOT become a ShellRoute (a ShellRoute swaps a
//      child per-URL and can't host a PageView). So `/` simply builds
//      `BottomBar()` and everything else is pushed on top of it.
//
//   3. Every entry from the old `routes:` map is migrated here with the SAME
//      path string, so existing `Navigator.pushNamed(context, '/cable')`-style
//      calls keep resolving (call sites are swapped to `context.push('/cable')`).
//      The `home:` logic (BottomBar for done/guest, else WelcomeScreen) is moved
//      into `_globalRedirect`.
//
//   4. Deep-link routes (`/store`, `/product`, `/store/.../table/...`, `/join`,
//      `/order`) are public-by-URL; the backend decides what data a guest sees.
//      `/order` still requires auth (it's a private receipt).
//
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// navigatorKey lives in app.dart — import, never redeclare.
import '../../app.dart' show navigatorKey;
import '../../core/auth/auth_provider.dart';

// Shell + entry screens
import '../../components/bootom_bar.dart';
import '../../features/marketPlace/pages/qr_scanner_screen.dart';
import '../../features/marketPlace/utils/vendor_scope.dart';
import '../../features/social/pages/post_detail_page.dart';
import '../../features/social/pages/public_profile_page.dart';
import '../../screens/welcome_screen.dart';

// Utility screens (moved here from app.dart's old routes map)
import '../../features/bottom_navigation/services_screen.dart'; // HomeScreen
import '../../features/bottom_navigation/wallet/wallet_screen.dart'; // WalletScreen
import '../../screens/first_screen.dart';
import '../../features/utility/screens/utility_screens/cable_suscription.dart';
import '../../features/utility/screens/utility_screens/airtime_screen.dart';
import '../../features/utility/screens/utility_screens/airtime_gift.dart';
import '../../features/utility/screens/utility_screens/data_screen.dart';
import '../../features/utility/screens/utility_screens/electric_screen.dart';
import '../../features/utility/screens/utility_screens/waec_screen.dart';
import '../../features/utility/screens/utility_screens/jamb_screen.dart';
import '../../features/utility/screens/utility_screens/rechargepins_screen.dart';
import '../../features/utility/screens/utility_screens/internet_services.dart';

// Deep-link targets
import '../../features/marketPlace/pages/vendor_detail_page.dart';
import '../../features/marketPlace/pages/product_landing_page.dart';
import '../../features/marketPlace/pages/order_detail_landing_page.dart';
import '../../features/referral/pages/referral_landing_page.dart';
import '../../shared/pages/not_found_page.dart';

/// Set by main.dart BEFORE the router is first built, from a cold-start App Link.
/// Lets the very first routed frame be the deep-linked page (no '/' or welcome
/// flash). Defaults to '/' for a normal launch.
String bootDeepLinkLocation = '/';

/// Paths a logged-out, non-guest visitor is allowed to land on directly.
/// Everything here is either the entry shell, the welcome screen, or a
/// public deep-link read surface (the backend gates the actual payload).
bool _isPublicLocation(String location) {
  if (location == '/' || location == '/welcome') return true;
  // Deep-link reads are public by URL (guest-safe data comes from /web/* APIs).
  return location.startsWith('/store/') ||
      location.startsWith('/product/') ||
      location.startsWith('/join/') ||
      location.startsWith('/post/') ||   // ← add
      location.startsWith('/u/');        // ← add
}

/// Replicates the OLD `home:` decision as a router-wide redirect:
///   old: hasDone ? BottomBar : isGuest ? BottomBar : WelcomeScreen
/// here: if the visitor is neither authenticated nor a guest AND is trying to
/// reach a non-public location, bounce them to /welcome. Authenticated users
/// and guests pass through untouched (guest still sees the feed at `/`).

// BEFORE: _globalRedirect bounced any non-signed-in visitor off non-public
// locations to /welcome, and _requireAuth hard-bounced guests off /order, /wallet.

// AFTER: only first-time visitors at '/' go to welcome; deep links pass through
// (they self-mark guest); private routes are guarded by AuthRequired, not redirects.
String? _globalRedirect(BuildContext context, GoRouterState state) {
  final auth = context.read<AuthProvider>();
  final entered = auth.isAuthenticated || auth.isGuest;
  final loc = state.matchedLocation;

  // First-time visitor opening the app normally → welcome, not the bottom nav.
  if (loc == '/' && !entered) return '/welcome';

  // Never strand an entered user on the marketing screen.
  if (entered && loc == '/welcome') return '/';

  return null;
}

/// Per-route guard for surfaces that require a REAL (non-guest) account.
/// Used for the private order receipt. Guests are pushed to /welcome.


final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey, // same key the PIN sheets + FCM use
  initialLocation: bootDeepLinkLocation,
  redirect: _globalRedirect,
  debugLogDiagnostics: false,

  routes: [
    // ── Entry shell ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) => const BottomBar(),
    ),
    GoRoute(
      path: '/welcome',
      name: WelcomeScreen.id, // 'welcome'
      builder: (context, state) => const WelcomeScreen(),
    ),

    // ── Migrated from the old routes: map ─────────────────────────────────────
    // Home + Wallet are also tabs inside BottomBar, but the old map registered
    // them as named routes too; we keep them reachable. We attach `name:` equal
    // to the old `.id` so any legacy pushNamed(HomeScreen.id) can be fixed to
    // context.pushNamed('home') without changing the id constant.
    GoRoute(
      path: '/home',
      name: HomeScreen.id, // 'home'
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/wallet',
      name: WalletScreen.id, // 'wallet'
      // redirect: _requireAuth, // wallet is account-only
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: '/first',
      name: FirstScreen.id, // 'First'
      builder: (context, state) => const FirstScreen(),
    ),

    // Utility screens — identical path strings to the old map.
    GoRoute(path: '/cable', builder: (c, s) => CableSubscription()),
    GoRoute(path: '/airtimeNormal', builder: (c, s) => AirtimeScreen()),
    GoRoute(path: '/airtimeGift', builder: (c, s) => AirtimeGift()),
    GoRoute(path: '/data', builder: (c, s) => DataScreen()),
    GoRoute(path: '/electric', builder: (c, s) => ElectricScreen()),
    GoRoute(path: '/waec', builder: (c, s) => WaecServices()),
    GoRoute(path: '/jamb', builder: (c, s) => JambServices()),
    GoRoute(path: '/rechargePins', builder: (c, s) => RechargePinsBusiness()),
    GoRoute(path: '/internetServices', builder: (c, s) => InternetServicesScreen()),

    // ── Deep links ────────────────────────────────────────────────────────────
    // Store → reuse the existing VendorDetailPage (already takes `vendorId`).
    GoRoute(
      path: '/store/:storeId',
      builder: (c, s) =>
          VendorScope(child: VendorDetailPage(vendorId: s.pathParameters['storeId']!)),
    ),

    // Store + table → Phase 6 wires the tableId into VendorDetailPage/checkout.
    // For Phase 1 the table URL must still RESOLVE (so App Link verification and
    // the SEO worker have a real route) — it opens the store. The tableId is
    // captured and forwarded as an extra so Phase 6 can pick it up without a
    // route change.
    GoRoute(
      path: '/store/:storeId/table/:tableId',
      builder: (c, s) => VendorScope(
        child: VendorDetailPage(
          vendorId: s.pathParameters['storeId']!,
          // NOTE (Phase 6): add `tableId:` param to VendorDetailPage and read
          // s.pathParameters['tableId'] here. Forwarded via `extra` for now.
        ),
      ),
    ),

    // Product → standalone landing page (in-app the product is a bottom sheet,
    // but a deep link needs a real full-screen destination).
    GoRoute(
      path: '/product/:productId',
      builder: (c, s) =>
          VendorScope(child: ProductLandingPage(menuItemId: s.pathParameters['productId']!)),
    ),

    // Referral join → captures the code, shows a friendly landing + CTA.
    GoRoute(
      path: '/join/:referralCode',
      builder: (c, s) =>
          ReferralLandingPage(referralCode: s.pathParameters['referralCode']!),
    ),

    // Private order receipt → requires a real account.
    GoRoute(
      path: '/order/:orderId',
      // redirect: _requireAuth,
      builder: (c, s) =>
          OrderDetailLandingPage(orderId: s.pathParameters['orderId']!),
    ),

    // Social deep links
    GoRoute(
      path: '/post/:postId',
      builder: (c, s) => PostDetailPage(postId: s.pathParameters['postId']!),
    ),
    GoRoute(
      path: '/u/:userHandle',
      builder: (c, s) =>
          PublicProfilePage(userHandle: s.pathParameters['userHandle']!),
    ),

    // In-app QR scanner (pushed from the "Scan" buttons)
    GoRoute(
      path: '/scan',
      builder: (c, s) => const QrScannerScreen(),
    ),

  ],

  // Any unmatched path (bad QR, stale link) lands on a branded 404, never a
  // red screen.
  errorBuilder: (context, state) =>
      NotFoundPage(attemptedLocation: state.uri.toString()),
);