import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../constraints/constants.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../social/models/creator_stats_model.dart';
import '../../social/providers/reward_provider.dart';
import '../../social/screens/buy_coins_screen.dart';

class EarningsTab extends StatelessWidget {
  // final UserProfile profile;
  final CreatorStats? stats;

  const EarningsTab({super.key, this.stats});

  @override
  Widget build(BuildContext context) {
    final rewardProvider = context.watch<RewardProvider>();
    final coinBalance = rewardProvider.coinBalance;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main earnings card - COMPACT
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                // Total cash earned
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cash Earned',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '₦${kFormatter.format(stats?.totalNairaEarned ?? 0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 32, color: Color(0xFF334155)),

                // Coin balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Coins',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          kFormatterNo.format(coinBalance),
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 24,
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
          const SizedBox(height: 16,),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Convert to Cash',
                  icon: Icons.swap_horiz_rounded,
                  color: VendorTheme.primary,
                  onTap: () => _showConvertDialog(context, coinBalance),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Buy Coins',
                  icon: Icons.add_circle_outline,
                  color: VendorTheme.gold,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BuyCoinsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Stats grid - COMPACT
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
                label: 'Total Coins Earned',
                value: kFormatterNo.format(stats?.totalCoinsEarned ?? 0),
                color: VendorTheme.gold,
              ),
              _StatCard(
                icon: Icons.card_giftcard_rounded,
                label: 'Gifts Received',
                value: kFormatterNo.format(stats?.totalGiftsReceived ?? 0),
                color: VendorTheme.primary,
              ),
              _StatCard(
                icon: Icons.trending_up,
                label: 'This Week',
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
        ],
      ),
    );
  }
}

void _showConvertDialog(BuildContext context, int availablePoints) {
  final TextEditingController controller = TextEditingController();
  bool isLoading = false;

  int? selectedAmount = 0;

  final List<int> quickAmounts = [2500, 5000, 10000, 50000, 100000];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,

    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // int enteredAmount = int.tryParse(controller.text) ?? 0;

          int? enteredAmount  = selectedAmount ?? int.tryParse(controller.text);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:  Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.currency_exchange, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Convert Points',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                          Text(
                            'Available: $availablePoints pts',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Quick Select',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: quickAmounts.map((amount) {
                    final isSelected = selectedAmount == amount;
                    return ChoiceChip(
                      label: Text(kFormatter.format(amount)),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedAmount = selected ? amount : null;
                          controller.clear();
                        });
                      },
                      selectedColor: kButtonColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: VendorTheme.surface,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                /// Input
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(

                    hintText: "Enter points to convert",
                    hintStyle: TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: VendorTheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      selectedAmount = null;
                    });
                  },
                ),
                const SizedBox(height: 20),
                /// Conversion Preview
                if (enteredAmount != null && enteredAmount > 0)
                  Text(
                    "You’ll receive ₦$enteredAmount",
                    style: const TextStyle(color: Colors.green),
                  ),

                const SizedBox(height: 20),

                /// Convert Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (enteredAmount == null || enteredAmount <= 0 || isLoading)
                        ? null
                        : () async {
                      setState(() => isLoading = true);

                      try {

                        final api = ApiService();
                        await api.post('/rewards/convert', {
                          "amount": enteredAmount,
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "₦$enteredAmount added to your wallet"),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Conversion failed"),
                          ),
                        );
                      }

                      setState(() => isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kButtonColor,
                      disabledBackgroundColor: kButtonColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Convert Now", style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        elevation: 0,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}