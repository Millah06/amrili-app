import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import '../../constraints/vendor_theme.dart';


/// Reusable image picker with edit support via pro_image_editor.
///
/// Usage:
/// ```dart
/// VendorImagePicker(
///   existingImages: item.images,        // List<String> — network URLs
///   onChanged: (keptUrls, newImages) {  // called on every change
///     _keptUrls  = keptUrls;            // existing URLs the user kept
///     _newImages = newImages;           // XFile list to upload
///   },
/// )
/// ```
class AppImagePicker extends StatefulWidget {
  /// Network image URLs already saved (e.g. from an existing model).
  final List<String> existingImages;
  final double imageHeight;
  final double imageWidth;
  final double spaceBetween;
  final double singleHeight;
  final double singleWidth;

  /// Fires whenever the selection changes.
  /// [keptUrls]  — existing URLs the user has NOT removed.
  /// [newImages] — newly picked / edited images to upload.
  final void Function(List<String> keptUrls, List<XFile> newImages) onChanged;

  const AppImagePicker({
    super.key,
    this.existingImages = const [],
    required this.onChanged,
    this.imageHeight = 180,
    this.imageWidth = 150,
    this.spaceBetween = 12,
    this.singleHeight = 260,
    this.singleWidth = 180,
  });

  @override
  State<AppImagePicker> createState() => _AppImagePickerState();
}

class _AppImagePickerState extends State<AppImagePicker> {
  late List<String> _existingUrls;
  final List<XFile> _newImages = [];
  final _picker = ImagePicker();

