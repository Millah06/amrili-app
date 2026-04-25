// lib/widgets/follow_button.dart - NEW

import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final String userId;
  final bool isFollowing;
  final VoidCallback onToggle;

  const FollowButton({
    super.key,
    required this.userId,
    required this.isFollowing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: isFollowing ? Colors.transparent : const Color(0xFF177E85),
          border: isFollowing
              ? Border.all(color: Colors.grey[600]!, width: 1)
              : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            color: isFollowing ? Colors.grey[400] : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}