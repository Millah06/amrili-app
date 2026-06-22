// Web implementation — renders an HTML <img> element via HtmlElementView.
// <img> is loaded by the browser natively; no CORS headers required.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildWebImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Color? backgroundColor,
}) {
  final objectFit = fit == BoxFit.contain
      ? 'contain'
      : fit == BoxFit.fill
          ? 'fill'
          : 'cover';

  // Each unique URL gets one registered factory (idempotent — registering the
  // same viewType twice is a no-op so long as the factory is the same).
  final viewType = 'net-img-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(viewType, (_) {
    final img = html.ImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = objectFit
      ..style.display = 'block';
    return img;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
