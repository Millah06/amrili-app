import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../../social/services/social_api_service.dart';
import '../providers/order_provider.dart';
import '../providers/vendor_center_provider.dart';
import '../models/order_model.dart';
import '../widgets/shared_widgets.dart';

class AppealWidget extends StatefulWidget {
  final OrderListProvider? orderListProvider;
  final VendorCenterProvider? vendorCenterProvider;
  final OrderModel order;

  const AppealWidget({
    super.key,
    this.orderListProvider,
    this.vendorCenterProvider,
    required this.order,
  });

  @override
  State<AppealWidget> createState() => _AppealWidgetState();
}

class _AppealWidgetState extends State<AppealWidget> {
  // FIX: controller created once in state, not in build()
  final _reasonCtrl = TextEditingController();
  File? _proofImage;
  String? _proofName;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _proofImage = File(picked.path);
      _proofName = picked.name;
    });
  }

  Future<void> _submit() async {
    final reason = _reasonCtrl.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe the issue'),
          backgroundColor: VendorTheme.warning,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final orderId = widget.order.id;
    bool ok;

    // 1. Submit appeal reason
    if (widget.orderListProvider != null) {
      ok = await widget.orderListProvider!.appealOrder(orderId, reason);
    } else {
      ok = await widget.vendorCenterProvider!.appealOrder(orderId, reason);
    }

    if (!ok) {
      if (mounted) {
        final err = widget.orderListProvider?.error ??
            widget.vendorCenterProvider?.error ??
            'Failed to submit appeal';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: VendorTheme.error),
        );
      }
      setState(() => _submitting = false);
      return;
    }

    // 2. If proof image selected, upload and send as chat message
    if (_proofImage != null) {
      try {
        final api = widget.orderListProvider?.api ??
            widget.vendorCenterProvider!.api;
        final SocialApiService apiService = SocialApiService();

        final urls = await apiService.uploadPostImages(
            [XFile(_proofImage!.path)]);
        if (urls.isNotEmpty) {
          final chat = context.read<OrderChatProvider>();
          await chat.sendImage(
            orderId,
            urls.first,
            caption: '📎 Appeal proof attached',
          );
        }
      } catch (_) {
        // proof upload failure is non-fatal — appeal is already submitted
      }
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text(
          'Open Appeal',
          style: TextStyle(
              color: VendorTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Warning banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VendorTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VendorTheme.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: VendorTheme.warning, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Submitting an appeal will freeze the escrow until an admin resolves the dispute.',
                    style: TextStyle(color: VendorTheme.warning, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Proof upload
          const Text(
            'Upload Proof (optional)',
            style: TextStyle(
                color: VendorTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 110,
              decoration: BoxDecoration(
                color: VendorTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _proofImage != null
                      ? VendorTheme.accent
                      : VendorTheme.divider,
                  width: _proofImage != null ? 1.5 : 1,
                ),
              ),
              child: _proofImage != null
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_proofImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image selected',
                          style: TextStyle(
                              color: VendorTheme.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(_proofName ?? '',
                          style: const TextStyle(
                              color: VendorTheme.textMuted,
                              fontSize: 11)),
                      const SizedBox(height: 4),
                      const Text('Tap to change',
                          style: TextStyle(
                              color: VendorTheme.textMuted,
                              fontSize: 11)),
                    ],
                  ),
                ],
              )
                  : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file_outlined,
                      color: VendorTheme.textMuted, size: 32),
                  SizedBox(height: 8),
                  Text('Tap to attach evidence',
                      style: TextStyle(
                          color: VendorTheme.textMuted, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('JPG or PNG',
                      style: TextStyle(
                          color: VendorTheme.textMuted, fontSize: 11)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reason
          const Text(
            'Describe the issue *',
            style: TextStyle(
                color: VendorTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _reasonCtrl,
            maxLines: 4,
            style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Item was not delivered, wrong items sent...',
              hintStyle: const TextStyle(color: VendorTheme.textMuted),
              filled: true,
              fillColor: VendorTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VendorTheme.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: VendorTheme.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                const BorderSide(color: VendorTheme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 28),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VendorTheme.textSecondary,
                    side: const BorderSide(color: VendorTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VendorTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: VendorTheme.error.withOpacity(0.4),
                  ),
                  child: _submitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Submit Appeal',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}