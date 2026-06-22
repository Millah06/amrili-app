import 'package:everywhere/features/marketPlace/widgets/trust_badge.dart';
import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import '../../../constraints/vendor_theme.dart';
import '../models/vendor_model.dart';

class VendorCard extends StatelessWidget {
  final VendorModel vendor;
  final VoidCallback onTap;

  const VendorCard({super.key, required this.vendor, required this.onTap});

  Color get _typeColor {
    switch (vendor.vendorType) {
      case VendorType.restaurant: return const Color(0xFFFF6B6B);
      case VendorType.grocery:    return const Color(0xFF10B981);
      case VendorType.drinks:     return const Color(0xFF3B82F6);
      case VendorType.retail:     return const Color(0xFFA855F7);
    }
  }

  double? get _lowestFee {
    final fees = vendor.branches.expand((b) => b.deliveryZones.map((z) => z.deliveryFee));
    if (fees.isEmpty) return null;
    return fees.reduce((a, b) => a < b ? a : b);
  }

  int? get _fastestTime {
    if (vendor.branches.isEmpty) return null;
    return vendor.branches.map((b) => b.estimatedDeliveryTime).reduce((a, b) => a < b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner / logo area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  // Background banner
                  vendor.coverPhoto.isNotEmpty
                      ? NetImage(
                    url: vendor.coverPhoto,
                    width: double.infinity, height: 90, fit: BoxFit.cover,
                    errorChild: _logoPlaceholder(),
                  ): Container(
                    height: 90,
                    width: double.infinity,
                    color: _typeColor.withValues(alpha: 0.12),
                  ),
                  // Type badge top-right
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vendor.vendorType.label,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  // Verified badge
                  Positioned(
                      top: 10,
                      left: 10,
                      child:
                      TrustBadge(level: vendor.trustLevel ?? 0,
                          verifiedFallback: vendor.verified)
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo overlapping banner
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vendor.logo.isNotEmpty
                          ? NetImage(
                        url: vendor.logo,
                        width: 52, height: 52, fit: BoxFit.cover,
                        errorChild: _logoPlaceholder(),
                      )
                          : _logoPlaceholder(),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.name,
                            style: const TextStyle(
                                color: VendorTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(vendor.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: VendorTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 10),
                        // Stats row
                        Row(
                          children: [
                            _stat(Icons.star_rounded, const Color(0xFFFFD700),
                                vendor.rating.toStringAsFixed(1)),
                            const SizedBox(width: 14),
                            _stat(Icons.check_circle_outline, VendorTheme.accent,
                                '${vendor.completionRate.toStringAsFixed(0)}%',
                                label: 'completion'),
                            const SizedBox(width: 14),
                            _stat(Icons.shopping_bag_outlined, VendorTheme.textMuted,
                                '${vendor.totalCompletedOrders}',
                                label: 'orders'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // In _vendorInfo(), add to the badges row:
                        if (vendor.vendorAllowsPod)
                          _stat(Icons.payments_outlined, VendorTheme.accent, 'Pay on Delivery'),
                        const SizedBox(height: 10,),
                        // Delivery row
                        Row(
                          children: [
                            if (_lowestFee != null) ...[
                              const Icon(Icons.delivery_dining, size: 14, color: VendorTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('From ₦${_lowestFee!.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      color: VendorTheme.textSecondary, fontSize: 12)),
                              const SizedBox(width: 14),
                            ],
                            if (_fastestTime != null) ...[
                              const Icon(Icons.access_time, size: 14, color: VendorTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('~$_fastestTime min',
                                  style: const TextStyle(
                                      color: VendorTheme.textSecondary, fontSize: 12)),
                            ],
                            const Spacer(),
                            Text('${vendor.branches.length} branch${vendor.branches.length == 1 ? '' : 'es'}',
                                style: const TextStyle(
                                    color: VendorTheme.textMuted, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, Color color, String value, {String? label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label != null ? '$value $label' : value,
          style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _logoPlaceholder() => Container(
    width: 52, height: 52,
    color: VendorTheme.surfaceVariant,
    child: const Icon(Icons.storefront, color: VendorTheme.textMuted, size: 26),
  );
}