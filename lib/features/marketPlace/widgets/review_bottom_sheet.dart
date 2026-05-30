import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../providers/vendor_center_provider.dart';

/// Shows a star-rating + comment sheet after a completed order.
/// Call via [ReviewBottomSheet.show].
class ReviewBottomSheet extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final String userName;
  final String orderId;
  final VoidCallback? onSubmitted;
  final VendorCenterProvider vendorCenterProvider;

  const ReviewBottomSheet({
    super.key,
    required this.vendorId,
    required this.vendorName,
    required this.userName,
    required this.orderId,
    required this.vendorCenterProvider,
    this.onSubmitted,
  });

  static Future<void> show(
      BuildContext context, {
        required String vendorId,
        required String vendorName,
        required String userName,
        required String orderId,
        required VendorCenterProvider vendorCenterProvider,
        VoidCallback? onSubmitted,
      }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReviewBottomSheet(
          vendorId: vendorId,
          orderId : orderId,
          vendorName: vendorName,
          userName: userName,
          vendorCenterProvider: vendorCenterProvider,
          onSubmitted: onSubmitted,
        ),
      );

  @override
  State<ReviewBottomSheet> createState() => _ReviewBottomSheetState();
}

class _ReviewBottomSheetState extends State<ReviewBottomSheet> {
  double _rating = 0;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: VendorTheme.warning,
        ),
      );
      return;
    }
    if (_ctrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a short comment'),
          backgroundColor: VendorTheme.warning,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await widget.vendorCenterProvider.submitReview(
      widget.vendorId,
      rating: _rating,
      comment: _ctrl.text.trim(),
      userName: widget.userName,
      orderId: widget.orderId
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      widget.onSubmitted?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted — thank you!'),
          backgroundColor: VendorTheme.accent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<VendorCenterProvider>().error ?? 'Failed to submit review',
          ),
          backgroundColor: VendorTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: VendorTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            const Text(
              '⭐ Rate your experience',
              style: TextStyle(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.vendorName,
              style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starVal = i + 1.0;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starVal),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      _rating >= starVal ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: _rating >= starVal
                          ? VendorTheme.gold
                          : VendorTheme.textMuted,
                      size: 38,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _ratingLabel,
              style: TextStyle(
                color: _rating > 0 ? VendorTheme.warning : VendorTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),

            // Comment
            TextField(
              controller: _ctrl,
              maxLines: 3,
              style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: const TextStyle(color: VendorTheme.textMuted),
                filled: true,
                fillColor: VendorTheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 20),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: VendorTheme.primary.withOpacity(0.4),
                ),
                child: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2),
                )
                    : const Text(
                  'Submit Review',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating.toInt()) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent!';
      default: return 'Tap to rate';
    }
  }
}