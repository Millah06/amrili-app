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
    if (_started) return; // idempotent — safe to call again on hot reload
    _started = true;

    // 1) COLD start: did a link launch the app?
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (e) {
      debugPrint('DeepLinkService: initial link error — $e');
    }

    // 2) WARM/HOT: links arriving while the app is running.
    _sub = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (Object e) => debugPrint('DeepLinkService: stream error — $e'),
    );
  }

  void _handleUri(Uri uri) {
    // Guard: only route links that belong to us.
    if (!_ownHosts.contains(uri.host)) {
      debugPrint('DeepLinkService: ignoring foreign host ${uri.host}');
      return;
    }

    // Build a router location from path (+ query if present). GoRouter expects
    // a leading slash; `uri.path` already provides it (defaults to '/').
    final String location =
    uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

    debugPrint('DeepLinkService: routing → $location');
    // `go` (not `push`) so a fresh link replaces rather than stacks endlessly.
    appRouter.go(location.isEmpty ? '/' : location);
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }
}