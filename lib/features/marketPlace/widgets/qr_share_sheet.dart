// lib/features/marketPlace/widgets/qr_share_sheet.dart
//
// PHASE 2 — QR SYSTEM  (PHASE 3 — web-safe export)
//
// One reusable bottom sheet behind every "Share Store" / "Share Product" button.
// It shows the branded AmrilQRCode and the share actions. Open it with
// `QRShareSheet.show(...)`.
//
// Actions map to the merchant requirements:
//   • Share link    → AppShareHelper (native text share with the https URL)
//   • Copy link     → clipboard
//   • Save QR       → save/download the branded QR card image
//   • Share QR      → share the branded QR card image
//
// (The spec lists "Download QR" and "Save QR" separately; on a phone both mean
// "save the image to the gallery", so we expose one save action rather than
// ship two identical buttons. On web that same action downloads the PNG.)
//
// PHASE 3: the save/share image actions now go through `core/platform/qr_export`
// instead of touching `gal` / `dart:io File` / `path_provider` directly, so this
// widget compiles and works on Flutter Web too:
//   • Save  → mobile: gallery (gal) · web: browser download
//   • Share → mobile: temp file + share sheet · web: in-memory XFile share
// The capture (RepaintBoundary → PNG bytes) is unchanged and platform-agnostic.
//
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../components/formatters.dart'; // AppShareHelper
import '../../../constraints/vendor_theme.dart';
import '../../../core/platform/qr_export.dart'; // PHASE 3: web-safe save/share
import 'amril_qr_code.dart';

enum QREntity { store, product, table }

class QRShareSheet extends StatefulWidget {
  /// The https link this QR encodes + the text-share uses.
  final String url;

  /// What we're sharing (drives the AppShareHelper call + copy + captions).
  final QREntity entity;

  /// The entity id (vendorId / menuItemId).
  final String entityId;

  /// Display name (store or product name).
  final String name;

  /// Optional store logo for the QR centre.
  final String? logoUrl;

  const QRShareSheet({
    super.key,
    required this.url,
    required this.entity,
    required this.entityId,
    required this.name,
    this.logoUrl,
  });

  /// Convenience opener.
  static Future<void> show(
      BuildContext context, {
        required String url,
        required QREntity entity,
        required String entityId,
        required String name,
        String? logoUrl,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QRShareSheet(
        url: url,
        entity: entity,
        entityId: entityId,
        name: name,
        logoUrl: logoUrl,
      ),
    );
  }

  @override
  State<QRShareSheet> createState() => _QRShareSheetState();
}

class _QRShareSheetState extends State<QRShareSheet> {
  final GlobalKey _qrKey = GlobalKey();
  bool _busy = false;

  String get _caption => switch (widget.entity) {
    QREntity.store => 'Scan to view this store',
    QREntity.product => 'Scan to view this item',
    QREntity.table => 'Scan to order at this table',
  };

  // Stable, descriptive base filename used by both save (gallery/download)
  // and share. The facade appends `.png` where the platform needs it.
  String get _fileName => 'amril_qr_${widget.entityId}';

  // Capture the branded QR card to PNG bytes. Platform-agnostic.
  Future<Uint8List?> _capture() async {
    final boundary =
    _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: VendorTheme.surface),
    );
  }

  Future<void> _shareLink() async {
    switch (widget.entity) {
      case QREntity.store:
        await AppShareHelper.shareStore(widget.entityId, storeName: widget.name);
      case QREntity.product:
        await AppShareHelper.shareProduct(widget.entityId,
            productName: widget.name);
      case QREntity.table:
      // table share needs both ids; fall back to plain link share.
        await AppShareHelper.shareStore(widget.entityId, storeName: widget.name);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    HapticFeedback.selectionClick();
    _toast('Link copied');
  }

  Future<void> _saveQr() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast('Could not render QR');
        return;
      }
      // PHASE 3: mobile → gallery (gal), web → browser download. The facade
      // owns the gallery-permission prompt and returns a platform-correct
      // message ("saved to gallery" vs "downloaded").
      final result = await saveQrImage(bytes, fileName: _fileName);
      _toast(result.message);
    } catch (_) {
      _toast('Couldn’t save QR');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareQrImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capture();
      if (bytes == null) {
        _toast('Could not render QR');
        return;
      }
      // PHASE 3: mobile → real temp file, web → in-memory XFile. Either way we
      // hand the resulting files to SharePlus so the share *text* stays here.
      final files = await buildQrShareFiles(bytes, fileName: _fileName);
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          text: '${widget.name}\n${widget.url}',
        ),
      );
    } catch (_) {
      _toast('Couldn’t share QR');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: VendorTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: VendorTheme.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Share',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 18),
              // The branded QR, captured for save/share.
              Center(
                child: RepaintBoundary(
                  key: _qrKey,
                  child: AmrilQRCode(
                    data: widget.url,
                    label: widget.name,
                    caption: _caption,
                    logoUrl: widget.logoUrl,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              // Actions
              _ActionRow(
                icon: Icons.ios_share_rounded,
                label: 'Share link',
                onTap: _shareLink,
              ),
              _ActionRow(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onTap: _copyLink,
              ),
              _ActionRow(
                icon: Icons.download_rounded,
                // PHASE 3: copy reads correctly on both platforms.
                label: 'Save QR',
                onTap: _saveQr,
                busy: _busy,
              ),
              _ActionRow(
                icon: Icons.qr_code_2_rounded,
                label: 'Share QR image',
                onTap: _shareQrImage,
                busy: _busy,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool busy;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: VendorTheme.primary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                if (busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: VendorTheme.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}