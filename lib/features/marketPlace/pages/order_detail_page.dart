import 'dart:async';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/widgets/navigation.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../components/transacrtion_pin.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../services/brain.dart';
import '../../../shared/utils/flush_bar_message.dart';
import '../models/order_model.dart';
import '../pages/order_chat_page.dart';
import '../providers/order_provider.dart';
import '../providers/vendor_center_provider.dart';
import '../widgets/appeal_widget.dart';
import '../widgets/review_bottom_sheet.dart';
import '../widgets/shared_widgets.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _hasReviewed = false;
  bool _reviewChecked = false;
  bool _reviewShownThisSession = false;
  late OrderModel _order;

  bool get _isUser => _order.userId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order.status == OrderStatus.completed) _checkReview();
  }

  Future<void> _checkReview() async {
    final reviewed = await context
        .read<VendorCenterProvider>()
        .checkHasReviewed(_order.vendorId);
    if (!mounted) return;
    setState(() {
      _hasReviewed = reviewed;
      _reviewChecked = true;
    });
    // Auto-pop the review sheet once per session
    if (!reviewed && !_reviewShownThisSession && _isUser) {
      _reviewShownThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showReview());
    }
  }

  void _showReview() {
    final user = context.read<UserProvider>().user;
    ReviewBottomSheet.show(
      context,
      vendorId: _order.vendorId,
      vendorName: _order.vendorName,
      userName: user?.name ?? 'Customer',
      orderId : _order.id,
      onSubmitted: () => setState(() => _hasReviewed = true),
      vendorCenterProvider: context
          .read<VendorCenterProvider>(),
    );
  }

  String get _currentUserId =>
      context.read<UserProvider>().user?.userId ?? '';



  /// The current user filed the appeal.
  bool get _iAmAppellant =>
      _order.appealedBy != null && _order.appealedBy == _currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Detail',
                style: TextStyle(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            Text(
              _order.id.substring(0, 8).toUpperCase(),
              style: const TextStyle(
                  color: VendorTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => vendorPush(
                context, ChatTab(order: _order, userId: _currentUserId)),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VendorTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: VendorTheme.primary.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      color: VendorTheme.primary, size: 14),
                  SizedBox(width: 5),
                  Text('Chat',
                      style: TextStyle(
                          color: VendorTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Step bar (only for non-final orders)
          if (!_order.status.isFinal &&
              _order.status != OrderStatus.appealed)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: _DetailStepBar(status: _order.status),
            ),

          // Appealed banner
          if (_order.status == OrderStatus.appealed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VendorTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: VendorTheme.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.gavel_rounded,
                      color: VendorTheme.warning, size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dispute in Progress',
                            style: TextStyle(
                                color: VendorTheme.warning,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                        SizedBox(height: 2),
                        Text(
                            'Payment is paused while an admin reviews this dispute.',
                            style: TextStyle(
                                color: VendorTheme.warning,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Pending countdown
          if (_order.status == OrderStatus.pending)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PendingBanner(deadline: _order.autoCancelAt),
            ),

          // Main scroll content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                // Counterparty card
                _InfoCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: VendorTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isUser
                              ? Icons.storefront
                              : Icons.person_outline,
                          color: VendorTheme.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isUser ? 'Vendor' : 'Buyer',
                              style: const TextStyle(
                                  color: VendorTheme.textMuted,
                                  fontSize: 11),
                            ),
                            Text(
                              _isUser
                                  ? _order.vendorName
                                  : 'User ${_order.userName}',
                              style: const TextStyle(
                                  color: VendorTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            Text(
                              _order.branchName,
                              style: const TextStyle(
                                  color: VendorTheme.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Items card
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Items',
                          style: TextStyle(
                              color: VendorTheme.textMuted,
                              fontSize: 12)),
                      const SizedBox(height: 10),
                      ..._order.items.map((item) => Padding(
                        padding:
                        const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2),
                              decoration: BoxDecoration(
                                color: VendorTheme.surfaceVariant,
                                borderRadius:
                                BorderRadius.circular(6),
                              ),
                              child: Text('${item.quantity}×',
                                  style: const TextStyle(
                                      color:
                                      VendorTheme.textMuted,
                                      fontSize: 11)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(item.name,
                                    style: const TextStyle(
                                        color: VendorTheme
                                            .textPrimary,
                                        fontSize: 13))),
                            Text(
                                '₦${kFormatter.format(item.total)}',
                                style: const TextStyle(
                                    color:
                                    VendorTheme.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      )),
                      const Divider(
                          color: VendorTheme.surfaceVariant,
                          height: 16),
                      _PriceRow('Subtotal',
                          '₦${kFormatter.format(_order.subtotal)}'),
                      const SizedBox(height: 4),
                      _PriceRow('Delivery fee',
                          '₦${kFormatter.format(_order.deliveryFee)}'),
                      const SizedBox(height: 4),
                      _PriceRow('Transaction fee',
                          '₦${kFormatter.format(_order.transactionFee)}'),
                      const Divider(
                          color: VendorTheme.surfaceVariant,
                          height: 16),
                      _PriceRow(
                          'Total',
                          '₦${kFormatter.format(_order.totalAmount)}',
                          bold: true,
                          valueColor: VendorTheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Delivery address
                _InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address',
                          style: TextStyle(
                              color: VendorTheme.textMuted,
                              fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: VendorTheme.primary, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(
                                  _order.deliveryAddress.full,
                                  style: const TextStyle(
                                      color: VendorTheme.textPrimary,
                                      fontSize: 13))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Order ID
                _InfoCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order ID',
                                style: TextStyle(
                                    color: VendorTheme.textMuted,
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                _order.id
                                    .substring(0, 8)
                                    .toUpperCase(),
                                style: const TextStyle(
                                    color: VendorTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(
                              text: _order.id
                                  .substring(0, 8)
                                  .toUpperCase()));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text('Order ID copied'),
                            backgroundColor: VendorTheme.accent,
                            duration: Duration(seconds: 1),
                          ));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                            VendorTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.copy,
                              color: VendorTheme.primary, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Payment protection / settlement (hidden for POD)
                if (!_order.isPod)
                  _InfoCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: VendorTheme.warning.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined,
                              color: VendorTheme.warning, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_isUser ? 'Buyer protection' : 'Settlement',
                                      style: const TextStyle(
                                          color: VendorTheme.textMuted,
                                          fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _escrowColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _payLabel(),
                                      style: TextStyle(
                                          color: _escrowColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _escrowMessage(_isUser),
                                style: const TextStyle(
                                    color: VendorTheme.textPrimary,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),

                // Rate vendor button (completed, not yet reviewed)
                if (_order.status == OrderStatus.completed &&
                    _reviewChecked &&
                    !_hasReviewed && _isUser) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showReview,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            VendorTheme.gold.withOpacity(0.15),
                            VendorTheme.warning.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: VendorTheme.gold.withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: VendorTheme.gold, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text('Rate your experience',
                                    style: TextStyle(
                                        color: VendorTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                                Text('Tell us how the order went',
                                    style: TextStyle(
                                        color: VendorTheme.textMuted,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: VendorTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Floating action panel
          _ActionPanel(
            order: _order,
            isUser: _isUser,
            iAmAppellant: _iAmAppellant,
            userId: _currentUserId,
          ),
        ],
      ),
    );
  }

  /// Short uppercase pill label for the payment state (buyer- vs merchant-aware).
  String _payLabel() {
    switch (_order.escrowStatus) {
      case 'held':      return _isUser ? 'PROTECTED' : 'CLEARING';
      case 'released':  return 'SETTLED';
      case 'appealed':  return 'PAUSED';
      case 'refunded':  return 'REFUNDED';
      case 'cancelled': return 'CANCELLED';
      default:          return _order.escrowStatus.toUpperCase();
    }
  }

  String _escrowMessage(bool isUser) {
    switch (_order.escrowStatus) {
      case 'held':     return isUser ? 'Protected until you confirm delivery' : 'Clearing — settles to your balance soon';
      case 'released': return isUser ? 'Payment released to the seller' : 'Settled to your balance';
      case 'appealed': return 'Payout paused — dispute under review';
      case 'refunded': return isUser ? 'Refunded to your wallet' : "Refunded to the buyer's wallet";


      case 'cancelled': return isUser ? 'Order automatically cancelled by the system,'
          ' due to no response from vendor' : 'Order automatically cancelled by the System,'
          ' due to no response from you';
      default:        return _order.escrowStatus;
    }
  }

  Color get _escrowColor {
    switch (_order.escrowStatus) {
      case 'held':    return VendorTheme.warning;
      case 'released': return VendorTheme.accent;
      case 'appealed': return VendorTheme.error;
      case 'refunded': return VendorTheme.primary;
      case 'cancelled': return VendorTheme.textMuted;
      default:        return VendorTheme.textMuted;
    }
  }

}

// ─── Floating Action Panel ────────────────────────────────────────────────────

// FULL REPLACEMENT of _ActionPanel class in order_detail_page.dart

class _ActionPanel extends StatefulWidget {
  final OrderModel order;
  final bool isUser;
  final bool iAmAppellant;
  final String userId;

  const _ActionPanel({
    required this.order,
    required this.isUser,
    required this.iAmAppellant,
    required this.userId,
  });

  @override
  State<_ActionPanel> createState() => _ActionPanelState();
}

class _ActionPanelState extends State<_ActionPanel> {
  bool _busy = false;

  OrderModel get order => widget.order;
  bool get isUser => widget.isUser;
  bool get iAmAppellant => widget.iAmAppellant;
  String get userId => widget.userId;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<OrderListProvider>();
    final vendorProvider = context.read<VendorCenterProvider>();
    final List<Widget> actions = [];

    // ── APPEALED state — both sides ──────────────────────────────────────────
    if (order.status == OrderStatus.appealed) {
      if (iAmAppellant) {
        actions.add(_PanelBtn(
          label: 'Cancel My Appeal',
          icon: Icons.undo_rounded,
          color: VendorTheme.warning,
          outlined: true,
          onTap: () => _run(() => _cancelAppeal(context, userProvider)),
        ));
      } else {
        actions.add(_PanelBtn(
          label: 'Concede Appeal',
          icon: Icons.handshake_outlined,
          color: VendorTheme.accent,
          onTap: () => _run(() => _concedeAppeal(context, userProvider)),
        ));
      }
    }

    // ── BUYER actions ────────────────────────────────────────────────────────
    if (isUser && order.status != OrderStatus.appealed) {
      if (!order.isPod) {
        if (order.status.canAppeal) {
          actions.add(_PanelBtn(
            label: 'Raise Appeal',
            icon: Icons.gavel_rounded,
            color: VendorTheme.error,
            outlined: true,
            onTap: () => vendorPush(context,
                AppealWidget(orderListProvider: userProvider, order: order)),
          ));
        }
        if (order.status.canConfirm) {
          actions.add(_PanelBtn(
            label: 'Confirm Delivery',
            icon: Icons.check_circle_outline,
            color: VendorTheme.accent,
            onTap: () => _showReleasePin(context, userProvider),
          ));
        }
      }
      // POD delivered — no settlement, just open chat
      if (order.isPod && order.status == OrderStatus.delivered) {
        actions.add(_PanelBtn(
          label: 'Contact Vendor',
          icon: Icons.chat_bubble_outline,
          color: VendorTheme.primary,
          onTap: () =>
              vendorPush(context, ChatTab(order: order, userId: userId)),
        ));
      }
    }

    // ── VENDOR actions ───────────────────────────────────────────────────────
    if (!isUser && order.status != OrderStatus.appealed) {
      const nextMap = {
        'pending':   'confirmed',
        'confirmed': 'preparing',
        'preparing': 'outForDelivery',
      };
      const labelMap = {
        'pending':   'Accept Order',
        'confirmed': 'Start Processing',
        'preparing': 'Out for Delivery',
      };
      const iconMap = {
        'pending':   Icons.check_circle_outline,
        'confirmed': Icons.inventory_2_outlined,
        'preparing': Icons.delivery_dining_outlined,
      };

      final next = nextMap[order.status.name];

      // Cancel (pending only)
      if (order.status.canCancelForVendor) {
        actions.add(_PanelBtn(
          label: 'Cancel',
          icon: Icons.close_rounded,
          color: VendorTheme.error,
          outlined: true,
          onTap: () => _run(() => _vendorCancel(context, vendorProvider)),
        ));
      }

      // Advance status (pending / confirmed / preparing)
      if (next != null) {
        actions.add(_PanelBtn(
          label: labelMap[order.status.name]!,
          icon: iconMap[order.status.name]!,
          color: VendorTheme.primary,
          onTap: () => _run(() => _vendorAdvance(context, vendorProvider, next)),
        ));
      }



      // outForDelivery → Mark Delivered (proof photo required)
      if (order.status == OrderStatus.outForDelivery) {
        actions.add(_PanelBtn(
          label: 'Mark Delivered',
          icon: Icons.add_a_photo_outlined,
          color: VendorTheme.primary,
          onTap: () => _run(() => _vendorMarkDelivered(context, vendorProvider)),
        ));
      }

      // Non-POD canAppeal statuses — vendor can appeal
      if (!order.isPod && order.status.canAppealForVendor &&
          order.status != OrderStatus.outForDelivery) {

        actions.add(_PanelBtn(
          label: 'Appeal',
          icon: Icons.gavel_rounded,
          color: VendorTheme.error,
          outlined: true,
          onTap: () {
            print(order.status.canAppealForVendor);
            vendorPush(context,
                AppealWidget(vendorCenterProvider: vendorProvider, order: order));
          },
        ));
      }

      // POD: confirm cash received
      if (order.isPod &&
          order.status == OrderStatus.delivered &&
          !order.podConfirmed) {
        actions.add(_PanelBtn(
          label: 'Confirm Cash',
          icon: Icons.payments_outlined,
          color: VendorTheme.accent,
          onTap: () =>
              _run(() => _vendorConfirmPod(context, vendorProvider)),
        ));
      }
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        border: const Border(top: BorderSide(color: VendorTheme.divider)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: _busy
          ? const Center(
        child: SizedBox(
          height: 36,
          width: 36,
          child: CircularProgressIndicator(
              color: VendorTheme.primary, strokeWidth: 2.5),
        ),
      )
          : Row(
        children: actions
            .expand((w) => [w, const SizedBox(width: 10)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  Future<void> _cancelAppeal(
      BuildContext context, OrderListProvider p) async {
    final ok = await _confirm(
        context, 'Cancel your appeal? Your payment stays protected until the order settles.');
    if (!ok) return;
    final success = await p.cancelAppeal(order.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.error ?? 'Failed'),
          backgroundColor: VendorTheme.error));
    }
  }

  Future<void> _concedeAppeal(
      BuildContext context, OrderListProvider p) async {
    final ok = await _confirm(context,
        'Concede this appeal? Funds will be directed accordingly and cannot be undone.');
    if (!ok) return;
    final success = await p.concedeAppeal(order.id);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.error ?? 'Failed'),
          backgroundColor: VendorTheme.error));
    }
  }

  Future<void> _vendorAdvance(
      BuildContext context, VendorCenterProvider p, String next) async {
    try {
      await p.api.put('/order/${order.id}/status', {'status': next});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: VendorTheme.error));
      }
    }
  }

  Future<void> _vendorMarkDelivered(
      BuildContext context, VendorCenterProvider p) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null || !context.mounted) return;
    final (ok, urls) = await p.markDeliveredWithProof(order.id, [picked]);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.error ?? 'Failed'),
          backgroundColor: VendorTheme.error));
      return;
    }
    if (urls.isNotEmpty) {
      await context.read<OrderChatProvider>().sendImage(
        order.id,
        urls.first,
        caption: '📦 Proof of delivery',
      );
    }
  }

  Future<void> _vendorCancel(
      BuildContext context, VendorCenterProvider p) async {
    final ok =
    await _confirm(context, 'Cancel this order? Buyer will be refunded.');
    if (!ok) return;
    try {
      await p.api.put('/order/${order.id}/status', {'status': 'cancelled'});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: VendorTheme.error));
      }
    }
  }

  Future<void> _vendorConfirmPod(
      BuildContext context, VendorCenterProvider p) async {
    final ok =
    await _confirm(context, 'Confirm you received the cash payment?');
    if (!ok) return;
    try {
      await p.api.post('/order/${order.id}/pod-confirm', {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: VendorTheme.error));
      }
    }
  }

  void _showReleasePin(BuildContext context, OrderListProvider p) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      isDismissible: false,
      builder: (_) => TransactionPin(
          onSuccess: () async {
            final ok = await p.confirmDelivery(order.id);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(p.error ?? 'Failed'),
                  backgroundColor: VendorTheme.error));
            }
          }
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm',
            style: TextStyle(color: VendorTheme.textPrimary)),
        content: Text(message,
            style:
            const TextStyle(color: VendorTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: VendorTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm',
                style: TextStyle(
                    color: VendorTheme.primary,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ??
        false;
  }
}

// ─── Pending Banner ───────────────────────────────────────────────────────────

class _PendingBanner extends StatefulWidget {
  final DateTime deadline;
  const _PendingBanner({required this.deadline});

  @override
  State<_PendingBanner> createState() => _PendingBannerState();
}

class _PendingBannerState extends State<_PendingBanner> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calc();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _calc());
  }

  void _calc() {
    final r = widget.deadline.difference(DateTime.now());
    if (mounted) {
      setState(
              () => _remaining = r.isNegative ? Duration.zero : r);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expired = _remaining == Duration.zero;
    final urgent =
        !expired && _remaining.inMinutes < 5;
    final color =
    expired || urgent ? VendorTheme.error : VendorTheme.warning;
    final m =
    _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
              expired
                  ? Icons.timer_off_outlined
                  : Icons.timer_outlined,
              color: color,
              size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    expired
                        ? 'Auto-cancel triggered'
                        : 'Vendor must accept in',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                if (!expired)
                  Text(
                    '$m:$s remaining',
                    style: TextStyle(
                        color: color.withOpacity(0.8),
                        fontSize: 11),
                  ),
                if (expired)
                  Text(
                      'Your order will be cancelled and funds returned.',
                      style: TextStyle(
                          color: color.withOpacity(0.8),
                          fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Step Bar ──────────────────────────────────────────────────────────

class _DetailStepBar extends StatelessWidget {
  final OrderStatus status;
  const _DetailStepBar({required this.status});

  static const _steps = [
    ('Placed', Icons.receipt_long_outlined),
    ('Accepted', Icons.check_circle_outline),
    ('Processing', Icons.inventory_2_outlined),
    ('On the way', Icons.delivery_dining_outlined),
    ('Arrived', Icons.home_outlined),
    ('Done', Icons.done_all_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final current = status.stepIndex.clamp(0, 5);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Column(
        children: [
          // Dots + connectors
          Row(
            children: List.generate(_steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final filled = (i - 1) ~/ 2 < current;
                return Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: filled
                          ? const LinearGradient(colors: [
                        VendorTheme.primary,
                        VendorTheme.primary,
                      ])
                          : null,
                      color: filled
                          ? null
                          : VendorTheme.surfaceVariant,
                    ),
                  ),
                );
              }
              final idx = i ~/ 2;
              final done = idx < current;
              final active = idx == current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: active ? 28 : 22,
                height: active ? 28 : 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? VendorTheme.primary
                      : active
                      ? VendorTheme.primary.withOpacity(0.2)
                      : VendorTheme.surfaceVariant,
                  border: active
                      ? Border.all(
                      color: VendorTheme.primary, width: 2)
                      : null,
                  boxShadow: active
                      ? [
                    BoxShadow(
                      color:
                      VendorTheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                    )
                  ]
                      : null,
                ),
                child: Icon(
                  done
                      ? Icons.check_rounded
                      : _steps[idx].$2,
                  size: active ? 14 : 12,
                  color: done || active
                      ? (done
                      ? Colors.black
                      : VendorTheme.primary)
                      : VendorTheme.textMuted,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Labels
          Row(
            children: List.generate(_steps.length, (i) {
              final active = i == current;
              final done = i < current;
              return Expanded(
                child: Text(
                  _steps[i].$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? VendorTheme.primary
                        : done
                        ? VendorTheme.textSecondary
                        : VendorTheme.textMuted,
                    fontSize: 9,
                    fontWeight: active
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: child,
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color valueColor;

  const _PriceRow(this.label, this.value,
      {this.bold = false,
        this.valueColor = VendorTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: VendorTheme.textMuted, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight:
                bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _PanelBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _PanelBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}