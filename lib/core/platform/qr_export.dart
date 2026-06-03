// ─────────────────────────────────────────────────────────────────────────────
// qr_export.dart  — Phase 3 (Flutter Web) platform abstraction
//
// WHY THIS EXISTS
// The QR share sheet (`qr_share_sheet.dart`) and `product_manage_card.dart`
// originally used `dart:io` (File + path_provider) to write a temporary PNG and
// `gal` to save to the gallery. Neither works on Flutter Web:
//   • `dart:io File` has no real filesystem on web.
//   • `gal` has no web implementation (gallery saving is a mobile concept).
//
// Rather than scatter `if (kIsWeb)` branches across the UI — which would still
// force `dart:io` to be *imported* in a web build (it co-compiles badly with
// `dart:html`) — we centralise the platform split with CONDITIONAL IMPORTS.
// The Dart compiler picks exactly one implementation per target:
//   • mobile/desktop → qr_export_io.dart   (dart:io + path_provider + gal)
//   • web            → qr_export_web.dart   (browser blob download)
//
// The UI calls these two functions and never touches dart:io / gal / dart:html
// directly, so it compiles cleanly on every platform.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

// Conditional import: the body comes from the IO or Web file depending on target.
import 'qr_export_io.dart'
if (dart.library.html) 'qr_export_web.dart' as impl;

/// Result of a "save QR" action, so the UI can show the right snackbar copy.
class QrSaveResult {
  /// True if the bytes reached a place the user can find them
  /// (device gallery on mobile, Downloads folder on web).
  final bool saved;

  /// Platform-appropriate, user-facing message
  /// (e.g. "Saved to gallery" vs "Downloaded").
  final String message;

  const QrSaveResult({required this.saved, required this.message});
}

/// Persist the rendered QR PNG where the user can retrieve it later.
///
/// • Mobile  → device photo gallery via `gal` (needs the gallery permission,
///             which `gal` requests internally on first use).
/// • Web     → triggers a browser download of `<fileName>.png`.
Future<QrSaveResult> saveQrImage(
    Uint8List pngBytes, {
      required String fileName,
    }) =>
    impl.saveQrImage(pngBytes, fileName: fileName);

/// Share the rendered QR PNG through the OS / browser share sheet.
///
/// Returns the [XFile] list ready to hand to `SharePlus.instance.share(...)`.
/// On web we use `XFile.fromData` (in-memory, no filesystem); on mobile we
/// write a real temp file (some share targets need a `file://` path).
///
/// The caller still owns the actual `SharePlus.instance.share(...)` call so the
/// share *text* / subject stays in one place in the UI.
Future<List<XFile>> buildQrShareFiles(
    Uint8List pngBytes, {
      required String fileName,
    }) =>
    impl.buildQrShareFiles(pngBytes, fileName: fileName);