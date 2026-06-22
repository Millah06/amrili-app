// Stub for non-web platforms — this function is never called on native
// (the kIsWeb branch in NetImage guards it), but Dart needs the symbol to
// compile on all targets.
import 'package:flutter/material.dart';

Widget buildWebImage(
  String url, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Color? backgroundColor,
}) =>
    const SizedBox.shrink();
