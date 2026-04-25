import 'dart:io';
import 'dart:ui' as ui;
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/widgets/share_card.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../components/swicht.dart';
import '../../../constraints/vendor_theme.dart';

import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../models/vendor_model.dart';
import '../pages/add_product_item_page.dart';
import 'navigation.dart';

class ProductManageCard extends StatelessWidget {
  final MenuItemModel item;
  final VendorCenterProvider p;

  const ProductManageCard({super.key, required this.item, required this.p});

  // Share card key for RepaintBoundary capture
  final GlobalKey _shareKey = const GlobalObjectKey('share');

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + upload tap
              GestureDetector(
                // onTap: () => _uploadImage(context),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: item.firstImage.isNotEmpty
                          ? Image.network(item.firstImage, width: 64, height: 64, fit: BoxFit.cover)
                          : Container(
                        width: 64, height: 64,
                        color: VendorTheme.surfaceVariant,
                        child: const Icon(Icons.add_photo_alternate_outlined, color: VendorTheme.textMuted),
                      ),
                    ),
                    if (item.images.length > 1)
                      Positioned(
                        bottom: 4,
                        right: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.62),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library_outlined,
                                  color: Colors.white, size: 9),
                              const SizedBox(width: 2),
                              Text(
                                '${item.images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: VendorTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text('₦${kFormatter.format(item.price)}',
                        style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              // Toggle availability
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.isAvailable ? VendorTheme.accent.withOpacity(0.15) : VendorTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isAvailable ? 'Available' : 'Unavailable',
                    style: TextStyle(
                        color: item.isAvailable ? VendorTheme.accent : VendorTheme.error,
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10,),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                  onTap: () => _shareCard(context),
                  child: Row(
                    children: [
                      const Text('Toggle Availability',
                        style: TextStyle(fontSize: 12, color: VendorTheme.textMuted,),),
                      const SizedBox(width: 4,),
                      const Icon(Icons.info_outline_rounded, color: VendorTheme.textMuted, size: 15),
                    ],
                  )
              ),
              TinySwitch(value: item.isAvailable, onChanged: (_) async {
                showDialog(context: context,
                    barrierDismissible: false, builder: (_) => const Dialog(
                      backgroundColor: VendorTheme.background,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: VendorTheme.circularProgressColor,),
                            SizedBox(width: 16),
                            Text("Updating status..."),
                          ],
                        ),
                      ),
                    ));
                await p.updateMenuItem(item.id, {'isAvailable': !item.isAvailable});

                if (context.mounted) {
                  Navigator.pop(context);
                }

              }),
              // Share
            ],
          ),
          const SizedBox(height: 10,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Others',
                style: TextStyle(fontSize: 12, color: VendorTheme.textMuted, ),),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  // // Delete
                  // GestureDetector(
                  //   onTap: () => _confirmDelete(context),
                  //   child: const Icon(Icons.delete_outline, color: VendorTheme.error, size: 18),
                  // ),
                  // Edit
                  GestureDetector(
                    onTap: () => vendorPush(context, AddMenuItemPage(existingItem: item,)),
                    child:  Row(
                      children: [
                        const Text('Edit', style: TextStyle(fontSize: 12),),
                        const SizedBox(width: 4,),
                        const Icon(Icons.edit, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(
                      height: 15,
                      child: VerticalDivider(color: VendorTheme.textMuted,
                        width: 20, thickness: 1, )),
                  // Share
                  GestureDetector(
                      onTap: () => _shareCard(context),
                      child: Row(
                        children: [
                          const Text('Share', style: TextStyle(fontSize: 12),),
                          const SizedBox(width: 4,),
                          const Icon(Icons.share_outlined, color: Colors.white, size: 18),
                        ],
                      )
                  ),


                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Delete Item?',
                  style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('Remove "${item.name}" from your menu?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Cancel',
                      color: VendorTheme.surfaceVariant,
                      textColor: VendorTheme.textSecondary,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VButton(
                      label: 'Delete',
                      color: VendorTheme.error,
                      onTap: () async {
                        Navigator.pop(context);
                        await p.deleteMenuItem(item.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareCard(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The share card itself — captured by RepaintBoundary
              RepaintBoundary(
                key: _shareKey,
                child: ShareCard(item: item, vendorName: p.myVendor?.name ?? ''),
              ),
              const SizedBox(height: 20),
              VButton(
                label: 'Share',
                icon: Icons.share,
                onTap: () async {
                  Navigator.pop(context);
                  await _captureAndShare(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureAndShare(BuildContext context) async {
    try {
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final uint8 = bytes.buffer.asUint8List();
      await Share.shareXFiles(
        [XFile.fromData(uint8, mimeType: 'image/png', name: '${item.name}.png')],
        text: '${item.name} — ₦${item.price.toStringAsFixed(0)}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e'), backgroundColor: VendorTheme.error),
        );
      }
    }
  }
}