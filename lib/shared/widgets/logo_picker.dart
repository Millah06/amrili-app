import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constraints/vendor_theme.dart';
import '../../features/marketPlace/widgets/shared_widgets.dart';

// ─── Logo Picker ──────────────────────────────────────────────────────────────

class LogoPicker extends StatelessWidget {

  final bool? logo;
  final String? existingUrl;
  final File? pendingImage;
  final void Function(File, String) onPick;

  const LogoPicker({super.key,
    required this.existingUrl,
    required this.pendingImage,
    required this.onPick,
    this.logo = true
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
      child: Row(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VendorTheme.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: pendingImage != null
                  ? Image.file(pendingImage!,
                  fit: BoxFit.cover)
                  : existingUrl != null && existingUrl!.isNotEmpty
                  ? CachedNetworkImage(
                  imageUrl: existingUrl!, fit: BoxFit.cover)
                  : Icon(logo! ? Icons.storefront : Icons.person,
                  color: VendorTheme.textMuted, size: 32),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(logo! ? 'Vendor Logo' : 'Profile Picture',
                    style: TextStyle(
                        color: VendorTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Square image, min 200×200. Shown on your card and menu.',
                    style: TextStyle(
                        color: VendorTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 8),
                VSmallButton(
                  label:  logo!? 'Change Logo' : 'Change Profile Picture',
                  color: VendorTheme.primary.withOpacity(0.15),
                  textColor: VendorTheme.primary,
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 85);
                    if (picked == null) return;
                    onPick(File(picked.path), picked.name);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}