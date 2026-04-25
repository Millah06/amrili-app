// lib/screens/create_post_screen.dart

import 'dart:io';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/shared/widgets/image_editor.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/storage_service.dart';
import '../../social/services/social_api_service.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final SocialApiService _apiService = SocialApiService();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isPosting = false;
  List<XFile> _pickedImages = [];

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final text = _textController.text.trim();
    final title = _titleController.text.trim();

    // if (text.isEmpty && _selectedImage == null) {
    //   _showError('Please add some text or an image');
    //   return;
    // }

    if (text.isEmpty && _pickedImages.isEmpty) {
      _showError('Please add some text or an image');
      return;
    }

    if (text.length > 500) {
      _showError('Post text cannot exceed 500 characters');
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
        _showSuccess('Post created successfully!');
      }
    } catch (e) {
      _showError('Failed to create post: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textLength = _textController.text.length;
    final isOverLimit = textLength > 500;

    return Scaffold(
      // backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF1E293B),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _isPosting || isOverLimit ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: kButtonColor,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isPosting
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text('Post', style: TextStyle(color: Colors.black),),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _SectionLabel(label: 'Title'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    maxLines: 1,
                    maxLength: 500,
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                      hintText: "Add title",
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      counterText: '',
                      focusedBorder: InputBorder.none
                    ),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 30,),

                  _SectionLabel(label: 'Description'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _textController,
                    maxLines: 10,
                    maxLength: 500,
                    cursorColor: Colors.white,
                    decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),

                        border: InputBorder.none,
                        counterText: '',
                        focusedBorder: InputBorder.none
                    ),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 50,),

                  AppImagePicker(
                      onChanged: (d, newImages) {
                        _pickedImages = newImages;
                      }
                  ),
                  // const SizedBox(height: 16),
                  // if (_selectedImage != null) ...[
                  //   Stack(
                  //     children: [
                  //       ClipRRect(
                  //         borderRadius: BorderRadius.circular(12),
                  //         child: Image.file(
                  //           _selectedImage!,
                  //           width: double.infinity,
                  //           fit: BoxFit.cover,
                  //         ),
                  //       ),
                  //       Positioned(
                  //         top: 8,
                  //         right: 8,
                  //         child: GestureDetector(
                  //           onTap: () => setState(() => _selectedImage = null),
                  //           child: Container(
                  //             padding: const EdgeInsets.all(8),
                  //             decoration: const BoxDecoration(
                  //               color: Colors.black54,
                  //               shape: BoxShape.circle,
                  //             ),
                  //             child: const Icon(
                  //               Icons.close,
                  //               color: Colors.white,
                  //               size: 20,
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  //   const SizedBox(height: 16),
                  // ],
                ],
              ),
            ),
          ),

          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Color(0xFF334155),
          //     border: Border(
          //       top: BorderSide(color: Colors.grey[200]!),
          //     ),
          //   ),
          //   child: Row(
          //     children: [
          //       IconButton(
          //         icon: Icon(
          //           Icons.image_outlined,
          //           color: kButtonColor,
          //         ),
          //         onPressed: _isPosting ? null : _pickImage,
          //       ),
          //       const Spacer(),
          //       Text(
          //         '$textLength/500',
          //         style: TextStyle(
          //           color: isOverLimit ? Colors.red : Colors.grey,
          //           fontSize: 12,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
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
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: VendorTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}