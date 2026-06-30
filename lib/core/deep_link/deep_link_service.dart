// lib/core/deep_link/deep_link_service.dart
//
// PHASE 1 — FOUNDATION
//
// Listens for inbound App Links / Universal Links and routes them through
// GoRouter. Three entry conditions are handled:
//   • COLD start  — app launched by tapping a link → `getInitialLink()`.
//   • WARM/HOT    — link tapped while app is alive/backgrounded → `uriLinkStream`.
//
// Routing rule: we ONLY act on links whose host is our web origin (amril.app /
// www.amril.app). Anything else (e.g. the Play-Store share link produced by
// `AppLinkHandler`) is ignored so we never hijack unrelated links. We forward
// just the PATH (+ query) into GoRouter, because the route table is defined in
// web-path terms (`/store/:id`, `/product/:id`, ...).
//
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import '../router/app_router.dart';
// add imports
import 'package:provider/provider.dart';
import '../../app.dart' show navigatorKey;
import '../auth/auth_provider.dart';

class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  /// Hosts we own. A universal/app link must match one of these to be routed.
  static const Set<String> _ownHosts = {'amril.app', 'www.amril.app'};

  /// Call once, after the first frame, from `app.dart`.
  Future<void> init() async {
    // App/Universal Links are a NATIVE concern. On web the browser URL + GoRouter
    // already drive routing, and app_links emits the current page URL (e.g. "/app/"),
    // which would wrongly route there. So: do nothing on web.
    if (kIsWeb) return;                 // ← ADD THIS LINE (kIsWeb already imported)
    if (_started) return;
    _started = true;
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => debugPrint('DeepLinkService: stream error — $e'),
    );
  }

  void _handleUri(Uri uri) {
    if (!_ownHosts.contains(uri.host)) {
      debugPrint('DeepLinkService: ignoring foreign host ${uri.host}');
      return;
    }

    // Don't disrupt a deep-link visitor: if they have no account and aren't yet a
    // guest, mark them a guest so the router lets them through and gated actions
    // (like/comment) show the sign-in sheet instead of bouncing to welcome.
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      final auth = ctx.read<AuthProvider>();
      if (!auth.isAuthenticated && !auth.isGuest) auth.continueAsGuest();
    }

    final String location =
    uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    debugPrint('DeepLinkService: routing → $location');
    appRouter.go(location.isEmpty ? '/' : location);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }
}