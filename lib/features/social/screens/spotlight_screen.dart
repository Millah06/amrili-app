// lib/features/social/screens/spotlight_screen.dart
//
// PHASE 10 — "Spotlight": the repositioned leaderboard.
//
// Two boards, money HIDDEN (coins + tiers only):
//   • Creators   — most celebrated this week (recognition, not earnings).
//   • Supporters — most generous gifters this week (the patron flex).
//
// Editorial, restrained, celebratory — designed to read as prestige, not a
// coin-farm. An understated podium for the top 3, tier badges, "this week"
// framing. Opt-out lives in Settings; this screen just renders who's listed.

import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../models/spotlight_models.dart';
import '../providers/reward_provider.dart';

class SpotlightScreen extends StatefulWidget {
  const SpotlightScreen({super.key});

  @override
  State<SpotlightScreen> createState() => _SpotlightScreenState();
}

class _SpotlightScreenState extends State<SpotlightScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<RewardProvider>();
      r.loadSpotlightCreators();
      r.loadSpotlightSupporters();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reward = context.watch<RewardProvider>();

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
          children: [
            // ── Header: prestige framing, not a money chart ───────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spotlight',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      Text('This week’s most celebrated',
                          style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            // ── Tabs ──────────────────────────────────────────────────────────
            TabBar(
              controller: _tabs,
              indicatorColor: VendorTheme.primary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              tabs: const [Tab(text: 'Creators'), Tab(text: 'Supporters')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _board(
                    entries: reward.topCreators,
                    loading: reward.isLoadingSpotlightCreators,
                    coinVerb: 'received',
                    emptyText: 'No creators yet this week.\nBe the first to get celebrated.',
                    onRefresh: () => context.read<RewardProvider>().loadSpotlightCreators(),
                  ),
                  _board(
                    entries: reward.topSupporters,
                    loading: reward.isLoadingSpotlightSupporters,
                    coinVerb: 'gifted',
                    emptyText: 'No supporters yet this week.\nGenerosity gets noticed here.',
                    onRefresh: () => context.read<RewardProvider>().loadSpotlightSupporters(),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Widget _board({
    required List<SpotlightEntry> entries,
    required bool loading,
    required String coinVerb,
    required String emptyText,
    required Future<void> Function() onRefresh,
  }) {
    if (loading && entries.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
    }
    if (entries.isEmpty) {
      return _Empty(text: emptyText);
    }

    final podium = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          _Podium(entries: podium, coinVerb: coinVerb),
          const SizedBox(height: 20),
          ...rest.asMap().entries.map((e) => _RankRow(
            rank: e.key + 4, // podium took 1-3
            entry: e.value,
            coinVerb: coinVerb,
          )),
        ],
      ),
    );
  }
}

// ── Podium (top 3) — understated, no money ──────────────────────────────────
class _Podium extends StatelessWidget {
  final List<SpotlightEntry> entries;
  final String coinVerb;
  const _Podium({required this.entries, required this.coinVerb});

  @override
  Widget build(BuildContext context) {
    SpotlightEntry? at(int i) => i < entries.length ? entries[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumPillar(entry: at(1), rank: 2, height: 96, coinVerb: coinVerb)),
        Expanded(child: _PodiumPillar(entry: at(0), rank: 1, height: 124, coinVerb: coinVerb)),
        Expanded(child: _PodiumPillar(entry: at(2), rank: 3, height: 80, coinVerb: coinVerb)),
      ],
    );
  }
}

class _PodiumPillar extends StatelessWidget {
  final SpotlightEntry? entry;
  final int rank;
  final double height;
  final String coinVerb;
  const _PodiumPillar({required this.entry, required this.rank, required this.height, required this.coinVerb});

  Color get _medal => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFC0C0C0),
    _ => const Color(0xFFCD7F32),
  };

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final e = entry!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          _Avatar(url: e.userAvatar, name: e.userName, size: rank == 1 ? 64 : 52, ring: _medal),
          const SizedBox(height: 6),
          Text(e.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          _TierChip(tier: e.tier),
          const SizedBox(height: 8),
          // Pillar
          Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_medal.withOpacity(0.25), VendorTheme.surface],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: _medal.withOpacity(0.4)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('#$rank', style: GoogleFonts.poppins(color: _medal, fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 14),
                    const SizedBox(width: 3),
                    Text('${e.weeklyCoins}',
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
                Text(coinVerb, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ranked rows (4-10) ───────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final int rank;
  final SpotlightEntry entry;
  final String coinVerb;
  const _RankRow({required this.rank, required this.entry, required this.coinVerb});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('$rank',
                style: GoogleFonts.poppins(color: Colors.white54, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          _Avatar(url: entry.userAvatar, name: entry.userName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                _TierChip(tier: entry.tier),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 16),
              const SizedBox(width: 4),
              Text('${entry.weeklyCoins}',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierChip extends StatelessWidget {
  final SpotlightTier tier;
  const _TierChip({required this.tier});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(tier.label,
          style: GoogleFonts.inter(color: VendorTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double size;
  final Color? ring;
  const _Avatar({required this.url, required this.name, required this.size, this.ring});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ring != null ? Border.all(color: ring!, width: 2.5) : null,
      ),
      child: ClipOval(
        child: (url != null && url!.isNotEmpty)
            ? NetImage(
          url: url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorChild: _initials(initials),
        )
            : _initials(initials),
      ),
    );
  }

  Widget _initials(String t) => Container(
    color: VendorTheme.surface,
    alignment: Alignment.center,
    child: Text(t, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.4)),
  );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, color: Colors.white24, size: 52),
            const SizedBox(height: 14),
            Text(text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }
}