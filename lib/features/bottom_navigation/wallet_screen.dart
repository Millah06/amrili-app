// lib/features/bottom_navigation/wallet_screen.dart
//
// PHASE 9 — The Wallet becomes the hub.
// ─────────────────────────────────────────────────────────────────────────────
// With the Services tab gone, the Wallet screen now carries the gated entries:
//
//   NG-tied users   → full wallet (balance, fund, transfer, withdraw)
//                     + "Bills & Top-ups" card  → pushes HomeScreen (the old
//                       Services screen, now a destination instead of a tab)
//                     + "Marketplace" feature card → pushes VendorEngineEntry
//   International   → premium "coming to your region" preview that teases the
//                     Phase-10 coin wallet, plus a "Nigerian abroad?" link to
//                     HomeCountrySheet (the foreign-SIM diaspora fix)
//
// What changed vs the old file (and why):
//  - CRYPTO REMOVED PERMANENTLY (binding decision): the crypto action, the
//    CryptoWalletScreen import, and the fake NGN/USDT math are gone.
//  - The Firestore StreamBuilder around the balance row is gone: its snapshot
//    data was never read — every figure came from UserProvider — so all it did
//    was flash a spinner and burn a listener. Balances render directly.
//  - The fragile Stack (270px header + content absolutely offset at 310px) is
//    replaced by a single CustomScrollView: hero, actions, cards and the
//    transaction list scroll as ONE surface — no overlap math, no overflow on
//    small screens, and the transaction list no longer fights the header for
//    height.
//  - New-code money formatting goes through Money (core/money/money.dart);
//    BalanceText is kept for the big animated figures (existing pattern).
//
// Unchanged on purpose: PullRevealOverlayWrapper, Brain-backed transaction
// list (RecentFrame → ViewReceipt), AccountInformation funding sheet, eye
// toggle starting HIDDEN (privacy-first, as before), HelpCenter entry.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:everywhere/components/wallet_balance.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/support/help_center.dart';
import 'package:everywhere/providers/transaction_provider.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:everywhere/shared/widgets/pull_to_reveal.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';