  // ─── State helpers ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _existingUrls = List.from(widget.existingImages);
  }

  void _notify() => widget.onChanged(_existingUrls, List.unmodifiable(_newImages));

  int get _totalCount => _existingUrls.length + _newImages.length;

  // ─── Picking ──────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;
    setState(() => _newImages.addAll(picked));
    _notify();
  }

  // ─── Removing ─────────────────────────────────────────────────────────────

  void _removeExisting(int index) {
    setState(() => _existingUrls.removeAt(index));
    _notify();
  }

  void _removeNew(int index) {
    setState(() => _newImages.removeAt(index));
    _notify();
  }

  // ─── Editing ──────────────────────────────────────────────────────────────

  /// Edit a newly picked XFile image.
  Future<void> _editNewImage(int index) async {
    final bytes = await File(_newImages[index].path).readAsBytes();
    if (!mounted) return;

    _openEditor(
      bytes: bytes,
      onSave: (editedBytes) async {
        final saved = await _bytesToTempFile(editedBytes);
        if (!mounted) return;
        setState(() => _newImages[index] = XFile(saved.path));
        _notify();
      },
    );
  }

  /// Edit an existing network image — downloads it, opens editor,
  /// then moves it from [_existingUrls] into [_newImages] as a local file.
  Future<void> _editExistingImage(int index) async {
    final url = _existingUrls[index];

    // Show a loading indicator while downloading
    _showLoading();
    late Uint8List bytes;
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        if (mounted) {
          Navigator.pop(context); // dismiss loader
          _showSnack('Could not download image for editing');
        }
        return;
      }
      bytes = response.bodyBytes;
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Network error while downloading image');
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    _openEditor(
      bytes: bytes,
      onSave: (editedBytes) async {
        final saved = await _bytesToTempFile(editedBytes);
        if (!mounted) return;
        setState(() {
          _existingUrls.removeAt(index); // no longer "existing" — it changed
          _newImages.add(XFile(saved.path));
        });
        _notify();
      },
    );
  }

  /// Opens ProImageEditor full-screen and calls [onSave] with the result bytes.
  void _openEditor({
    required Uint8List bytes,
    required Future<void> Function(Uint8List) onSave,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          bytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (editedBytes) async {
              await onSave(editedBytes);
              if (mounted) Navigator.pop(context);
            },
          ),
          configs: _editorConfigs(),
        ),
      ),
    );
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  Future<File> _bytesToTempFile(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final name = 'vendor_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return File('${dir.path}/$name').writeAsBytes(bytes);
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: VendorTheme.primary),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: VendorTheme.textPrimary)),
        backgroundColor: VendorTheme.surface,
      ),
    );
  }

  // ─── ProImageEditor theme ─────────────────────────────────────────────────

  ProImageEditorConfigs _editorConfigs() {
    return ProImageEditorConfigs(
      theme: VendorTheme.theme,
      paintEditor: PaintEditorConfigs(
        style: PaintEditorStyle(
          background: VendorTheme.background,
          appBarColor: VendorTheme.surface,
          // appBarForeground: VendorTheme.textPrimary,
          bottomBarBackground: VendorTheme.surface,
          // bottomBarForegroundColor: VendorTheme.textPrimary,
          editSheetBackgroundColor: VendorTheme.surface,
        )
      ),
      cropRotateEditor: CropRotateEditorConfigs(
        style: CropRotateEditorStyle(
          background: VendorTheme.background,
          appBarBackground: VendorTheme.surface,

          cropCornerColor: VendorTheme.primary,
          helperLineColor: VendorTheme.primary,
        )
      ),
      filterEditor: FilterEditorConfigs(
        style: FilterEditorStyle(
          background: VendorTheme.background,
          appBarBackground: VendorTheme.surface,
          previewTextColor: VendorTheme.textPrimary,
        )
      ),
      blurEditor: BlurEditorConfigs(
        style: BlurEditorStyle(
          background: VendorTheme.background,
          appBarBackgroundColor: VendorTheme.surface,
          appBarForegroundColor: VendorTheme.textPrimary,
        ),
      ),
      dialogConfigs: DialogConfigs(
        style: DialogStyle(
          loadingDialog: LoadingDialogStyle(
            textColor: VendorTheme.textPrimary,
          ),

        )
      )

    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing network images
        if (_existingUrls.isNotEmpty) ...[

          _sectionLabel('Current Images'),
          const SizedBox(height: 8),
          _imageRow(
            imageLength: _existingUrls.length,
            count: _existingUrls.length,
            imageBuilder: (i) {
              double finalImageHeight = _existingUrls.length == 1 ? widget.singleHeight : widget.imageHeight;
              double finalImageWidth = _existingUrls.length == 1 ? widget.singleWidth : widget.imageWidth;
              return CachedNetworkImage(
                imageUrl: _existingUrls[i],
                width: finalImageWidth,
                height: finalImageHeight,
                fit: BoxFit.cover,
                placeholder: (_, __) => _shimmer(),
                errorWidget: (_, __, ___) => _brokenImage(),
              );},
            onEdit: _editExistingImage,
            onRemove: _removeExisting,
          ),
          const SizedBox(height: 14),
        ],

        // Newly picked / edited images
        if (_newImages.isNotEmpty) ...[
          _sectionLabel(
            _existingUrls.isEmpty ? 'Selected Images' : 'New Images',
          ),
          const SizedBox(height: 8),
          _imageRow(
            imageLength: _newImages.length,
            count: _newImages.length,
            imageBuilder: (i) {
              double finalImageHeight = _newImages.length == 1 ? widget.singleHeight : widget.imageHeight;
              double finalImageWidth = _newImages.length == 1 ? widget.singleWidth : widget.imageWidth;
              return Image.file(
                File(_newImages[i].path),
                width: finalImageWidth,
                height: finalImageHeight,
                fit: BoxFit.cover,
              );},
            onEdit: _editNewImage,
            onRemove: _removeNew,
          ),
          const SizedBox(height: 14),
        ],

        // Pick button
        _pickButton(),
      ],
    );
  }

  // ─── Sub-widgets ──────────────────────────────────────────────────────────

  Widget _imageRow({
    required int count,
    required Widget Function(int index) imageBuilder,
    required Future<void> Function(int) onEdit,
    required void Function(int) onRemove,
    required int imageLength
  }) {
    double finalImageHeight = imageLength == 1 ? widget.singleHeight : widget.imageHeight;
    double finalImageWidth = imageLength == 1 ? widget.singleWidth : widget.imageWidth;
    return SizedBox(
      height: finalImageHeight + widget.spaceBetween, // 110 image + 4 gap + 16 label + some padding
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {

          return _thumbnail(
            image: imageBuilder(i),
            onEdit: () => onEdit(i),
            onRemove: () => onRemove(i),
            imageWidth: finalImageWidth,
            imageHeight: finalImageHeight,
        );},
      ),
    );
  }

  Widget _thumbnail({
    required Widget image,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
    required double imageWidth,
    required double imageHeight
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: imageWidth, height: imageHeight, child: image),
            ),
            // Remove button
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 11, color: Colors.white),
                      SizedBox(width: 3),
                      Text('Tap to edit',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  Widget _pickButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendorTheme.primary.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: VendorTheme.primary.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              _totalCount == 0
                  ? 'Tap to pick images from gallery'
                  : 'Tap to add more images',
              style: TextStyle(
                fontSize: 13,
                color: VendorTheme.primary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_totalCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '$_totalCount image${_totalCount == 1 ? '' : 's'} selected',
                  style: const TextStyle(
                    fontSize: 11,
                    color: VendorTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      color: VendorTheme.textSecondary,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _shimmer() => Container(
    color: VendorTheme.surfaceVariant,
    child: const Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: VendorTheme.primary,
        ),
      ),
    ),
  );

  Widget _brokenImage() => Container(
    color: VendorTheme.surfaceVariant,
    child: const Icon(
      Icons.broken_image_outlined,
      color: VendorTheme.textMuted,
      size: 28,
    ),
  );
}