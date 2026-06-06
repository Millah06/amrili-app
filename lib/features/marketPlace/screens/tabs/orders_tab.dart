import 'dart:async';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../components/transacrtion_pin.dart';
import '../../../../providers/user_provider.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../models/order_model.dart';
import '../../pages/order_detail_page.dart';
import '../../providers/order_provider.dart';
import '../../widgets/appeal_widget.dart';
import '../../widgets/navigation.dart';
import '../../widgets/shared_widgets.dart';

// ─── OrdersTab ────────────────────────────────────────────────────────────────

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    // Substitute the existing addPostFrameCallback block:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().user?.userId ?? '';
      context.read<OrderListProvider>()
        ..watchRealtime(userId)
        ..fetchOrders();
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Orders',
                          style: TextStyle(
                              color: VendorTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Consumer<OrderListProvider>(
                        builder: (_, p, __) => Text(
                          '${p.orders.length} total orders',
                          style: const TextStyle(
                              color: VendorTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Consumer<OrderListProvider>(
                    builder: (_, p, __) => GestureDetector(
                      onTap: p.loading ? null : p.fetchOrders,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: VendorTheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VendorTheme.divider),
                        ),
                        child: p.loading
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: VendorTheme.primary,
                              strokeWidth: 2),
                        )
                            : const Icon(Icons.refresh_rounded,
                            color: VendorTheme.textMuted, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tabs
            TabBar(
              controller: _tabs,
              indicatorColor: VendorTheme.primary,
              indicatorWeight: 2,
              labelColor: VendorTheme.primary,
              unselectedLabelColor: VendorTheme.textMuted,
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              isScrollable: false,
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
                Tab(text: 'Cancelled'),
                Tab(text: 'Appealed'),
              ],
            ),

            // Content
            Expanded(
              child: Consumer<OrderListProvider>(
                builder: (context, p, _) {
                  if (p.loading && p.orders.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: VendorTheme.primary));
                  }
                  if (p.error != null && p.orders.isEmpty) {
                    return VErrorState(
                        message: p.error!, onRetry: p.fetchOrders);
                  }
                  return TabBarView(
                    controller: _tabs,
                    children: [
                      _OrderList(
                          orders: p.ongoing,
                          emptyTitle: 'No ongoing orders',
                          emptySubtitle: 'Your active orders will appear here'),
                      _OrderList(
                          orders: p.completed,
                          emptyTitle: 'No completed orders',
                          emptySubtitle: 'Completed orders will appear here'),
                      _OrderList(
                          orders: p.cancelled,
                          emptyTitle: 'No cancelled orders'),
                      _OrderList(
                          orders: p.appealed,
                          emptyTitle: 'No appealed orders'),
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

// ─── Order List ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final List<OrderModel> orders;
  final String emptyTitle;
  final String? emptySubtitle;

  const _OrderList(
      {required this.orders,
        required this.emptyTitle,
        this.emptySubtitle});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return VEmptyState(
        icon: Icons.receipt_long_outlined,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return RefreshIndicator(
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      onRefresh: () => context.read<OrderListProvider>().fetchOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderCard(order: orders[i]),
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final p = context.read<OrderListProvider>();
    final isCancelled = order.status == OrderStatus.cancelled;
    final isAppealed = order.status == OrderStatus.appealed;

    return GestureDetector(
      onTap: () => vendorPush(context, OrderDetailPage(order: order)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: VendorTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAppealed
                ? VendorTheme.warning.withOpacity(0.4)
                : isCancelled
                ? VendorTheme.error.withOpacity(0.2)
                : VendorTheme.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  // Vendor avatar placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: VendorTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront,
                        color: VendorTheme.textMuted, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.vendorName,
                            style: const TextStyle(
                                color: VendorTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(order.branchName,
                            style: const TextStyle(
                                color: VendorTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
            ),

            // Step progress (only for non-final, non-cancelled)
            if (!isCancelled && !isAppealed) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _StepBar(status: order.status),
              ),
            ],

            if (isAppealed)
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: VendorTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: VendorTheme.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gavel_rounded,
                          color: VendorTheme.warning, size: 13),
                      SizedBox(width: 6),
                      Text('Dispute under admin review',
                          style: TextStyle(
                              color: VendorTheme.warning, fontSize: 11)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Items & amount
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                order.items.map((i) => '${i.quantity}× ${i.name}').join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: VendorTheme.textSecondary, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
              child: Row(
                children: [
                  Text('₦${kFormatter.format(order.totalAmount)}',
                      style: const TextStyle(
                          color: VendorTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  if (order.isPod)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: VendorTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text('POD',
                          style: TextStyle(
                              color: VendorTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  const Spacer(),
                  // Countdown for pending
                  if (order.status == OrderStatus.pending)
                    _CountdownChip(deadline: order.autoCancelAt),
                  if (order.status != OrderStatus.pending)
                    Text(
                      '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                      style: const TextStyle(
                          color: VendorTheme.textMuted, fontSize: 11),
                    ),
                ],
              ),
            ),

            // Action buttons
            if (!order.isPod && (order.status.canConfirm || order.status.canAppeal)) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                height: 1,
                color: VendorTheme.divider,
              ),
              Padding(
                padding:
                const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    if (order.status.canAppeal)
                      Expanded(
                        child: _ActionButton(
                          label: 'Appeal',
                          icon: Icons.gavel_rounded,
                          color: VendorTheme.error,
                          outlined: true,
                          onTap: () => vendorPush(
                            context,
                            AppealWidget(
                              orderListProvider: p,
                              order: order,
                            ),
                          ),
                        ),
                      ),
                    if (order.status.canConfirm &&
                        order.status.canAppeal)
                      const SizedBox(width: 8),
                    if (order.status.canConfirm)
                      Expanded(
                        child: _ActionButton(
                          label: 'Confirm Delivery',
                          icon: Icons.check_circle_outline,
                          color: VendorTheme.accent,
                          onTap: () =>
                              _showReleasePin(context, p),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  void _showReleasePin(BuildContext context, OrderListProvider p) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      isDismissible: false,
      builder: (_) => TransactionPin(
          onSuccess: () async {
            Navigator.pop(context);
            final ok = await p.confirmDelivery(order.id);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(p.error ?? 'Failed'),
                    backgroundColor: VendorTheme.error),
              );
            }
          }
      ),
    );
  }
}

// ─── Step Bar ─────────────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final OrderStatus status;
  const _StepBar({required this.status});

  static const _labels = ['Placed', 'Accepted', 'Processing', 'On the way', 'Arrived', 'Done'];
  static const _totalSteps = 6;

  @override
  Widget build(BuildContext context) {
    final current = status.stepIndex.clamp(0, _totalSteps - 1);
    return Column(
      children: [
        // Dots + lines
        Row(
          children: List.generate(_totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final stepIdx = (i - 1) ~/ 2;
              final filled = stepIdx < current;
              return Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: filled
                        ? const LinearGradient(
                        colors: [VendorTheme.primary, VendorTheme.primary])
                        : null,
                    color: filled ? null : VendorTheme.surfaceVariant,
                  ),
                ),
              );
            }
            // Dot
            final stepIdx = i ~/ 2;
            final done = stepIdx < current;
            final active = stepIdx == current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 12 : 8,
              height: active ? 12 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? VendorTheme.primary
                    : VendorTheme.surfaceVariant,
                boxShadow: active
                    ? [
                  BoxShadow(
                    color: VendorTheme.primary.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        // Labels (show current and neighbours only to keep it tidy)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_totalSteps, (i) {
            final active = i == current;
            final done = i < current;
            return Expanded(
              child: Text(
                _labels[i],
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active
                      ? VendorTheme.primary
                      : done
                      ? VendorTheme.textMuted
                      : VendorTheme.surfaceVariant,
                  fontSize: 9,
                  fontWeight:
                  active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Status Chip ─────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case OrderStatus.pending:            return VendorTheme.warning;
      case OrderStatus.confirmed:          return VendorTheme.primary;
      case OrderStatus.preparing:          return const Color(0xFFF97316);
      case OrderStatus.outForDelivery:     return VendorTheme.accent;
      case OrderStatus.delivered:          return VendorTheme.accent;
      case OrderStatus.pendingFundRelease: return VendorTheme.accent;
      case OrderStatus.completed:          return VendorTheme.accent;
      case OrderStatus.cancelled:          return VendorTheme.error;
      case OrderStatus.appealed:           return VendorTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            color: _color,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ─── Countdown Chip ───────────────────────────────────────────────────────────

class _CountdownChip extends StatefulWidget {
  final DateTime deadline;
  const _CountdownChip({required this.deadline});

  @override
  State<_CountdownChip> createState() => _CountdownChipState();
}

class _CountdownChipState extends State<_CountdownChip> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calc();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calc());
  }

  void _calc() {
    final r = widget.deadline.difference(DateTime.now());
    if (mounted) setState(() => _remaining = r.isNegative ? Duration.zero : r);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const Text('Expiring…',
          style: TextStyle(
              color: VendorTheme.error, fontSize: 10));
    }
    final m =
    _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s =
    _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final urgent = _remaining.inMinutes < 5;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
        (urgent ? VendorTheme.error : VendorTheme.warning).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (urgent ? VendorTheme.error : VendorTheme.warning)
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined,
              color: urgent ? VendorTheme.error : VendorTheme.warning,
              size: 11),
          const SizedBox(width: 4),
          Text('$m:$s',
              style: TextStyle(
                  color:
                  urgent ? VendorTheme.error : VendorTheme.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Action Button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}