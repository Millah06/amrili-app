// lib/widgets/gift_bottom_sheet.dart - COMPLETE REDESIGN

import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/services/api_service.dart';
import 'package:everywhere/shared/utils/info_box.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../components/transacrtion_pin.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/brain.dart';
import '../../../shared/functions/shared_functions.dart';
import '../../../shared/utils/flush_bar_message.dart';
import '../models/post_model.dart';
import '../models/gift_type.dart';
import '../providers/feed_provider.dart';
import '../providers/reward_provider.dart';

class GiftBottomSheet extends StatefulWidget {
  final Post post;

  const GiftBottomSheet({super.key, required this.post});

  @override
  State<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends State<GiftBottomSheet>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  GiftType? _selectedGift;
  int _quantity = 1; // ADD QUANTITY
  int _coinBalance = 0;
  bool _isLoadingBalance = true;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCoinBalance();
    });


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
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  Future<void> _sendGift() async {
    if (_selectedGift == null) return;

    setState(() => _isProcessing = true);

    try {
      final rewardProvider = context.read<RewardProvider>();

      // Send gift for each quantity
      for (int i = 0; i < _quantity; i++) {
        await rewardProvider.sendGift(
          postId: widget.post.postId,
          giftType: _selectedGift!.id,
        );
      }

      if (mounted) {
        // Update post
        final totalCoins = _selectedGift!.coins * _quantity;
        context.read<FeedProvider>().updatePostAfterGift(
          widget.post.postId,
          widget.post.giftCount + _quantity,
          widget.post.coinTotal + totalCoins,
        );

        Navigator.pop(context);

        _showSuccess(
          '$_quantity ${_selectedGift!.emoji} sent!',
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _openOpay() async {
    if (_selectedGift == null) return;

    setState(() => _isProcessing = true);

    try {
      final api = ApiService();
      final data = await api.post('/opay/deep-link', {});
      print(data);
      if (mounted) {

        _showSuccess(
          '$_quantity ${_selectedGift!.emoji} sent!',
        );

        String cashierUrl = data['data']['data']['cashierUrl'];

        print(cashierUrl);

        Navigator.push(context, MaterialPageRoute(builder: (context) =>
            OpayCheckoutPage(checkoutUrl: cashierUrl,)));
        // Update post
        // SharedFunctions.openDeepLink(cashierUrl);

      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  int get _totalCoins => (_selectedGift?.coins ?? 0) * _quantity;
  double get _totalNaira => (_selectedGift?.naira ?? 0) * _quantity;

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
              colors: [
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with coin balance
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
                      child: const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Send Gift',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            widget.post.userHandle.isNotEmpty ?
                            'to @${widget.post.userHandle}' : 'to @${widget.post.userName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Coin balance badge
                    if (!_isLoadingBalance)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.2),
                              const Color(0xFFFFD700).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFFFD700),
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              kFormatterNo.format(_coinBalance),
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Scrollable gift grid
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Your Gift',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gift grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: GiftType.allGifts.length,
                          itemBuilder: (context, index) {
                            final gift = GiftType.allGifts[index];
                            final isSelected = _selectedGift?.id == gift.id;
                            final canAfford = _coinBalance >= (gift.coins * _quantity);

                            return _GiftCard(
                              gift: gift,
                              isSelected: isSelected,
                              canAfford: canAfford,
                              pulseAnimation: _pulseController,
                              onTap: () {
                                setState(() {
                                  _selectedGift = isSelected ? null : gift;
                                  _quantity = 1; // Reset quantity on new selection
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom section with quantity and send button
              if (_selectedGift != null)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Quantity selector
                      Row(
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),

                          // Minus button
                          _QuantityButton(
                            icon: Icons.remove,
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),

                          // Quantity display
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF21D3ED).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Plus button
                          _QuantityButton(
                            icon: Icons.add,
                            onTap: _quantity < 99
                                ? () => setState(() => _quantity++)
                                : null,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Total cost display
                      if (_coinBalance < _totalCoins)
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '₦${kFormatter.format(((_totalCoins - _coinBalance) / 10))} will be auto-converted from your wallet',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF21D3ED).withOpacity(0.1),
                              const Color(0xFF177E85).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF21D3ED).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Cost',
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
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_totalCoins coins',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '  (₦${kFormatterNo.format(_totalNaira)})',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () => GuestHelper.guardAction(context, action: () {
                            _isProcessing ? null : showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              isDismissible: false,
                              builder: (_) => TransactionPin(
                                  onSuccess: ()  {
                                    // _sendGift();
                                    _openOpay();
                                  }
                              ),
                            );
                          },
                              reason: 'gift creators'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF21D3ED),
                            disabledBackgroundColor: Colors.grey[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFF21D3ED).withOpacity(0.4),
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
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedGift!.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Send $_quantity ${_selectedGift!.name}${_quantity > 1 ? "s" : ""}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0.3,
                                ),
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

class OpayCheckoutPage extends StatefulWidget {
  final String checkoutUrl;

  const OpayCheckoutPage({
    super.key,
    required this.checkoutUrl,
  });

  @override
  State<OpayCheckoutPage> createState() =>
      _OpayCheckoutPageState();
}

class _OpayCheckoutPageState
    extends State<OpayCheckoutPage> {

  late final WebViewController controller;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()

    // VERY IMPORTANT
      ..setJavaScriptMode(JavaScriptMode.unrestricted)

    // Allow background media etc
    //   ..setMediaPlaybackRequiresUserGesture(false)

    // Navigation interception
      ..setNavigationDelegate(
        NavigationDelegate(

          onProgress: (progress) {
            debugPrint("Progress: $progress%");
          },

          onPageStarted: (url) {
            debugPrint("Started: $url");
          },

          onPageFinished: (url) {
            debugPrint("Finished: $url");

            setState(() {
              isLoading = false;
            });
          },

          onNavigationRequest: (request) async {

            final url = request.url;

            debugPrint("Intercepted URL: $url");

            // Allow normal http/https
            if (
            url.startsWith("http://") ||
                url.startsWith("https://")
            ) {
              return NavigationDecision.navigate;
            }

            // Handle deep links / intents
            try {

              final uri = Uri.parse(url);

              if (await canLaunchUrl(uri)) {

                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );

                return NavigationDecision.prevent;
              }

            } catch (e) {
              debugPrint("Deep link error: $e");
            }

            return NavigationDecision.prevent;
          },

        ),
      )

    // Load checkout
      ..loadRequest(
        Uri.parse(widget.checkoutUrl),
      );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor:  Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Secure Payment"),
      ),

      body: Stack(

        children: [

          WebViewWidget(
            controller: controller,
          ),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

        ],
      ),
    );
  }
}

// Gift card widget
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
            colors: [
              Color(0xFF21D3ED),
              Color(0xFF177E85),
            ],
          )
              : null,
          color: isSelected ? null : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : canAfford
                ? Colors.grey[800]!
                : Colors.red.withOpacity(0.1),
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pulse effect for selected
            if (isSelected)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3 * pulseAnimation.value),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // Emoji
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 250),
                  tween: Tween(begin: 1.0, end: isSelected ? 1.15 : 1.0),
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Text(
                        gift.emoji,
                        style: const TextStyle(fontSize: 45),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                // Name
                Text(
                  gift.name,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : canAfford
                        ? Colors.white
                        : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Coins
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : canAfford
                            ? const Color(0xFFFFD700)
                            : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${gift.coins}',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : canAfford
                              ? const Color(0xFFFFD700)
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Naira
                const SizedBox(height: 2),
                Text(
                  '₦${gift.naira.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white70
                        : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Quantity button
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    this.onTap,
  });

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
                ? const Color(0xFF21D3ED).withOpacity(0.4)
                : Colors.grey[700]!,
          ),
        ),
        child: Icon(
          icon,
          color: onTap != null ? const Color(0xFF21D3ED) : Colors.grey[600],
          size: 15,
        ),
      ),
    );
  }
}