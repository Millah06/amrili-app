// lib/core/adaptive/breakpoints.dart
//
// Phase 12 (Track B) — Single place for every responsive sizing decision.
//
// WHY A CENTRAL FILE
//   Before this, magic numbers like `maxWidth: 640` were sprinkled across
//   individual screens (FeedScreen, vendor pages, etc.) and would drift apart
//   when any screen was updated without looking at the others. One file means
//   one grep to find every breakpoint in the app.
//
// BREAKPOINT RATIONALE
//   Mobile  < 600 px — single column, full-bleed; the default Flutter target.
//   Tablet  600–1023 px — wider but still touch-first; some grids go 2-col.
//   Desktop ≥ 1024 px — mouse/keyboard; side rail replaces bottom bar;
//                        content is centred in a max-width column.
//
// MAX-WIDTH COLUMNS
//   feedWidth    640 px — PostCard reads oddly wider than this; matches
//                          the column the FeedScreen already constrained to.
//   contentWidth 900 px — marketplace listings, profiles, wider data tables.
//   formWidth    480 px — single input column; TextFields stretch on web
//                          otherwise (known Phase 8 issue).

import 'package:flutter/material.dart';

// Using an abstract class with a private constructor prevents instantiation
// while keeping `static` without needing the `final` modifier.
abstract final class AmrilBreakpoints {
  static const double mobile  = 600;
  static const double tablet  = 1024;

  static const double feedWidth    = 640;  // social feed, post detail
  static const double contentWidth = 900;  // marketplace, profile, settings
  static const double formWidth    = 480;  // auth, checkout, utility forms

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

// ─────────────────────────────────────────────────────────────────────────────
// ContentColumn — convenience wrapper that centres a child inside a max-width
// column. Replaces `Center(child: ConstrainedBox(constraints: BoxConstraints(
// maxWidth: x), child: Padding(..., child: ...)))` at every call site.
//
// Usage:
//   ContentColumn(maxWidth: AmrilBreakpoints.feedWidth, child: feedList)
// ─────────────────────────────────────────────────────────────────────────────
class ContentColumn extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ContentColumn({
    super.key,
    required this.child,
    this.maxWidth = AmrilBreakpoints.contentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding != EdgeInsets.zero
            ? Padding(padding: padding, child: child)
            : child,
      ),
    );
  }
}
