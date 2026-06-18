import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/profile_provider.dart';

class VerificationBadge extends StatelessWidget {
  final String userId;

  const VerificationBadge({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.read<ProfileProvider>();

    if (profileProvider.profile == null) {
      return const SizedBox.shrink();
    }

    final profile = profileProvider.profile!;

    // Build list of badges based on what the user has
    final List<Widget> badges = [];

    // Check KYC (hasBlueCheck)
    if (profile.isVerified) {
      badges.add(
        const Icon(
          Icons.verified,
          color: Color(0xFF1DA1F2),
          size: 18,
        ),
      );
    }

    // Return row of badges or empty if none
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    // Add spacing between badges if more than one
    if (badges.length == 1) {
      return badges.first;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: badges.map((badge) => Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: badge,
      )).toList(),
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