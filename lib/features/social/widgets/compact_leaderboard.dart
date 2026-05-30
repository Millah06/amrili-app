// lib/widgets/compact_leaderboard.dart - NEW

// import 'package:everywhere/constraints/constants.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../providers/reward_provider.dart';
//
//
// class CompactLeaderboard extends StatefulWidget {
//   const CompactLeaderboard({super.key});
//
//   @override
//   State<CompactLeaderboard> createState() => _CompactLeaderboardState();
// }
//
// class _CompactLeaderboardState extends State<CompactLeaderboard> {
//   bool _isExpanded = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<RewardProvider>(
//       builder: (context, rewardProvider, _) {
//         if (rewardProvider.isLoadingLeaderboard) {
//           return const SizedBox.shrink();
//         }
//
//         final earners = rewardProvider.topEarners.take(5).toList();
//
//         if (earners.isEmpty) {
//           return const SizedBox.shrink();
//         }
//
//         return Container(
//           margin: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: const Color(0xFF1E293B),
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.2),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             children: [
//               // Header
//               InkWell(
//                 onTap: () => setState(() => _isExpanded = !_isExpanded),
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 24),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Top Earners',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const Spacer(),
//                       Icon(
//                         _isExpanded ? Icons.expand_less : Icons.expand_more,
//                         color: Colors.grey[400],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//
//               // Collapsed view - horizontal scroll
//               if (!_isExpanded)
//                 SizedBox(
//                   height: 80,
//                   child: ListView.separated(
//                     scrollDirection: Axis.horizontal,
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     itemCount: earners.length,
//                     separatorBuilder: (context, index) => const SizedBox(width: 12),
//                     itemBuilder: (context, index) {
//                       final earner = earners[index];
//                       return _CompactEarnerCard(
//                         rank: index + 1,
//                         name: earner.userName,
//                         points: earner.weeklyCoins,
//                       );
//                     },
//                   ),
//                 ),
//
//               // Expanded view - vertical list
//               if (_isExpanded)
//                 ListView.separated(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
//                   itemCount: earners.length,
//                   separatorBuilder: (context, index) => const SizedBox(height: 8),
//                   itemBuilder: (context, index) {
//                     final earner = earners[index];
//                     return _ExpandedEarnerCard(
//                       rank: index + 1,
//                       name: earner.userName,
//                       avatar: earner.userAvatar,
//                       weeklyPoints: earner.weeklyCoins,
//                       totalPoints: earner.totalCoins,
//                     );
//                   },
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// class _CompactEarnerCard extends StatelessWidget {
//   final int rank;
//   final String name;
//   final int points;
//
//   const _CompactEarnerCard({
//     required this.rank,
//     required this.name,
//     required this.points,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     Color rankColor;
//     switch (rank) {
//       case 1:
//         rankColor = const Color(0xFFFFD700); // Gold
//         break;
//       case 2:
//         rankColor = const Color(0xFFC0C0C0); // Silver
//         break;
//       case 3:
//         rankColor = const Color(0xFFCD7F32); // Bronze
//         break;
//       default:
//         rankColor = Colors.grey[600]!;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F172A),
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(
//           color: rankColor.withOpacity(0.3),
//         ),
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   color: rankColor,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: Text(
//                     '$rank',
//                     style: const TextStyle(
//                       color: Colors.black,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 name.length > 10 ? '${name.substring(0, 10)}...' : name,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '₦${kFormatter.format(points)}',
//             style: TextStyle(
//               color: Colors.grey[400],
//               fontSize: 11,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _ExpandedEarnerCard extends StatelessWidget {
//   final int rank;
//   final String name;
//   final String? avatar;
//   final int weeklyPoints;
//   final int totalPoints;
//
//   const _ExpandedEarnerCard({
//     required this.rank,
//     required this.name,
//     this.avatar,
//     required this.weeklyPoints,
//     required this.totalPoints,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     Color rankColor;
//     switch (rank) {
//       case 1:
//         rankColor = const Color(0xFFFFD700);
//         break;
//       case 2:
//         rankColor = const Color(0xFFC0C0C0);
//         break;
//       case 3:
//         rankColor = const Color(0xFFCD7F32);
//         break;
//       default:
//         rankColor = Colors.grey[600]!;
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0F172A),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         children: [
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               color: rankColor,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 '$rank',
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 14,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           CircleAvatar(
//             radius: 20,
//             backgroundColor: Colors.grey[700],
//             child: Text(
//               name[0].toUpperCase(),
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   name,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 14,
//                   ),
//                 ),
//                 Text(
//                   'Total: ₦${kFormatter.format(totalPoints)}',
//                   style: TextStyle(
//                     color: Colors.grey[500],
//                     fontSize: 11,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Text(
//                 '₦${kFormatter.format(weeklyPoints)}',
//                 style: const TextStyle(
//                   color: Color(0xFF177E85),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                 ),
//               ),
//               Text(
//                 'this week',
//                 style: TextStyle(
//                   color: Colors.grey[500],
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

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

        final earners = rewardProvider.topEarners.take(10).toList();

        if (earners.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 2, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Creators',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'This Week\'s Stars',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: const Color(0xFFFFD700),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),

              // Collapsed view - horizontal scroll
              if (!_isExpanded)
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: earners.take(5).length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final earner = earners[index];
                      return _CompactEarnerCard(
                        rank: index + 1,
                        name: earner.userName,
                        coins: earner.weeklyCoins,
                        avatar: earner.userAvatar,
                      );
                    },
                  ),
                ),
              // Expanded view - vertical list
              if (_isExpanded)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: earners.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final earner = earners[index];
                    return _ExpandedEarnerCard(
                      rank: index + 1,
                      name: earner.userName,
                      avatar: earner.userAvatar,
                      weeklyCoins: earner.weeklyCoins,
                      totalCoins: earner.totalCoins,
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
  final int coins;
  final String? avatar;

  const _CompactEarnerCard({
    required this.rank,
    required this.name,
    required this.coins,
    this.avatar,
  });

  Color get _rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700); // Gold
      case 2: return const Color(0xFFC0C0C0); // Silver
      case 3: return const Color(0xFFCD7F32); // Bronze
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _rankColor.withOpacity(0.15),
            _rankColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _rankColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _rankColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _rankColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            name.length > 9 ? '${name.substring(0, 9)}.' : name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Coins
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.stars_rounded,
                size: 14,
                color: Color(0xFFFFD700),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  kFormatterNo.format(coins),
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
  final int weeklyCoins;
  final int totalCoins;

  const _ExpandedEarnerCard({
    required this.rank,
    required this.name,
    this.avatar,
    required this.weeklyCoins,
    required this.totalCoins,
  });

  Color get _rankColor {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _rankColor.withOpacity(0.1),
            _rankColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _rankColor.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rankColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _rankColor.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF334155),
            child: Text(
              name[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name & total
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 12,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${kFormatterNo.format(totalCoins)} total',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Weekly coins
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    kFormatterNo.format(weeklyCoins),
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
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