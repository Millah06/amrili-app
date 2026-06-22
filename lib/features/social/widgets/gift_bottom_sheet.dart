// lib/features/social/widgets/gift_bottom_sheet.dart
//
// Gift sheet — gift grid + quantity stay here (gift-specific UI); the PAYMENT
// (PIN → processing → success) is delegated to the universal `PaymentSheet`
// in coin mode, so gifting looks/behaves like every other payment.
//
// Coins-else-wallet: the backend `sendGift` decrements the coin balance if
// sufficient, otherwise debits the available wallet balance for the shortfall.
// The sheet reflects this — when coins are short it shows the ₦ amount that
// will come from the wallet and proceeds (PIN), instead of blocking.

import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/features/payment/widgets/payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constraints/constants.dart';
import '../../../shared/functions/shared_functions.dart';
import '../models/post_model.dart';
import '../models/gift_type.dart';
import '../providers/feed_provider.dart';
import '../providers/reward_provider.dart';
import '../screens/buy_coins_screen.dart';

// 10 coins = ₦1 (matches the existing conversion used across the app).
const double _kCoinsPerNaira = 10;

class GiftBottomSheet extends StatefulWidget {
  final Post post;
  const GiftBottomSheet({super.key, required this.post});

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet>
    with SingleTickerProviderStateMixin {
  GiftType? _selectedGift;
  int _quantity = 1;
  int _coinBalance = 0;
  bool _isLoadingBalance = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCoinBalance());
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadCoinBalance() async {
    try {
      final rewardProvider = context.read<RewardProvider>();
      await rewardProvider.loadCoinBalance();
      if (mounted) {
        setState(() {
          _coinBalance = rewardProvider.coinBalance;
          _isLoadingBalance = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  int get _totalCoins => (_selectedGift?.coins ?? 0) * _quantity;
  double get _totalNaira => (_selectedGift?.naira ?? 0) * _quantity;
  bool get _coinsShort => _coinBalance < _totalCoins;
  double get _walletShortfallNaira =>
      _coinsShort ? (_totalCoins - _coinBalance) / _kCoinsPerNaira : 0;

  /// Open the universal payment sheet in coin mode. It handles PIN → processing
  /// → success; `onConfirm` performs the actual gift send (coins-else-wallet on
  /// the backend). Returns true when sent.
  Future<void> _openPayment() async {
    final gift = _selectedGift;
    if (gift == null) return;

    final sent = await PaymentSheet.coins(
      context,
      coinCost: _totalCoins,
      coinBalance: _coinBalance,
      productName: '$_quantity ${gift.name}${_quantity > 1 ? "s" : ""}',
      onGetCoins: () {
        Navigator.pop(context); // close gift sheet
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BuyCoinsScreen()));
      },
      onConfirm: () async {
        final reward = context.read<RewardProvider>();
        for (int i = 0; i < _quantity; i++) {
          await reward.sendGift(postId: widget.post.postId, giftType: gift.id);
        }
        return true;
      },
    );

    if (sent && mounted) {
      // Reflect the gift on the post immediately.
      final totalCoins = gift.coins * _quantity;
      context.read<FeedProvider>().updatePostAfterGift(
        widget.post.postId,
        widget.post.giftCount + _quantity,
        widget.post.coinTotal + totalCoins,
      );
      Navigator.pop(context); // close the gift sheet (PaymentSheet showed success)
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header + coin balance badge
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF21D3ED), Color(0xFF177E85)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF21D3ED).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: Colors.white, size: 25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Send Gift',
                              style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          Text(
                            widget.post.userHandle.isNotEmpty
                                ? 'to @${widget.post.userHandle}'
                                : 'to @${widget.post.userName}',
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    if (!_isLoadingBalance)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            const Color(0xFFFFD700).withOpacity(0.2),
                            const Color(0xFFFFD700).withOpacity(0.1),
                          ]),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.4), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded,
                                color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 6),
                            Text(kFormatterNo.format(_coinBalance),
                                style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Gift grid
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Choose Your Gift',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 16),
                        LayoutBuilder(builder: (context, gc) {
                          final cols = gc.maxWidth >= 460 ? 4 : 3;
                          return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: GiftType.allGifts.length,
                          itemBuilder: (context, index) {
                            final gift = GiftType.allGifts[index];
                            final isSelected = _selectedGift?.id == gift.id;
                            // Cards never look "unaffordable" now — wallet covers
                            // any shortfall — so always show as affordable.
                            return _GiftCard(
                              gift: gift,
                              isSelected: isSelected,
                              canAfford: true,
                              pulseAnimation: _pulseController,
                              onTap: () {
                                setState(() {
                                  _selectedGift = isSelected ? null : gift;
                                  _quantity = 1;
                                });
                              },
                            );
                          },
                        );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom: quantity + cost + send
              if (_selectedGift != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Quantity',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF21D3ED).withOpacity(0.3)),
                            ),
                            child: Text('$_quantity',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: _quantity < 99
                                ? () => setState(() => _quantity++)
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_coinsShort)
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '₦${kFormatter.format(_walletShortfallNaira)} will be charged from your wallet',
                                style: const TextStyle(color: Colors.orange, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            const Color(0xFF21D3ED).withOpacity(0.1),
                            const Color(0xFF177E85).withOpacity(0.05),
                          ]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFF21D3ED).withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Cost',
                                style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Row(
                              children: [
                                const Icon(Icons.stars_rounded,
                                    color: Color(0xFFFFD700), size: 18),
                                const SizedBox(width: 6),
                                Text('$_totalCoins coins',
                                    style: const TextStyle(
                                        color: Color(0xFFFFD700),
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                                Text('  (₦${kFormatterNo.format(_totalNaira)})',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () => GuestHelper.guardAction(
                            context,
                            action: _openPayment,
                            reason: 'gift creators',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF21D3ED),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: const Color(0xFF21D3ED).withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_selectedGift!.emoji,
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Text(
                                'Send $_quantity ${_selectedGift!.name}${_quantity > 1 ? "s" : ""}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Gift card (your design, retained).
class _GiftCard extends StatelessWidget {
  final GiftType gift;
  final bool isSelected;
  final bool canAfford;
  final AnimationController pulseAnimation;
  final VoidCallback onTap;

  const _GiftCard({
    required this.gift,
    required this.isSelected,
    required this.canAfford,
    required this.pulseAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF21D3ED), Color(0xFF177E85)],
          )
              : null,
          color: isSelected ? null : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[800]!,
            width: isSelected ? 0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF21D3ED).withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 250),
              tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(gift.emoji, style: const TextStyle(fontSize: 45)),
            ),
            const SizedBox(height: 8),
            Text(gift.name,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFFFFD700)),
                  const SizedBox(width: 4),
                  Text('${gift.coins}',
                      style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text('₦${gift.naira.toStringAsFixed(0)}',
                style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QuantityButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap != null
              ? const Color(0xFF21D3ED).withOpacity(0.15)
              : Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: onTap != null
                ? const Color(0xFF21D3ED).withValues(alpha: 0.4)
                : Colors.grey[700]!,
          ),
        ),
        child: Icon(icon,
            color: onTap != null ? const Color(0xFF21D3ED) : Colors.grey[600],
            size: 15),
      ),
    );
  }
}