// lib/core/app_scroll_behavior.dart
//
// PHASE 3 (web/desktop hardening)
//
// Flutter's default ScrollBehavior only allows DRAG scrolling with touch and
// trackpad — it deliberately excludes the mouse. On a desktop browser that makes
// scrollables feel stuck (no click-drag, and wheel scrolling can be flaky inside
// nested scroll areas). This behavior re-enables mouse + trackpad + stylus drag
// everywhere, so the feed and every other list scroll normally on desktop web.
//
// Wired once on MaterialApp.router via `scrollBehavior:`. Harmless on mobile
// (touch is already included; the extra device kinds simply never fire there).
//
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}