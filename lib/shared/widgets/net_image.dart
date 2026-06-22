// lib/shared/widgets/net_image.dart
//
// Platform-aware image widget.
//
// WHY THREE PATHS
//   Flutter web CanvasKit (default on desktop browsers) fetches images via XHR
//   which is subject to CORS. The CDN must respond with
//   Access-Control-Allow-Origin. If it doesn't, images silently fail.
//
//   The fix: on web we render an HTML <img> element via HtmlElementView.
//   The browser loads <img> natively without the CORS restriction that applies
//   to XHR/fetch. This works for both CanvasKit and HTML renderers.
//
//   On native (iOS/Android) CachedNetworkImage provides disk caching + shimmer.
//
// USAGE
//   NetImage(url: post.imageUrl, width: 300, height: 200)
//   NetImage.circle(url: user.avatar, radius: 20)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constraints/app_theme.dart';

// Web-only platform-view import — stubbed on non-web by the conditional.
import '_net_image_web.dart' if (dart.library.io) '_net_image_stub.dart';

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? errorChild;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const NetImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorChild,
    this.borderRadius,
    this.backgroundColor,
  });

  // Convenience constructor for circular avatar images
  static Widget circle({
    required String? url,
    required double radius,
    Widget? fallback,
  }) {
    if (url == null || url.isEmpty) {
      return _CircleFallback(radius: radius, child: fallback);
    }
    return ClipOval(
      child: NetImage(
        url: url,
        width: radius * 2,
        height: radius * 2,
      ),
    );
  }

  // Upgrades http:// to https:// to avoid mixed-content blocking on web.
  String get _safeUrl {
    if (kIsWeb && url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return errorChild ?? _BrokenIcon(color: backgroundColor);
    }

    final Widget image;

    if (kIsWeb) {
      // On web: render an HTML <img> element via platform view.
      // <img> tags are loaded by the browser natively and do NOT require CORS
      // headers — unlike Image.network which goes through XHR.
      image = buildWebImage(
        _safeUrl,
        width: width,
        height: height,
        fit: fit,
        backgroundColor: backgroundColor,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: _safeUrl,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, __) => _Shimmer(
          width: width,
          height: height,
          color: backgroundColor,
        ),
        errorWidget: (_, __, ___) =>
            errorChild ?? _BrokenIcon(color: backgroundColor),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final Color? color;
  const _Shimmer({this.width, this.height, this.color});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.surface,
      highlightColor: AppTheme.surfaceVariant,
      child: Container(
        width: width,
        height: height,
        color: color ?? AppTheme.surface,
      ),
    );
  }
}

class _BrokenIcon extends StatelessWidget {
  final Color? color;
  const _BrokenIcon({this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? AppTheme.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.broken_image_outlined,
        color: AppTheme.textMuted,
        size: 28,
      ),
    );
  }
}

class _CircleFallback extends StatelessWidget {
  final double radius;
  final Widget? child;
  const _CircleFallback({required this.radius, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: child ??
          Icon(Icons.person_outline, size: radius, color: AppTheme.textMuted),
    );
  }
}
