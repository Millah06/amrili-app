// lib/widgets/compact_leaderboard.dart - NEW

import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reward_provider.dart';


class CompactLeaderboard extends StatefulWidget {
  const CompactLeaderboard({super.key});

  @override
  State<CompactLeaderboard> createState() => _CompactLeaderboardState();
}

class _CompactLeaderboardState extends State<CompactLeaderboard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<RewardProvider>(
      builder: (context, rewardProvider, _) {
        if (rewardProvider.isLoadingLeaderboard) {
          return const SizedBox.shrink();
        }

        final earners = rewardProvider.topEarners.take(5).toList();

        if (earners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Top Earners',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),

              // Collapsed view - horizontal scroll
              if (!_isExpanded)
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: earners.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final earner = earners[index];
                      return _CompactEarnerCard(
                        rank: index + 1,
                        name: earner.userName,
                        points: earner.weeklyPoints,
                      );
                    },
                  ),
                ),

              // Expanded view - vertical list
              if (_isExpanded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  itemCount: earners.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final earner = earners[index];
                    return _ExpandedEarnerCard(
                      rank: index + 1,
                      name: earner.userName,
                      avatar: earner.userAvatar,
                      weeklyPoints: earner.weeklyPoints,
                      totalPoints: earner.totalRewardPoints,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactEarnerCard extends StatelessWidget {
  final int rank;
  final String name;
  final double points;

  const _CompactEarnerCard({
    required this.rank,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        rankColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rankColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name.length > 10 ? '${name.substring(0, 10)}...' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₦${kFormatter.format(points)}',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedEarnerCard extends StatelessWidget {
  final int rank;
  final String name;
  final String? avatar;
  final double weeklyPoints;
  final double totalPoints;

  const _ExpandedEarnerCard({
    required this.rank,
    required this.name,
    this.avatar,
    required this.weeklyPoints,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        break;
      default:
        rankColor = Colors.grey[600]!;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[700],
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Total: ₦${kFormatter.format(totalPoints)}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${kFormatter.format(weeklyPoints)}',
                style: const TextStyle(
                  color: Color(0xFF177E85),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'this week',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}