import '../../components/recent_frame.dart';
import '../../components/service_fraame.dart';
import '../../components/view_receipt.dart';
import '../../core/analytics/analytics.dart';
import '../../core/money/money.dart';
import '../../core/region/region_provider.dart';
import '../../services/brain.dart';
import '../../shared/widgets/account_information.dart';
import '../../shared/widgets/home_country_sheet.dart';
import '../marketPlace/utils/vendor_engine_entry.dart';
import '../wallet/pages/p2p_transfer_screen.dart';
import '../wallet/pages/withdraw_bank_screen.dart';
import '../../screens/services_screen.dart'; // HomeScreen — the Services page, now pushed

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  static String id = 'wallet';

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  /// true = balances hidden (asterisks). Starts hidden — privacy-first, same
  /// default the old screen shipped with.
  bool _hidden = true;

  void _toggleHidden() => setState(() => _hidden = !_hidden);

  @override
  void initState() {
    super.initState();
    // Load transactions lazily — only when the Wallet tab is first visited,
    // not on cold start. PageView keeps this widget alive so initState fires once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<TransactionProvider>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isNgTied = context.watch<RegionProvider>().isNgTied;

    final double availableBalance =
        userProvider.user?.wallet.fiat.availableBalance ?? 0.0;
    final double rewardBalance =
        userProvider.user?.wallet.fiat.rewardBalance ?? 0.0;

    return PullRevealOverlayWrapper(
      controller: PullToRevealController(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        // One scroll surface for the whole page. Slivers keep the transaction
        // list lazy (builder) while letting the hero/cards scroll away
        // naturally — the old fixed-header layout wasted half the viewport.
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Hero: brand gradient, total assets, help ───────────────────
            SliverToBoxAdapter(
              child: _Hero(
                hidden: _hidden,
                onToggleHidden: _toggleHidden,
                isNgTied: isNgTied,
                availableBalance: availableBalance,
                rewardBalance: rewardBalance,
              ),
            ),

            if (isNgTied) ...[
              // ── Quick actions: Transfer · Withdraw · Bills ───────────────
              SliverToBoxAdapter(
                child: _QuickActions(
                  onTransfer: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const P2PTransferScreen()),
                  ),
                  onWithdraw: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const WithdrawBankScreen()),
                  ),
                  onBills: () {
                    Analytics.I.logBillsOpen();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
              ),

              // ── Marketplace feature card (the relocated entry) ───────────
              SliverToBoxAdapter(
                child: _MarketplaceCard(
                  onTap: () {
                    Analytics.I.logMarketplaceOpen();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VendorEngineEntry()),
                    );
                  },
                ),
              ),
            ] else
            // ── International: premium coming-soon / coins teaser ────────
              SliverToBoxAdapter(
                child: _InternationalPreview(
                  onSetHomeCountry: () => HomeCountrySheet.show(context),
                ),
              ),

            // ── Recent transactions ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                const EdgeInsets.only(left: 15, right: 15, top: 18, bottom: 6),
                child: Text(
                  'Recent Transactions',
                  style: GoogleFonts.poppins(
                      fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (pov.transactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Text('No Transactions yet',
                        style: GoogleFonts.inter(color: Colors.white54)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding:
                const EdgeInsets.only(left: 15, right: 15, bottom: 90),
                sliver: SliverList.builder(
                  itemCount: pov.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = pov.transactions[index];
                    return RecentFrame(
                      beneficiary: transaction['Product Name'] ?? '',
                      date: (transaction['Date']).toDate(),
                      amount: (transaction['Paid Amount'] as num).toString(),
                      status: transaction['Status'] ?? '0',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewReceipt(
                                transactionId:
                                transaction['Transaction ID']),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO — brand gradient header. NG: total assets + NGN/Reward card + Add
// Funds. International: a calmer globe header (no figures — there is nothing
// to show yet, and an eternal ₦0.00 would read as broken).
// ─────────────────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  final bool hidden;
  final VoidCallback onToggleHidden;
  final bool isNgTied;
  final double availableBalance;
  final double rewardBalance;

  const _Hero({
    required this.hidden,
    required this.onToggleHidden,
    required this.isNgTied,
    required this.availableBalance,
    required this.rewardBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 18),
      decoration: const BoxDecoration(
        // Same brand wash the old header used — kept so the screen still
        // "feels" like the Amril wallet, just tidier.
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF0D9488),
            Color(0xFF0F172A),
            Color(0xFF0D9488),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: title/total-assets label + HELP ──────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_moon_outlined,
                          size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      const Text(
                        'Total Assets',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'DejaVu Sans',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isNgTied)
                        GestureDetector(
                          onTap: onToggleHidden,
                          // 24px+ hit area would be tight; the icon row is
                          // padded by the parent so the target stays usable.
                          child: FaIcon(
                            hidden
                                ? FontAwesomeIcons.eyeSlash
                                : FontAwesomeIcons.eye,
                            size: 13,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  // HELP — unchanged behavior, slightly tightened visuals.
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HelpCenter()),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'HELP',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const FaIcon(FontAwesomeIcons.headset,
                            size: 24, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Total assets figure (NG only) ─────────────────────────────
            if (isNgTied)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: hidden
                    ? Text('******', style: kMoneyStyle)
                    : Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    BalanceText(
                        availableBalance + rewardBalance, 24, 14),
                    const SizedBox(width: 5),
                    Text(
                      Money.defaultCurrency,
                      style: kMoneyStyle.copyWith(
                          fontFamily: 'DejaVu Sans', fontSize: 12),
                    ),
                  ],
                ),
              )
            else
            // International: identity line instead of a meaningless ₦0.
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  'Amril Wallet',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

            // ── NGN / Reward balance card + Add Funds (NG only) ───────────
            if (isNgTied)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F172A),
                      Color(0xFF0D9488),
                      Color(0xFF0F172A),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF177E85).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Labels row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_moon_outlined,
                                size: 18, color: Colors.white70),
                            const SizedBox(width: 2),
                            Text('NGN Wallet Balance', style: kWalletStyle),
                          ],
                        ),
                        Text('Reward Balance', style: kWalletStyle),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Figures row — rendered straight from UserProvider. The
                    // old Firestore StreamBuilder here never used its
                    // snapshot's data; it only delayed this exact row.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        hidden
                            ? Text('******', style: kMoneyStyle)
                            : Row(
                          textBaseline: TextBaseline.alphabetic,
                          crossAxisAlignment:
                          CrossAxisAlignment.baseline,
                          children: [
                            Text(
                              Money.symbol(),
                              style: kMoneyStyle.copyWith(
                                  fontFamily: 'DejaVu Sans',
                                  fontSize: 18),
                            ),
                            const SizedBox(width: 2),
                            BalanceText(availableBalance, 30, 18),
                          ],
                        ),
                        hidden
                            ? Text('******', style: kMoneyStyle)
                            : Row(
                          children: [
                            Text(
                              Money.symbol(),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 3),
                            BalanceText(rewardBalance, 20, 10),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Add Funds — opens the DVA AccountInformation sheet,
                    // exactly as before.
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (_) => FractionallySizedBox(
                            heightFactor: 0.4,
                            child: AccountInformation(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF177E85),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Add Funds', style: kExpenseStyle),
                            const FaIcon(FontAwesomeIcons.circlePlus,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK ACTIONS — Transfer · Withdraw · Bills & Top-ups. Reuses ServiceFrame
// (the app's standard action tile) inside the same 0xFF1E293B card the old
// action row used, so it reads as an evolution, not a redesign. Crypto's slot
// is taken by Bills & Top-ups — the Services screen's new front door.
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onTransfer;
  final VoidCallback onWithdraw;
  final VoidCallback onBills;

  const _QuickActions({
    required this.onTransfer,
    required this.onWithdraw,
    required this.onBills,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E293B),
      ),
      child: SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ServiceFrame(
              title: 'Transfer',
              icon: FontAwesomeIcons.moneyBillTransfer,
              onTap: onTransfer,
              isNew: false,
              titleFont: 11,
            ),
            ServiceFrame(
              title: 'Withdraw',
              icon: FontAwesomeIcons.moneyBill,
              onTap: onWithdraw,
              isNew: false,
              titleFont: 11,
            ),
            ServiceFrame(
              title: 'Bills & Top-ups',
              icon: FontAwesomeIcons.boltLightning,
              onTap: onBills,
              isNew: true, // freshly relocated — the badge teaches the move
              titleFont: 11,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARKETPLACE CARD — the relocated marketplace entry. Premium gradient
// feature-card language (the same treatment the dine-in card got on
// OverviewTab in Phase 7): brand gradient sliver of color on a dark card,
// storefront icon in a glowing ring, chevron affordance.
// ─────────────────────────────────────────────────────────────────────────────
class _MarketplaceCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MarketplaceCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF134E4A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF21D3ED).withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF177E85).withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon in a glowing brand ring — the card's focal point.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF21D3ED), Color(0xFF177E85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF21D3ED).withOpacity(0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.bagShopping,
                    size: 18, color: Colors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop & Dine',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Discover stores, order food & track deliveries',
                    style: GoogleFonts.inter(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNATIONAL PREVIEW — what a non-NG-tied user sees instead of funding /
// bills / marketplace. Deliberately premium, not apologetic: this surface is
// where the Phase-10 coin wallet will live, so it teases coins concretely and
// offers the diaspora escape hatch (Home country) prominently.
// ─────────────────────────────────────────────────────────────────────────────
class _InternationalPreview extends StatelessWidget {
  final VoidCallback onSetHomeCountry;

  const _InternationalPreview({required this.onSetHomeCountry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF21D3ED).withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Globe in a brand ring — mirrors the marketplace card's focal
          // treatment so both regions share one design language.
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF21D3ED), Color(0xFF177E85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF21D3ED).withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(FontAwesomeIcons.earthAfrica,
                  size: 22, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your wallet is on its way',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amril coins are coming to your region — buy coins, gift them on '
                'posts, support creators, and send gifts to friends anywhere.',
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 13,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          // Concrete teaser rows — three coin verbs, not vague marketing.
          const _PreviewRow(
              icon: FontAwesomeIcons.coins, label: 'Buy & gift Amril coins'),
          const _PreviewRow(
              icon: FontAwesomeIcons.heart, label: 'Support your favorite creators'),
          const _PreviewRow(
              icon: FontAwesomeIcons.paperPlane,
              label: 'Send gifts to friends worldwide'),
          const SizedBox(height: 16),
          // The diaspora fix, framed as a benefit — not a settings chore.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSetHomeCountry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF21D3ED),
                side: BorderSide(
                    color: const Color(0xFF21D3ED).withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const FaIcon(FontAwesomeIcons.flag, size: 14),
              label: Text(
                'Nigerian abroad? Set your home country',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One teaser line: small brand icon + label. Kept tiny and reusable so the
/// Phase-10 coin wallet can recycle the same rows for real features.
class _PreviewRow extends StatelessWidget {
  final FaIconData icon;
  final String label;

  const _PreviewRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: const Color(0xFF21D3ED)),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}