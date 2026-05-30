import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// About tab placeholder (shown before profile loads — shows cached or skeleton)
// ─────────────────────────────────────────────────────────────────────────────

class AboutPlaceholder extends StatelessWidget {
  final Future<void> Function() onRefresh;
  const AboutPlaceholder({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF177E85),
      backgroundColor: const Color(0xFF1E293B),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _SkeletonLine(width: 200, height: 16),
          const SizedBox(height: 12),
          _SkeletonLine(width: double.infinity, height: 52),
          const SizedBox(height: 12),
          _SkeletonLine(width: double.infinity, height: 52),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonLine({required this.width, required this.height});
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8),
    ),
  );
}