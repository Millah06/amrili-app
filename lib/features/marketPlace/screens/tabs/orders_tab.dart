
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../components/transacrtion_pin.dart';
import '../../../../services/brain.dart';
import '../../../../shared/utils/flush_bar_message.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../models/order_model.dart';
import '../../pages/order_detail_page.dart';
import '../../providers/order_provider.dart';
import '../../widgets/appeal_widget.dart';
import '../../widgets/navigation.dart';
import '../../widgets/shared_widgets.dart';



class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderListProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Text('My Orders',
                      style: TextStyle(color: VendorTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.read<OrderListProvider>().fetchOrders(),
                    child: const Icon(Icons.refresh, color: VendorTheme.textMuted),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              indicatorColor: VendorTheme.primary,
              indicatorWeight: 2,
              labelColor: VendorTheme.primary,
              unselectedLabelColor: VendorTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
                Tab(text: 'Appealed'),
              ],
            ),
            Expanded(
              child: Consumer<OrderListProvider>(
                builder: (context, p, _) {
                  if (p.loading) return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
                  if (p.error != null) return VErrorState(message: p.error!, onRetry: p.fetchOrders);
                  return TabBarView(
                    controller: _tabs,
                    children: [
                      _OrderList(orders: p.ongoing, emptyTitle: 'No ongoing orders'),
                      _OrderList(orders: p.completed, emptyTitle: 'No completed orders'),
                      _OrderList(orders: p.cancelled, emptyTitle: 'No cancelled orders'),
                      _OrderList(orders: p.appealed, emptyTitle: 'No appealed orders'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyTitle;
  const _OrderList({required this.orders, required this.emptyTitle});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return VEmptyState(icon: Icons.receipt_long_outlined, title: emptyTitle);
    }
    return RefreshIndicator(
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      onRefresh: () => context.read<OrderListProvider>().fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

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

  @override
  Widget build(BuildContext context) {
    final p = context.read<OrderListProvider>();
    return GestureDetector(
      onTap: () => vendorPush(context, OrderDetailPage(order: order,)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.vendorName,
                    style: const TextStyle(color:
                    VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    VStatusBadge(label: order.status.label, color: _statusColor),
                    Icon(Icons.chevron_right, color: VendorTheme.textMuted,),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(order.branchName, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              order.items.map((i) => '${i.quantity}x ${i.name}').join(', '),
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('₦${kFormatter.format(order.totalAmount)}',
                    style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Text('${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                    style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
              ],
            ),
            if (order.status.canConfirm || order.status.canAppeal) ...[
              const SizedBox(height: 10),
              const Divider(color: VendorTheme.divider, height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (order.status.canAppeal)
                    Expanded(
                      child: VSmallButton(
                        label: 'Appeal',
                        color: VendorTheme.error,
                        onTap: () => _showAppealDialog(context, p),
                      ),
                    ),

                  if (order.status.canConfirm && order.status.canAppeal)
                    const SizedBox(width: 8),
                  if (order.status.canConfirm)
                    Expanded(
                      child: VSmallButton(
                        label: 'Release Funds',
                        color: VendorTheme.accent,
                        onTap: () async {
                          showModalBottomSheet(
                              isScrollControlled: true,
                              context: context,
                              isDismissible: false,
                              builder: (_) =>
                                  TransactionPin(
                                      onCompleted: (pin ) async {
                                        if (pin == context.read<Brain>().localPIN) {
                                          final ok = await p.confirmDelivery(order.id);
                                          if (!ok && context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(p.error ?? 'Failed'), backgroundColor: VendorTheme.error),
                                            );
                                          }

                                        }
                                        else {
                                          FlushBarMessage.showFlushBar(
                                            context: context,
                                            message: 'Incorrect PIN!, try again.',
                                            title: 'Ops',
                                            icon: Icon(Icons.error_outline,
                                              color: Colors.white, size: 30,),
                                          );

                                        }
                                      },
                                      onForgotPin: () async {
                                        final Uri uri = Uri.parse('https://wa.me/message/BZ5RBPJYF7PHE1');
                                        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                          throw Exception('Could not launch');
                                        }
                                      },
                                  )
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAppealDialog(BuildContext context, OrderListProvider orderListProvider) {
    final ctrl = TextEditingController();
    vendorPush(
      context,
      AppealWidget(orderListProvider: orderListProvider, order: order, ctrl: ctrl,),
    );
  }

}