// lib/widgets/profile_header.dart - NEW

import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile_model.dart';
import '../../../features/profile/providers/user_profile_provider.dart';
import 'verification_badge.dart';
import 'follow_button.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwnProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar
          NetImage.circle(
            url: profile.avatar ?? '',
            radius: 50,
            fallback: profile.avatar == null
                ? CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[700],
                    child: Text(
                      profile.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),

          // Username with badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                profile.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              VerificationBadge(isVerified: profile.isKycVerified),
            ],
          ),

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Follow button or edit profile
          if (!isOwnProfile)
            FollowButton(
              userId: profile.userId,
              isFollowing: profile.isFollowing,
              onToggle: () => context.read<UserProfileProvider>().toggleFollow(),
            )
          else
            OutlinedButton(
              onPressed: () {
                // Navigate to edit profile
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[600]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Edit Profile',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
        ],
      ),
    );
  }
}