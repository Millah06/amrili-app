import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../components/transacrtion_pin.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/brain.dart';
import '../../../shared/utils/flush_bar_message.dart';
import '../models/gift_type.dart';
import '../providers/reward_provider.dart';


class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  int? _selectedAmount;
  final TextEditingController _customController = TextEditingController();
  bool _isProcessing = false;
  int _coinBalance = 0;
  double _walletBalance = 0;

  final List<int> _quickAmounts = [
    100,   // ₦10
    500,   // ₦50
    1000,  // ₦100
    2000,  // ₦200
    5000,  // ₦500
    10000, // ₦1000
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBalances());
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _loadBalances() async {
    final rewardProvider = context.read<RewardProvider>();
    await rewardProvider.loadCoinBalance();

    // Get wallet balance from Brain provider
    final brain = context.read<UserProvider>();

    if (mounted) {
      setState(() {
        _coinBalance = rewardProvider.coinBalance;
        _walletBalance = brain.user!.wallet.fiat.availableBalance;
      });
    }
  }

  Future<void> _buyCoins() async {
    final amount = _selectedAmount ?? int.tryParse(_customController.text);
    if (amount == null || amount < 10) {
      _showError('Minimum purchase is 10 coins (₦1)');
      return;
    }

    final nairaAmount = amount / 10;
    if (nairaAmount > _walletBalance) {
      _showError('Insufficient wallet balance');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Deduct from wallet and credit coins
      final brain = context.read<UserProvider>();
      // await brain.deductWallet(nairaAmount);

      final rewardProvider = context.read<RewardProvider>();
      await rewardProvider.loadCoinBalance();

      if (mounted) {
        setState(() {
          _coinBalance = rewardProvider.coinBalance;
          _walletBalance = brain.user!.wallet.fiat.availableBalance;
        });

        _showSuccess('₦${nairaAmount.toStringAsFixed(2)} converted to $amount coins!');

        // Reset selection
        setState(() {
          _selectedAmount = null;
          _customController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    FlushBarMessage.showFlushBar(
      context: context,
      message: message,
      title: 'Error',
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showSuccess(String message) {
    FlushBarMessage.showFlushBar(
      context: context,
      message: message,
      title: 'Success',
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedAmount = _selectedAmount ?? int.tryParse(_customController.text) ?? 0;
    final nairaAmount = selectedAmount / 10;

    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buy Coins',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance cards
            Row(
              children: [
                Expanded(
                  child: _BalanceCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Wallet',
                    amount: '₦${kFormatter.format(_walletBalance)}',
                    color: VendorTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BalanceCard(
                    icon: Icons.stars_rounded,
                    label: 'Coins',
                    amount: kFormatterNo.format(_coinBalance),
                    color: VendorTheme.gold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Conversion info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VendorTheme.primary.withOpacity(0.15),
                    VendorTheme.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: VendorTheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: VendorTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: VendorTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      '₦1 = 10 coins\nBuy coins to send gifts',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Quick amounts
            const Text(
              'Quick Buy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: _quickAmounts.length,
              itemBuilder: (context, index) {
                final coins = _quickAmounts[index];
                final isSelected = _selectedAmount == coins;

                return _QuickAmountCard(
                  coins: coins,
                  naira: coins / 10,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedAmount = isSelected ? null : coins;
                      _customController.clear();
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 28),

            // Custom amount
            const Text(
              'Custom Amount',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Enter coins amount',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.stars_rounded, color: VendorTheme.gold),
                filled: true,
                fillColor: VendorTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: VendorTheme.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedAmount = null;
                });
              },
            ),

            const SizedBox(height: 28),

            // Preview popular gifts
            const Text(
              'Popular Gifts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final gift = GiftType.allGifts[index];
                  return _GiftPreview(gift: gift);
                },
              ),
            ),

            const SizedBox(height: 32),

            // Buy summary
            if (selectedAmount > 0)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: VendorTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: VendorTheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You Pay',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        Text(
                          '₦${nairaAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'You Get',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: VendorTheme.gold, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$selectedAmount coins',
                              style: const TextStyle(
                                color: VendorTheme.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Buy button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (selectedAmount > 0 && !_isProcessing)
                    ? () {
                  showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    isDismissible: false,
                    builder: (_) => TransactionPin(
                      onSuccess: () async {
                          Navigator.pop(context);
                          _buyCoins();
                        }

                    ),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  disabledBackgroundColor: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: VendorTheme.primary.withOpacity(0.4),
                ),
                child: _isProcessing
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                  ),
                )
                    : const Text(
                  'Buy Coins',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _BalanceCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountCard extends StatelessWidget {
  final int coins;
  final double naira;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickAmountCard({
    required this.coins,
    required this.naira,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [VendorTheme.primary, Color(0xFF177E85)],
          )
              : null,
          color: isSelected ? null : VendorTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : VendorTheme.primary.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: isSelected ? Colors.white : VendorTheme.gold,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  kFormatterNo.format(coins),
                  style: TextStyle(
                    color: isSelected ? Colors.white : VendorTheme.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '₦${naira.toStringAsFixed(0)}',
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GiftPreview extends StatelessWidget {
  final GiftType gift;

  const _GiftPreview({required this.gift});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(gift.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            '${gift.coins}',
            style: const TextStyle(
              color: VendorTheme.gold,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}