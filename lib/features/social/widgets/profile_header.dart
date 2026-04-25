// lib/widgets/profile_header.dart - NEW

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';
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
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[700],
            backgroundImage: profile.avatar != null
                ? CachedNetworkImageProvider(profile.avatar!)
                : null,
            child: profile.avatar == null
                ? Text(
              profile.userName[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
              VerificationBadge(userId: profile.userId),
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
              onToggle: () => context.read<ProfileProvider>().toggleFollow(),
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