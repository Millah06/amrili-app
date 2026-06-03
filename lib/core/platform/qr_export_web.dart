// ─────────────────────────────────────────────────────────────────────────────
// qr_export_web.dart  — Flutter Web implementation of the QR export facade.
//
// Selected by `qr_export.dart` only when `dart.library.html` is available
// (i.e. a web build). It is NEVER compiled on mobile, so using `dart:html` here
// is safe and keeps `dart:io` out of the web bundle entirely.
//
// • Save  → there is no "gallery" on the web, so we trigger a normal browser
//           file download (anchor + object URL) into the user's Downloads.
// • Share → `XFile.fromData` builds an in-memory file; on browsers that support
//           the Web Share API (level 2, with files) this surfaces the native
//           share sheet. Browsers without it fall back to share_plus's behaviour.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'qr_export.dart' show QrSaveResult;

/// Trigger a browser download of the QR PNG into the user's Downloads folder.
Future<QrSaveResult> saveQrImage(
    Uint8List pngBytes, {
      required String fileName,
    }) async {
  try {
    final blob = html.Blob([pngBytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    // A transient anchor element is the standard way to start a download.
    final anchor = html.AnchorElement(href: url)
      ..download = '$fileName.png'
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    // Free the object URL once the download has been kicked off.
    html.Url.revokeObjectUrl(url);
    return const QrSaveResult(saved: true, message: 'QR code downloaded');
  } catch (_) {
    return const QrSaveResult(saved: false, message: 'Could not download QR code');
  }
}

/// Build an in-memory [XFile] for the Web Share API (no filesystem on web).
Future<List<XFile>> buildQrShareFiles(
    Uint8List pngBytes, {
      required String fileName,
    }) async {
  return [
    XFile.fromData(
      pngBytes,
      mimeType: 'image/png',
      name: '$fileName.png',
    ),
  ];
}