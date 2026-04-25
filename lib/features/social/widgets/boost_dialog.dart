// lib/widgets/boost_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post_model.dart';
import '../providers/feed_provider.dart';
import '../providers/reward_provider.dart';


class BoostDialog extends StatefulWidget {
  final Post post;

  const BoostDialog({super.key, required this.post});

  @override
  State<BoostDialog> createState() => _BoostDialogState();
}

class _BoostDialogState extends State<BoostDialog> {
  bool _isProcessing = false;

  Future<void> _processBoost() async {
    setState(() => _isProcessing = true);

    try {
      await context.read<RewardProvider>().boostPost(widget.post.postId);

      if (mounted) {
        context.read<FeedProvider>().updatePostAfterBoost(widget.post.postId);
        Navigator.pop(context);
        _showSuccess('Post boosted for 24 hours!');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor:   Color(0xFF1E293B),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rocket_launch, color: Colors.amber),
          ),
          const SizedBox(width: 12),
          const Text('Boost Post', style: TextStyle(color: Colors.white),),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boost your post to appear at the top of the feed for 24 hours.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Boost Cost',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '₦300.00',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white),),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processBoost,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Boost Now'),
        ),
      ],
    );
  }
}