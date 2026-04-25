import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constraints/vendor_theme.dart';

// ─── Cover Picker ─────────────────────────────────────────────────────────────

class CoverPicker extends StatelessWidget {
  final String? existingUrl;
  final File? pendingImage;
  final void Function(File, String) onPick;

  const CoverPicker({
    required this.existingUrl,
    required this.pendingImage,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);
        if (picked == null) return;
        onPick(File(picked.path), picked.name);
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (pendingImage != null)
                Image.file(pendingImage!,
                    fit: BoxFit.cover)
              else if (existingUrl != null && existingUrl!.isNotEmpty)
                CachedNetworkImage(imageUrl: existingUrl!, fit: BoxFit.cover)
              else
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.panorama_outlined,
                        color: VendorTheme.textMuted, size: 36),
                    SizedBox(height: 6),
                    Text('Tap to add cover photo',
                        style: TextStyle(
                            color: VendorTheme.textMuted, fontSize: 12)),
                    Text('Recommended: 1200×400',
                        style: TextStyle(
                            color: VendorTheme.textMuted, fontSize: 11)),
                  ],
                ),
              // Edit overlay
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      const Text('Change',
                          style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}