// ─────────────────────────────────────────────────────────────────────────────
// qr_export_io.dart  — mobile / desktop implementation of the QR export facade.
//
// Selected by `qr_export.dart` on any target that has `dart:io`
// (Android, iOS, macOS, Windows, Linux). NEVER imported in a web build, so it
// is safe to use `dart:io`, `path_provider`, and `gal` here.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'qr_export.dart' show QrSaveResult;

/// Save the QR PNG to the device photo gallery via `gal`.
///
/// `gal` handles the platform permission prompt internally and throws
/// `GalException` if the user denies it — we surface that as a failed result
/// rather than letting it crash the share sheet.
Future<QrSaveResult> saveQrImage(
    Uint8List pngBytes, {
      required String fileName,
    }) async {
  try {
    // `gal` saves raw image bytes straight to the gallery — no temp file needed.
    await Gal.putImageBytes(pngBytes, name: fileName);
    return const QrSaveResult(saved: true, message: 'QR code saved to your gallery');
  } on GalException catch (e) {
    // Most common cause: gallery permission denied on Android/iOS.
    return QrSaveResult(saved: false, message: 'Could not save QR: ${e.type.message}');
  } catch (_) {
    return const QrSaveResult(saved: false, message: 'Could not save QR code');
  }
}

/// Write the PNG to a temp file and wrap it as an [XFile] for sharing.
///
/// A real `file://` path is used (rather than in-memory data) because some
/// Android share targets only accept file URIs.
Future<List<XFile>> buildQrShareFiles(
    Uint8List pngBytes, {
      required String fileName,
    }) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$fileName.png');
  await file.writeAsBytes(pngBytes, flush: true);
  return [XFile(file.path, mimeType: 'image/png', name: '$fileName.png')];
}