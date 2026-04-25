import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';

import '../models/order_model.dart';

class MetricsGrid extends StatelessWidget {
  final VendorMetrics metrics;
  const MetricsGrid({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Revenue', '₦${kFormatter.format(metrics.totalRevenue)}', Icons.payments_outlined, VendorTheme.primary),
      ('Rating', metrics.rating.toStringAsFixed(1), Icons.star_rounded, const Color(0xFFFFD700)),
      ('Completion', '${metrics.completionRate.toStringAsFixed(0)}%', Icons.check_circle_outline, VendorTheme.accent),
      ('Orders Done', '${metrics.totalCompletedOrders}', Icons.shopping_bag_outlined, VendorTheme.textSecondary),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.$3, color: item.$4, size: 20),
            const SizedBox(height: 6),
            Text(item.$2,
                style: TextStyle(color: item.$4, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(item.$1, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
          ],
        ),
      )).toList(),
    );
  }
}