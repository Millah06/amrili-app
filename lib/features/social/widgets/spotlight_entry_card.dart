// lib/features/social/widgets/spotlight_entry_card.dart
//
// PHASE 10 — the slim Spotlight entry that replaces the in-feed leaderboard.
// One restrained, tappable banner at the top of Explore → opens SpotlightScreen.
// No rankings or money in the feed itself; this is just a tasteful doorway.

import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';
import '../screens/spotlight_screen.dart';

class SpotlightEntryCard extends StatelessWidget {
  const SpotlightEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Material(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SpotlightScreen()),
          ),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  VendorTheme.primary.withOpacity(0.16),
                  VendorTheme.surface,
                ],
              ),
              border: Border.all(color: VendorTheme.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: VendorTheme.gold, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spotlight',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('This week’s celebrated creators & supporters',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}