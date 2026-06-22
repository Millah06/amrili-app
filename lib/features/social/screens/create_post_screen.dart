// lib/features/social/screens/create_post_screen.dart
// =============================================================================
// PHASE 11 — Create Post (polish pass)
// -----------------------------------------------------------------------------
// Behaviour is identical to before (same validation, image upload, guest guard,
// 500-char limit). Only the presentation changed: VendorTheme tokens + Inter/
// Poppins, filled rounded inputs, a live character counter, and a Post button
// with proper contrast. The image picker, API calls, and navigation are untouched.
// =============================================================================

import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/shared/widgets/image_editor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../core/auth/guest_helper.dart';
import '../services/social_api_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final SocialApiService _apiService = SocialApiService();
  bool _isPosting = false;
  List<XFile> _pickedImages = [];

  static const int _maxChars = 500;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text = _textController.text.trim();
    final title = _titleController.text.trim();

    if (text.isEmpty && _pickedImages.isEmpty) {
      _showError('Add some text or an image to post.');
      return;
    }
    if (text.length > _maxChars) {
      _showError('Post text can\'t exceed $_maxChars characters.');
      return;
    }

    setState(() => _isPosting = true);
    try {
      List<String>? imageUrls;
      if (_pickedImages.isNotEmpty) {
        imageUrls = await _apiService.uploadPostImages(_pickedImages);
      }

      await _apiService.createPost(
        title: title,
        text: text,
        imageUrls: imageUrls,
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccess('Post created');
      }
    } catch (e) {
      _showError('Couldn\'t create the post. Try again.');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: VendorTheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: kSnackSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _textController.text.length;
    final isOverLimit = textLength > _maxChars;

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: VendorTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.close, color: VendorTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Create post',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: ElevatedButton(
              onPressed: _isPosting || isOverLimit
                  ? null
                  : () => GuestHelper.guardAction(context,
                  action: _createPost, reason: 'create post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorTheme.primary,
                foregroundColor: VendorTheme.background,
                disabledBackgroundColor: VendorTheme.surfaceVariant,
                disabledForegroundColor: VendorTheme.textMuted,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: _isPosting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation(VendorTheme.background)),
              )
                  : Text('Post',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(label: 'Title'),
            const SizedBox(height: 10),
            _filledField(
              controller: _titleController,
              hint: 'Add a title',
              maxLines: 1,
              capitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 24),
            const _SectionLabel(label: 'Description'),
            const SizedBox(height: 10),
            _filledField(
              controller: _textController,
              hint: 'What\'s on your mind?',
              maxLines: 8,
              capitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 6),
            // live character counter
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$textLength / $_maxChars',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isOverLimit
                      ? VendorTheme.error
                      : VendorTheme.textMuted,
                  fontWeight: isOverLimit ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 24),
            const _SectionLabel(label: 'Photos'),
            const SizedBox(height: 10),
            AppImagePicker(
              onChanged: (d, newImages) {
                _pickedImages = newImages;
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    ),
    );
  }

  // one styled input used for both fields (cohesive look)
  Widget _filledField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required TextCapitalization capitalization,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: _maxChars,
      cursorColor: VendorTheme.primary,
      textCapitalization: capitalization,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.inter(color: VendorTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        GoogleFonts.inter(color: VendorTheme.textMuted, fontSize: 15),
        counterText: '',
        filled: true,
        fillColor: VendorTheme.surface,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendorTheme.surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendorTheme.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: VendorTheme.primary),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: VendorTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: VendorTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}