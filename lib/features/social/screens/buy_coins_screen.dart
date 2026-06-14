// lib/features/social/screens/buy_coins_screen.dart
//
// PHASE 10 — Buy Coins. FULL REPLACEMENT.
//
// Region-aware, two rails (decided by RegionProvider.isNgTied):
//   • NG-tied   → packs priced in ₦ (from /coins/catalog); tapping opens the
//                 universal PaymentSheet with entityType "coin_purchase", so the
//                 user pays with Wallet OR OPay — same sheet as every order.
//   • non-NG    → packs come from the app store via in_app_purchase; the price
//                 shown is the STORE's localized price (e.g. $4.99). Tapping
//                 launches the native purchase; the backend verifies the receipt
//                 and mints the coins.
//
// Both rails mint PURCHASED (spend-only) coins. The old wallet→coins conversion
// at ₦1=10 is GONE — that round-trip is not allowed.

import 'package:everywhere/core/region/region_provider.dart';
import 'package:everywhere/features/payment/widgets/payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../shared/utils/flush_bar_message.dart';
import '../providers/reward_provider.dart';
import '../services/coin_purchase_services.dart';

class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  // Non-NG (store) state.
  final _store = CoinPurchaseService.instance;
  List<ProductDetails> _products = [];
  bool _storeAvailable = false;
  bool _loadingProducts = false;
  String? _pendingProductId; // a buy is in flight for this SKU

  bool get _isNg => context.read<RegionProvider>().isNgTied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    if (!_isNg) _store.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final reward = context.read<RewardProvider>();
    await reward.loadCoinBalance();

    if (_isNg) {
      // NG packs come from our catalog (naira pricing).
      await reward.loadCatalog();
    } else {
      // Non-NG: wire the store stream + query products.
      _store.onDelivered = _onStoreDelivered;
      _store.init();
      setState(() => _loadingProducts = true);
      _storeAvailable = await _store.isAvailable;
      if (_storeAvailable) {
        _products = await _store.queryProducts();
      }
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  // ── NG: pay a pack through the universal sheet (Wallet / OPay) ───────────────
  Future<void> _buyNg(CoinPack pack) async {
    final result = await PaymentSheet.show(
      context,
      amount: pack.nairaWallet,
      entityType: 'coin_purchase',
      entityId: pack.productId, // pack SKU doubles as the engine entityId
      productName: pack.label,
    );
    if (result != null && mounted) {
      // The coin_purchase handler already minted the coins on SUCCESS.
      await context.read<RewardProvider>().loadCoinBalance();
      FlushBarMessage.showFlushBar(context: context, message: '${pack.coins} coins added!');
    }
  }

  // ── Non-NG: launch the native store purchase ─────────────────────────────────
  Future<void> _buyStore(ProductDetails product) async {
    setState(() => _pendingProductId = product.id);
    try {
      await _store.buy(product);
      // Result arrives asynchronously on the purchase stream → _onStoreDelivered.
    } catch (e) {
      if (mounted) {
        setState(() => _pendingProductId = null);
        FlushBarMessage.showFlushBar(context: context, message: 'Could not start purchase');
      }
    }
  }

  Future<void> _onStoreDelivered(String productId, bool success) async {
    if (!mounted) return;
    setState(() => _pendingProductId = null);
    if (success) {
      await context.read<RewardProvider>().loadCoinBalance();
      FlushBarMessage.showFlushBar(context: context, message: '${coinsForProduct(productId)} coins added!');
    } else {
      FlushBarMessage.showFlushBar(context: context, message:  'Purchase could not be verified');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = context.watch<RewardProvider>();

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Buy Coins', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BalanceHeader(
            purchased: reward.purchasedCoins,
            earned: reward.earnedCoins,
          ),
          const SizedBox(height: 20),
          // Plain-language explainer — purchased coins are for gifting/boosting.
          _InfoNote(
            text: _isNg
                ? 'Coins are for sending gifts and boosting posts. Pay with your '
                'wallet or OPay. Coins you buy can\'t be withdrawn — only coins '
                'you receive as gifts can be converted.'
                : 'Coins are for sending gifts and boosting posts. Prices are set '
                'by the App Store / Google Play in your local currency.',
          ),
          const SizedBox(height: 24),
          const Text('Choose a pack',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          if (_isNg)
            _buildNgPacks(reward)
          else
            _buildStorePacks(),
        ],
      ),
    );
  }

  // NG packs — coins + ₦ price.
  Widget _buildNgPacks(RewardProvider reward) {
    if (reward.packs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: VendorTheme.primary)),
      );
    }
    return Column(
      children: reward.packs
          .map((p) => _PackTile(
        coins: p.coins,
        priceLabel: '₦${p.nairaWallet.toStringAsFixed(0)}',
        onTap: () => _buyNg(p),
      ))
          .toList(),
    );
  }

  // Non-NG packs — coins + store-localized price.
  Widget _buildStorePacks() {
    if (_loadingProducts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: VendorTheme.primary)),
      );
    }
    if (!_storeAvailable || _products.isEmpty) {
      // NOT_CONFIGURED era (no store products yet) or store unavailable (e.g. web).
      return const _EmptyStore();
    }
    // Store returns products unsorted-by-coins; the service already sorted them.
    return Column(
      children: _products
          .map((prod) => _PackTile(
        coins: coinsForProduct(prod.id),
        priceLabel: prod.price, // localized by the store, shown verbatim
        loading: _pendingProductId == prod.id,
        onTap: _pendingProductId == null ? () => _buyStore(prod) : null,
      ))
          .toList(),
    );
  }
}

// ── Widgets ─────────────────────────────────────────────────────────────────

class _BalanceHeader extends StatelessWidget {
  final int purchased;
  final int earned;
  const _BalanceHeader({required this.purchased, required this.earned});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VendorTheme.primary, Color(0xFF177E85)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 8),
              Text('${purchased + earned}',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('coins', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Show the split so the convertibility rule is visible.
          Row(
            children: [
              _miniStat('Purchased', purchased, 'spend only'),
              const SizedBox(width: 20),
              _miniStat('Earned', earned, 'convertible'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int value, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label · $value',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      Text(sub, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ],
  );
}

class _PackTile extends StatelessWidget {
  final int coins;
  final String priceLabel;
  final VoidCallback? onTap;
  final bool loading;
  const _PackTile({required this.coins, required this.priceLabel, this.onTap, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 26),
                const SizedBox(width: 14),
                Text('$coins coins',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (loading)
                  const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: VendorTheme.primary),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: VendorTheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(priceLabel,
                        style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: VendorTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
        ],
      ),
    );
  }
}

class _EmptyStore extends StatelessWidget {
  const _EmptyStore();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: const [
          Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 48),
          SizedBox(height: 12),
          Text('Coin purchases are coming soon',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Check back shortly.', style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}