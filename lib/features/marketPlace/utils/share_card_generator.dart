import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../constraints/vendor_theme.dart';
import '../models/vendor_model.dart';


// ─── SHARE CARD GENERATOR (client-side) ─────────────────────────────────────
// Renders a branded share card and allows sharing it.

class ShareCardGenerator extends StatefulWidget {
  final VendorModel vendor;
  final MenuItemModel item;

  const ShareCardGenerator({super.key, required this.vendor, required this.item});

  @override
  State<ShareCardGenerator> createState() => _ShareCardGeneratorState();
}

class _ShareCardGeneratorState extends State<ShareCardGenerator> {
  final _repaintKey = GlobalKey();
  bool _capturing = false;

  Future<void> _captureAndShare() async {
    setState(() => _capturing = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
      await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // TODO: use share_plus package:
      // final bytes = byteData.buffer.asUint8List();
      // final file = XFile.fromData(bytes, mimeType: 'image/png', name: '${widget.item.name}.png');
      // await Share.shareXFiles([file], text: '${widget.vendor.name} - ${widget.item.name}');

      // For now, show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Share card captured! Add share_plus to share.'),
              backgroundColor: VendorTheme.accent),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Share Item',
              style: TextStyle(
                  color: VendorTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 16),

          // The shareable card
          RepaintBoundary(
            key: _repaintKey,
            child: _ShareCard(vendor: widget.vendor, item: widget.item),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _capturing ? null : _captureAndShare,
              icon: _capturing
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share, color: Colors.white, size: 18),
              label: const Text('Share',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  final VendorModel vendor;
  final MenuItemModel item;

  const _ShareCard({required this.vendor, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VendorTheme.primary.withOpacity(0.3), width: 1.5),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor branding row
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  vendor.logo,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 44,
                    height: 44,
                    color: VendorTheme.surfaceVariant,
                    child: const Icon(Icons.storefront,
                        color: VendorTheme.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name,
                      style: const TextStyle(
                          color: VendorTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(vendor.vendorType.label,
                      style: const TextStyle(
                          color: VendorTheme.primary, fontSize: 11)),
                ],
              ),
              const Spacer(),
              if (vendor.verified)
                const Icon(Icons.verified, color: VendorTheme.accent, size: 18),
            ],
          ),

          const SizedBox(height: 16),

          // Item image
          if (item.firstImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.firstImage,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 14),

          // Item info
          Text(item.name,
              style: const TextStyle(
                  color: VendorTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: VendorTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),

          // Price
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: VendorTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('₦${item.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: VendorTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22)),
          ),

          const SizedBox(height: 14),

          // App branding
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: VendorTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('Powered by YourApp',
                  style: TextStyle(
                      color: VendorTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}