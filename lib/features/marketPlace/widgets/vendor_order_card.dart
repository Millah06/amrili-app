import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../models/order_model.dart';
import '../pages/order_detail_page.dart';
import 'navigation.dart';
import 'package:provider/provider.dart';

class VendorOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onStatusChanged;
  final Function() ? onAppeal;

  const VendorOrderCard({super.key, required this.order, required this.onStatusChanged, this.onAppeal});

  static const _nextStatus = {
    'pending':        'confirmed',
    'confirmed':      'preparing',
    'preparing':      'outForDelivery',
    'outForDelivery': 'delivered',
    'delivered': 'pendingFundRelease'
  };

  static const _nextLabel = {
    'pending':        'Accept Order',
    'confirmed':      'Start Preparing',
    'preparing':      'Mark Out for Delivery',
    'outForDelivery': 'Mark Delivered',
    'delivered' : 'Pending Release'
  };

  @override
  Widget build(BuildContext context) {
    final p = context.read<VendorCenterProvider>();
    final next = _nextStatus[order.status.name];
    final label = _nextLabel[order.status.name];
    print(order.status.name);

    return GestureDetector(
      onTap: () {vendorPush(context, OrderDetailPage(order: order));},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendorTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('ID: ${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                VStatusBadge(label: order.status.label, color: _color(order.status)),
              ],
            ),
            const SizedBox(height: 6),
            Text(order.deliveryAddress.full,
                style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(order.items.map((i) => '${i.quantity} x ${i.name}').join(', '),
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('₦${kFormatter.format(order.totalAmount)}',
                    style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                if (next != null && label != null)
                  VSmallButton(
                    label: label,
                    color: label == 'Pending Release' ? Colors.transparent :VendorTheme.primary,
                    textColor: label == 'Pending Release' ? Colors.amberAccent :Colors.white,
                    onTap: () async {
                      await p.api.put('/order/${order.id}/status', {'status': next});
                      onStatusChanged();
                    },
                  ),
                if (order.status.name == 'pending') ...[
                  const SizedBox(width: 8),
                  VSmallButton(
                    label: 'Cancel',
                    color: VendorTheme.error.withOpacity(0.15),
                    textColor: VendorTheme.error,
                    onTap: () async {
                      await p.api.put('/order/${order.id}/status', {'status': 'cancelled'});
                      onStatusChanged();
                    },
                  ),
                ],
                if (order.paymentMethod == 'pay_on_delivery'
                    && order.status.name == 'delivered' && !order.podConfirmed)
                  VSmallButton(
                    label: 'Confirm Cash Received',
                    color: VendorTheme.accent,
                    textColor: Colors.white,
                    onTap: () async {
                      await p.api.post('/order/${order.id}/pod-confirm', {});
                      onStatusChanged();
                    },
                  ),
                if (order.status.name == 'delivered') ...[
                  const SizedBox(width: 8),
                  VSmallButton(
                    label: 'Appeal',
                    color: VendorTheme.error.withOpacity(0.15),
                    textColor: VendorTheme.error,
                    onTap: () {
                      onAppeal!();
                    },
                  ),
                ],


              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _color(OrderStatus s) {
    switch (s) {
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
}