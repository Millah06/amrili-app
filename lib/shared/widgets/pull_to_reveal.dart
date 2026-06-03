import 'package:everywhere/core/auth/guest_helper.dart';
import 'package:everywhere/features/support/help_center.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:everywhere/features/utility/screens/utility_screens/airtime_gift.dart';
import 'package:everywhere/screens/pages/transaction_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_reveal_flutter/pull_to_reveal_flutter.dart';

import '../../constraints/vendor_theme.dart';
import '../../features/profile/screens/settings_screeen.dart';
import '../../features/bottom_navigation/wallet/pages/withdraw_bank_screen.dart';
import '../../features/marketPlace/utils/vendor_engine_entry.dart';

class PullRevealOverlayWrapper extends StatefulWidget {
  final Widget child;
  final PullToRevealController controller;

  const PullRevealOverlayWrapper({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  State<PullRevealOverlayWrapper> createState() =>
      _PullRevealOverlayWrapperState();
}

class _PullRevealOverlayWrapperState
    extends State<PullRevealOverlayWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  String _label = '';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _opacity = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scale = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    widget.controller.addListener(_onStateChange);
  }

  void _onStateChange() {
    final state = widget.controller.state;

    switch (state) {
      case RevealState.idle:
        _animController.reverse();
        break;

      case RevealState.pulling:
        _label = 'Pulling...access quick actions';
        _animController.forward();
        break;

      case RevealState.armed:
        _label = 'Release to open';
        _animController.forward();
        break;

      case RevealState.revealed:
        _label = 'Opening...';
        _animController.forward();
        break;
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PullToReveal(
            threshold: 60,
            resistanceFactor: 0.25,
            controller: widget.controller,
            background: BackgroundWidget(
                onCancel: () {
              widget.controller.dismiss();
            }),
            onReveal: GuestHelper.isGuest ? () {} : () {
              Navigator.push(context, MaterialPageRoute(builder: (context) =>
                  VendorEngineEntry(searchParam: null,)));
            },
            child: widget.child,
          ),
          if (!widget.controller.isRevealed)
          // Overlay
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: true,
              child: FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: Center(
                    child: _OverlayCard(label: _label),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  final String label;

  const _OverlayCard({required this.label});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    if (label.contains('Pulling')) {
      icon = Icons.arrow_downward;
    } else if (label.contains('Release')) {
      icon = Icons.lock_open;
    } else {
      icon = Icons.storefront;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: VendorTheme.background.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class BackgroundWidget extends StatelessWidget {
  final Function() onCancel;

  const BackgroundWidget({
    super.key,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 HEADER
              Row(
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white54),
                      ),
                      child: const Row(
                        children: [
                          Text('Close'),
                          SizedBox(width: 6),
                          Icon(Icons.close, size: 18),
                        ],
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              /// ⚡ QUICK ACTION GRID
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  children: [
                    _ActionItem(
                      icon: Icons.storefront,
                      label: "Marketplace",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) =>
                            VendorEngineEntry(searchParam: null,)));
                      },
                    ),
                    _ActionItem(
                      icon: Icons.account_balance_wallet,
                      label: "Withdraw",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => WithdrawBankScreen()));
                      },
                    ),
                    _ActionItem(
                      icon: Icons.card_giftcard,
                      label: "Gifts",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AirtimeGift()));
                      },
                    ),
                    _ActionItem(
                      icon: Icons.settings,
                      label: "Settings",
                      onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => SettingsScreen()));
                      },
                    ),
                    _ActionItem(
                      icon: Icons.history,
                      label: "History",
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => TransactionHistoryScreen()));
                      },
                    ),
                    _ActionItem(
                      icon: Icons.support_agent,
                      label: "Support",
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => HelpCenter()));
                      },
                    ),
                  ],
                ),
              ),

              Center(
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    'Pull up to close',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => GuestHelper.guardAction(context, action: onTap, reason: 'access quick actions'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Icon container
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 28),
          ),

          const SizedBox(height: 8),

          /// Label
          Text(
            label,
            style: const TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
