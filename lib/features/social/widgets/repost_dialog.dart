// lib/widgets/repost_dialog.dart - NEW

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../services/social_api_service.dart';
import '../models/post_model.dart';
import '../providers/feed_provider.dart';

class RepostDialog extends StatefulWidget {
  final Post post;

  const RepostDialog({super.key, required this.post});

  @override
  State<RepostDialog> createState() => _RepostDialogState();
}

class _RepostDialogState extends State<RepostDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isReposting = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textController.text = widget.post.text;
    });
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.repeat, color: Color(0xFF177E85)),
          const SizedBox(width: 8),
          const Text(
            'Repost',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original post preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[700],
                        child: Text(
                          widget.post.userName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.post.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.post.text.length > 100
                        ? '${widget.post.text.substring(0, 100)}...'
                        : widget.post.text,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Add your thoughts
            Text('Add your thoughts (optional)', style: TextStyle(color: Colors.grey[600]),),
            const SizedBox(height: 5,),
            TextField(
              controller: _textController,
              maxLines: 3,
              maxLength: 280,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add your thoughts (optional)',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                counterStyle: TextStyle(color: Colors.grey[600]),
              ),

            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isReposting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: _isReposting ? null : _submitRepost,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF177E85),
            disabledBackgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isReposting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : const Text('Repost'),
        ),
      ],
    );
  }

  Future<void> _submitRepost() async {
    setState(() => _isReposting = true);

    try {
      final apiService = SocialApiService();
      final result = await apiService.repostPost(
        postId: widget.post.postId,
        text: _textController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);

        // Add repost to feed
        final newPost = Post.fromJson(result['post']);
        context.read<FeedProvider>().addNewPost(newPost);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reposted successfully!'),
            backgroundColor: VendorTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to repost: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isReposting = false);
      }
    }
  }
}