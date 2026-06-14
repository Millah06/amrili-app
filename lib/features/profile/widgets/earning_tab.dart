// lib/features/profile/widgets/earning_tab.dart
//
// PHASE 10 — Earnings tab. FULL REWRITE (coin-first, region-aware).
//
// Why the rewrite: the old tab led with "₦ Cash Earned" for everyone and had an
// inline convert dialog. That breaks internationally — a non-NG user can't convert
// coins to a wallet, so naira is meaningless to them. Now:
//   • Coins are the universal unit shown to everyone (purchased + earned split).
//   • NG-tied users additionally see what's cashable (₦) and a Cash Out button
//     → ConvertCoinsScreen (the dedicated screen; no more inline dialog).
//   • Non-NG users see coins only — no naira anywhere — with copy that frames
//     earned coins as something to gift onward / be recognised for.
//   • Buy Coins is available to everyone (rail picked by region inside that screen).
//
// Naira stays PRIVATE to this owner-only tab and only for NG; it never appears on
// any public surface (that's what Spotlight is for).

import 'package:everywhere/core/region/region_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../social/models/creator_stats_model.dart';
import '../../social/providers/reward_provider.dart';
import '../../social/screens/buy_coins_screen.dart';
import '../../social/screens/convert_coin_screen.dart';
import '../../social/screens/spotlight_screen.dart';

class EarningsTab extends StatefulWidget {
  final CreatorStats? stats;
  const EarningsTab({super.key, this.stats});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<RewardProvider>();
      r.loadCoinBalance();
      r.loadCreatorStats();
      r.loadCatalog(); // brings conversionRate for the cashable estimate
    });
  }

  @override
  Widget build(BuildContext context) {
    final reward = context.watch<RewardProvider>();
    final isNg = context.watch<RegionProvider>().isNgTied;
    final stats = reward.stats ?? widget.stats;

    final purchased = reward.purchasedCoins;
    final earned = reward.earnedCoins;
    final total = reward.coinBalance;
    final rate = reward.conversionRate <= 0 ? 10 : reward.conversionRate;
    final cashable = isNg ? earned / rate : 0.0; // ₦ value of earned coins (NG only)

    return RefreshIndicator(
      onRefresh: () async {
        await reward.loadCoinBalance();
        await reward.loadCreatorStats();
      },
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Balance card ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: VendorTheme.gold.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isNg ? 'Your balance' : 'Your coins',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  // Total spendable coins.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 30),
                      const SizedBox(width: 8),
                      Text(kFormatterNo.format(total),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6, left: 6),
                        child: Text('coins', style: TextStyle(color: Colors.white54, fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Purchased / Earned split — makes the convertibility rule visible.
                  Row(
                    children: [
                      Expanded(
                        child: _SplitChip(
                          label: 'Purchased',
                          value: kFormatterNo.format(purchased),
                          sub: 'for gifting',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SplitChip(
                          label: 'Earned',
                          value: kFormatterNo.format(earned),
                          sub: isNg ? 'cashable' : 'gift onward',
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                  // NG-only: show what those earned coins are worth, privately.
                  if (isNg && earned > 0) ...[
                    const Divider(height: 28, color: Color(0xFF334155)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cashable now', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('$kNaira${cashable.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: VendorTheme.primary, fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Actions ──────────────────────────────────────────────────────
            Row(
              children: [
                // Cash Out — NG only (non-NG can't convert).
                if (isNg)
                  Expanded(
                    child: _ActionButton(
                      label: 'Cash Out',
                      icon: Icons.account_balance_wallet_outlined,
                      color: VendorTheme.primary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ConvertCoinsScreen())),
                    ),
                  ),
                if (isNg) const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Buy Coins',
                    icon: Icons.add_circle_outline,
                    color: VendorTheme.gold,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BuyCoinsScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Recognition nudge → Spotlight (the viral loop) ───────────────
            _SpotlightNudge(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SpotlightScreen())),
            ),
            const SizedBox(height: 20),

            // ── Stats — coins only, no naira (universal) ─────────────────────
            const Text('This season',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _StatCard(
                  icon: Icons.stars_rounded,
                  label: 'Coins earned',
                  value: kFormatterNo.format(stats?.totalCoinsEarned ?? 0),
                  color: VendorTheme.gold,
                ),
                _StatCard(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Gifts received',
                  value: kFormatterNo.format(stats?.totalGiftsReceived ?? 0),
                  color: VendorTheme.primary,
                ),
                _StatCard(
                  icon: Icons.trending_up,
                  label: 'This week',
                  value: kFormatterNo.format(stats?.weeklyCoins ?? 0),
                  color: VendorTheme.accent,
                ),
                _StatCard(
                  icon: Icons.military_tech,
                  label: 'Level',
                  value: '${stats?.level ?? 1}',
                  color: VendorTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Honest, compliance-clean footnote so users understand the split.
            Text(
              isNg
                  ? 'Only coins you receive as gifts can be cashed out. Coins you '
                  'buy are for gifting and supporting others.'
                  : 'Coins you receive as gifts can be sent on to other creators. '
                  'Coins you buy are for gifting and supporting others.',
              style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Split chip (Purchased / Earned) ─────────────────────────────────────────
class _SplitChip extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final bool highlight;
  const _SplitChip({required this.label, required this.value, required this.sub, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? VendorTheme.primary.withOpacity(0.5) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 16),
              const SizedBox(width: 4),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Spotlight nudge ──────────────────────────────────────────────────────────
class _SpotlightNudge extends StatelessWidget {
  final VoidCallback onTap;
  const _SpotlightNudge({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [VendorTheme.primary.withOpacity(0.15), VendorTheme.surface],
            ),
            border: Border.all(color: VendorTheme.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: VendorTheme.gold, size: 22),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('See who’s being celebrated this week',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action button ────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}