import 'dart:io';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class AppealWidget extends StatefulWidget {

  final OrderListProvider ? orderListProvider;
  final VendorCenterProvider ? vendorCenterProvider;
  final OrderModel order;
  final TextEditingController ctrl;
  const AppealWidget({super.key, this.orderListProvider, required this.order,
    required this.ctrl, this.vendorCenterProvider});

  @override
  State<AppealWidget> createState() => _AppealWidgetState();
}

class _AppealWidgetState extends State<AppealWidget> {

  File? _selectedImage;
  String?    _imageName;

  @override
  Widget build(BuildContext context) {
    TextEditingController ctrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Appeal Page',
            style: TextStyle(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      backgroundColor: VendorTheme.surface,

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Open Appeal',
                style: TextStyle(color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            // CAC Upload
            const Text('Upload Proof',
                style: TextStyle(
                    color: VendorTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage(),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: VendorTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedImage != null
                        ? VendorTheme.accent
                        : VendorTheme.divider,
                  ),
                ),
                child: _imageName != null
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description, color: VendorTheme.accent, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Document uploaded',
                            style: TextStyle(
                                color: VendorTheme.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(_imageName?? '',
                            style: const TextStyle(
                                color: VendorTheme.textMuted, fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text('Tap to change',
                            style: TextStyle(
                                color: VendorTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_file_outlined,
                        color: VendorTheme.textMuted, size: 36),
                    SizedBox(height: 8),
                    Text('Tap to upload proof for appeal',
                        style: TextStyle(
                            color: VendorTheme.textMuted, fontSize: 13)),
                    SizedBox(height: 4),
                    Text('JPG, PNG or PDF accepted',
                        style: TextStyle(
                            color: VendorTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Describe the issue. Escrow will be frozen until admin resolves.',
                style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 14),
            VTextField(controller: ctrl, label: 'Reason', maxLines: 3),
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
                    label: 'Submit',
                    color: VendorTheme.error,
                    onTap: () async {
                      Navigator.pop(context);
                      if ( widget.orderListProvider==null) {

                        final ok = await widget.vendorCenterProvider!.appealOrder(widget.order.id,
                            ctrl.text.trim());
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(widget.vendorCenterProvider!.error ?? 'Failed'), backgroundColor: VendorTheme.error),
                          );
                        }

                      }
                      final ok = await widget.orderListProvider!.appealOrder(widget.order.id, ctrl.text.trim());
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(widget.orderListProvider!.error ?? 'Failed'), backgroundColor: VendorTheme.error),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _imageName = picked.name;
    });
  }
}

