import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final bool isVerified;

  const VerificationBadge({
    super.key,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVerified) return const SizedBox.shrink();
    return const Icon(
      Icons.verified,
      color: Color(0xFF1DA1F2),
      size: 18,
    );
  }
}

class VerificationBadgeForPost extends StatelessWidget {
  final bool ? verified;

  const VerificationBadgeForPost({
    super.key,
    this.verified = false ,
  });

  @override
  Widget build(BuildContext context) {


    // Return row of badges or empty if none
    if (verified == false) {
      return const SizedBox.shrink();
    }
     return  const Icon(
       Icons.verified,
       color: Color(0xFF1DA1F2),
       size: 18,
     );
  }
}