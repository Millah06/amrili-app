// lib/features/social/screens/gift_user_screen.dart
//
// PHASE 10 — Gift a USER directly (not a post). DEDICATED SCREEN.
//
// Opened from a profile ("Send a gift"). Mirrors the post gift flow: pick a gift
// + quantity, pay through the universal PaymentSheet in coin mode (coins only,
// no wallet fallback), backend credits the recipient EARNED coins.

import 'package:everywhere/features/payment/widgets/payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../shared/utils/flush_bar_message.dart';
import '../models/gift_type.dart';
import '../providers/reward_provider.dart';
import 'buy_coins_screen.dart';

class GiftUserScreen extends StatefulWidget {
  final String receiverId;
  final String displayName;
  final String? avatarUrl;

  const GiftUserScreen({
    super.key,
    required this.receiverId,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  State<GiftUserScreen> createState() => _GiftUserScreenState();
}

class _GiftUserScreenState extends State<GiftUserScreen> {
  GiftType? _selected;
  int _quantity = 1;
  int _coinBalance = 0;

  int get _totalCoins => (_selected?.coins ?? 0) * _quantity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBalance());
  }

  Future<void> _loadBalance() async {
    final reward = context.read<RewardProvider>();
    await reward.loadCoinBalance();
    if (mounted) setState(() => _coinBalance = reward.coinBalance);
  }

  Future<void> _send() async {
    final gift = _selected;
    if (gift == null) return;

    final sent = await PaymentSheet.coins(
      context,
      coinCost: _totalCoins,
      coinBalance: _coinBalance,
      productName: '$_quantity ${gift.name}${_quantity > 1 ? "s" : ""} → ${widget.displayName}',
      // No wallet fallback — short coins routes to Buy Coins.
      onGetCoins: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyCoinsScreen()));
      },
      onConfirm: () async {
        final reward = context.read<RewardProvider>();
        for (int i = 0; i < _quantity; i++) {
          await reward.sendUserGift(receiverId: widget.receiverId, giftType: gift.id);
        }
        return true;
      },
    );

    if (sent && mounted) {
      await _loadBalance();
      FlushBarMessage.showFlushBar(context: context, message: 'Gift sent to ${widget.displayName}!');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = context.watch<RewardProvider>();
    _coinBalance = reward.coinBalance;
    final gifts = GiftType.allGifts;

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('Gift ${widget.displayName}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Live coin balance.
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 18),
                  const SizedBox(width: 4),
                  Text('$_coinBalance',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: gifts.length,
              itemBuilder: (context, i) {
                final g = gifts[i];
                final selected = _selected?.id == g.id;
                return GestureDetector(
                  onTap: () => setState(() => _selected = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: VendorTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? VendorTheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard_rounded, color: VendorTheme.gold, size: 34),
                        const SizedBox(height: 8),
                        Text(g.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${g.coins} coins',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Quantity + send bar.
          if (_selected != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(color: VendorTheme.surface),
              child: Row(
                children: [
                  _qtyButton(Icons.remove, () {
                    if (_quantity > 1) setState(() => _quantity--);
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_quantity',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                  _qtyButton(Icons.add, () => setState(() => _quantity++)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VendorTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text('Send · $_totalCoins',
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VendorTheme.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}