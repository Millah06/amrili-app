// lib/widgets/profile_stats.dart - NEW

import 'package:flutter/material.dart';
import '../../../models/user_profile_model.dart';


class ProfileStats extends StatelessWidget {
  final UserProfile profile;

  const ProfileStats({Key? key, required this.profile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'Posts',
            value: profile.postCount.toString(),
          ),
          _StatItem(
            label: 'Followers',
            value: _formatCount(profile.followerCount),
          ),
          _StatItem(
            label: 'Following',
            value: _formatCount(profile.followingCount),
          ),
          _StatItem(
            label: 'Earned',
            value: '₦${_formatCount(profile.totalNairaEarned.toInt())}',
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}