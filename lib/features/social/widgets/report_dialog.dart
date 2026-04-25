// lib/widgets/report_dialog.dart - NEW

import 'package:flutter/material.dart';
import '../services/social_api_service.dart';
import '../models/post_model.dart';

class ReportDialog extends StatefulWidget {
  final Post post;

  const ReportDialog({super.key, required this.post});

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _reasons = {
    'inappropriate': 'Inappropriate content',
    'harassment': 'Harassment or bullying',
    'spam': 'Spam or misleading',
    'religious': 'Religious violation',
    'other': 'Other',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Report Post',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this post?',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Reason selection
            ..._reasons.entries.map((entry) {
              return RadioListTile<String>(
                value: entry.key,
                groupValue: _selectedReason,
                title: Text(
                  entry.value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                activeColor: const Color(0xFF177E85),
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),

            const SizedBox(height: 16),

            // Additional details
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 500,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Additional details (optional)',
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null || _isSubmitting
              ? null
              : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            disabledBackgroundColor: Colors.grey[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    try {
      final apiService = SocialApiService();
      await apiService.reportPost(
        postId: widget.post.postId,
        reason: _selectedReason!,
        details: _detailsController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Thank you for keeping our community safe.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}