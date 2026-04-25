import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reward_provider.dart';

class LeaderboardSection extends StatelessWidget {
  const LeaderboardSection({super.key});

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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[700]!, Colors.purple[500]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Top Earners This Week',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: earners.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final earner = earners[index];
                    return _TopEarnerCard(
                      rank: index + 1,
                      name: earner.userName,
                      points: earner.weeklyPoints,
                    );
                  },
                ),
              ),
            ],
          ),
        );

      },
    );
  }
}

class _TopEarnerCard extends StatelessWidget {
  final int rank;
  final String name;
  final double points;

  const _TopEarnerCard({
    required this.rank,
    required this.name,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    switch (rank) {
      case 1:
        rankColor = Colors.amber;
        break;
      case 2:
        rankColor = Colors.grey[300]!;
        break;
      case 3:
        rankColor = Colors.brown[300]!;
        break;
      default:
        rankColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
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
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                name.length > 12 ? '${name.substring(0, 12)}...' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₦${kFormatter.format(points)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}