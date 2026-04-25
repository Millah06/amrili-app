import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/widgets/navigation.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../models/order_model.dart';
import '../widgets/shared_widgets.dart';
import 'order_chat_page.dart';

class OrderDetailPage extends StatefulWidget {
  final OrderModel order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: Text('Order Detail Page',
            style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: _DetailsTab(order: widget.order, userId: pov.user!.userId),
    );
  }
}

// ─── Details Tab ──────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final OrderModel order;
  final String userId;
  const _DetailsTab({required this.order, required this.userId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status
        _card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Contact', style: TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
              VSmallButton(
                label: 'Contact ${order.userId == userId ? 'Seller' : 'Buyer'}',
                color: VendorTheme.primary,
                textColor: Colors.black,
                onTap: () {
                vendorPush(context, ChatTab(order: order, userId: userId,));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Status
        _card(
          child: Row(
            children: [
              const Text('Status', style: TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
              const Spacer(),
              VStatusBadge(label: order.status.label, color: _statusColor),
            ],
          ),
        ),
        if (order.status.canAppeal)
          _card(child: Row(
            children: [
              const Text('Action', style: TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
              const Spacer(),
              VSmallButton(label: 'Cancel Appeal', color: _statusColor, onTap: () {

              },),
            ],
          ),),
        const SizedBox(height: 12),
        // Vendor
        order.userId == userId ? _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Vendor', style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(order.vendorName,
                  style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(order.branchName, style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ) :  _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Buyer', style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text('User_${order.userId.substring(5, 10)}',
                  style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(order.branchName, style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // Items
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Items', style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VendorTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('${item.quantity}x',
                          style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.name,
                          style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13)),
                    ),
                    Text('₦${kFormatter.format(item.total)}',
                        style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              )),
              const Divider(color: VendorTheme.divider),
              _row('Subtotal', '₦${kFormatter.format(order.subtotal)}'),
              const SizedBox(height: 4),
              _row('Delivery fee', '₦${kFormatter.format(order.deliveryFee)}'),
              const SizedBox(height: 4),
              _row('Transaction fee', '₦${kFormatter.format(order.transactionFee)}'),
              const Divider(color: VendorTheme.divider),
              _row('Total', '₦${kFormatter.format(order.totalAmount)}',
                  bold: true, valueColor: VendorTheme.primary),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Delivery address
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Delivery Address', style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Text(order.deliveryAddress.full,
                  style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        //Order Id
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order ID', style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.id.substring(0, 8).toUpperCase(),
                      style: const TextStyle(color: VendorTheme.textPrimary,
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: order.id.substring(0, 8).toUpperCase()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Order Id Copied'),
                            backgroundColor: VendorTheme.accent),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VendorTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.copy, color: VendorTheme.primary, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // Escrow
        _card(
          child: Row(
            children: [
              const Icon(Icons.lock_outline, color: VendorTheme.warning, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Escrow',
                        style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
                    Text(
                      order.escrowStatus == 'held'
                          ? 'Payment is held in escrow'
                          : order.escrowStatus == 'released'
                          ? 'Payment released to vendor'
                          : order.escrowStatus == 'appealed'
                          ? 'Escrow frozen — appeal in progress'
                          : 'Refunded to you',
                      style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:        return VendorTheme.warning;
      case OrderStatus.confirmed:      return VendorTheme.primary;
      case OrderStatus.preparing:      return const Color(0xFFF97316);
      case OrderStatus.outForDelivery: return VendorTheme.accent;
      case OrderStatus.delivered:      return VendorTheme.accent;
      case OrderStatus.completed:      return VendorTheme.accent;
      case OrderStatus.cancelled:      return VendorTheme.error;
      case OrderStatus.appealed:       return VendorTheme.warning;
      case OrderStatus.pendingFundRelease: return VendorTheme.accent;

    }
  }

  Widget _card({required Widget child}) {
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

  Widget _row(String label, String value, {bool bold = false, Color valueColor = VendorTheme.textSecondary}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

