import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';

import '../models/vendor_model.dart';

class ShareCard extends StatelessWidget {
  final MenuItemModel item;
  final String vendorName;

  const ShareCard({required this.item, required this.vendorName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendorTheme.primary.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.firstImage.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.firstImage,
                width: 280, height: 160, fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 280, height: 160,
              decoration: const BoxDecoration(
                color: Color(0xFF334155),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Icon(Icons.fastfood, color: VendorTheme.textMuted, size: 56),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(item.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₦${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.bold, fontSize: 22)),
                    Text(vendorName,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}