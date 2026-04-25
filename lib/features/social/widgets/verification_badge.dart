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
    if (profile.hasBlueCheck) {
      badges.add(
        const Icon(
          Icons.verified,
          color: Color(0xFF1DA1F2),
          size: 18,
        ),
      );
    }

    // Check Premium
    if (profile.hasPremium) {
      badges.add(
        const Icon(
          Icons.workspace_premium,
          color: Color(0xFFFFD700),
          size: 18,
        ),
      );
    }

    // Check Business - Updated with more beautiful icon
    if (profile.isBusiness) {
      badges.add(
        const Icon(
          Icons.storefront, // More beautiful business icon
          color: Color(0xFF177E85),
          size: 18,
        ),
      );
    }

    // Check Creator
    if (profile.isCreator) {
      badges.add(
        const Icon(
          Icons.star,
          color: Color(0xFFFF6B6B),
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
  final String? badge;

  const VerificationBadgeForPost({
    super.key,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {

    // Build list of badges based on what the user has
    final  Map<String, Widget> mapIcons = {
      'kycBlue' : const Icon(
        Icons.verified,
        color: Color(0xFF1DA1F2),
        size: 18,
      ),
      'premiumPaid' :  const Icon(
        Icons.workspace_premium,
        color: Color(0xFFFFD700),
        size: 18,
      ),
      'business' : const Icon(
        Icons.storefront, // More beautiful business icon
        color: Color(0xFF177E85),
        size: 18,
      ),
      'creatorEarnings' :  const Icon(
        Icons.star,
        color: Color(0xFFFF6B6B),
        size: 18,
      ),
    };

    List<String> badges = mapIcons.keys.toList();

    if (!badges.contains(badge)) {
      return const SizedBox.shrink();
    }

    // Return row of badges or empty if none
    if (badge!.isEmpty || badge == null) {
      return const SizedBox.shrink();
    }
     return mapIcons[badge] ??  const SizedBox.shrink();
  }
}