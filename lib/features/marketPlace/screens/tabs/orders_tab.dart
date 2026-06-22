import 'dart:async';
import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../components/transaction_pin.dart';
import '../../../../providers/user_provider.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../models/order_model.dart';
import '../../pages/order_detail_page.dart';
import '../../providers/order_provider.dart';
import '../../widgets/appeal_widget.dart';
import '../../widgets/navigation.dart';
import '../../widgets/shared_widgets.dart';
import 'package:everywhere/features/payment/widgets/payment_sheet.dart';

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
    // Tell the provider which bucket is visible so lazy-load + ping target it.
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      context
          .read<OrderListProvider>()
          .setActiveBucket(OrderListProvider.buckets[_tabs.index]);
    });
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
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
                      Text('My Orders',
                          style: kTopAppbars.copyWith(
                              fontFamily:  'DejaVu Sans', fontSize: 23),
                          // style: TextStyle(
                          //     color: VendorTheme.textPrimary,
                          //     fontSize: 22,
                          //     fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Consumer<OrderListProvider>(
                        builder: (_, p, __) => Text(
                          '${p.orders.length} orders',
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
                Tab(text: 'Issues'),
              ],
            ),

            // Content — each tab paginates its own bucket and owns its
            // loading / empty / error / load-more states.
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: const [
                  _OrderList(
                      bucket: 'ongoing',
                      emptyTitle: 'No ongoing orders',
                      emptySubtitle: 'Your active orders will appear here'),
                  _OrderList(
                      bucket: 'completed',
                      emptyTitle: 'No completed orders',
                      emptySubtitle: 'Completed orders will appear here'),
                  _OrderList(
                      bucket: 'cancelled',
                      emptyTitle: 'No cancelled orders'),
                  _OrderList(
                      bucket: 'appealed',
                      emptyTitle: 'No reported orders'),
                ],
              ),
            ),

          ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Order List ───────────────────────────────────────────────────────────────

class _OrderList extends StatelessWidget {
  final String bucket; // 'ongoing' | 'completed' | 'cancelled' | 'appealed'
  final String emptyTitle;
  final String? emptySubtitle;

  const _OrderList({
    required this.bucket,
    required this.emptyTitle,
    this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderListProvider>(
      builder: (context, p, _) {
        final items = p.itemsFor(bucket);

        // First load for this tab → skeletons, not a bare spinner.
        if ((!p.loadedOnceFor(bucket) || p.loadingFor(bucket)) &&
            items.isEmpty) {
          return const _OrderListSkeleton();
        }
        if (p.error != null && items.isEmpty) {
          return VErrorState(
              message: p.error!, onRetry: () => p.refreshBucket(bucket));
        }
        if (items.isEmpty) {
          return VEmptyState(
            icon: Icons.receipt_long_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 720;
            return RefreshIndicator(
              color: VendorTheme.primary,
              backgroundColor: VendorTheme.surface,
              onRefresh: () => p.refreshBucket(bucket),
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                    p.fetchMoreBucket(bucket);
                  }
                  return false;
                },
                child: twoCol
                    ? _OrderGrid(items: items, provider: p, bucket: bucket)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                        itemCount: items.length + 1,
                        itemBuilder: (_, i) {
                          if (i == items.length) {
                            if (p.loadingMoreFor(bucket)) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: VendorTheme.primary),
                                  ),
                                ),
                              );
                            }
                            if (!p.hasMoreFor(bucket)) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 16, bottom: 28),
                                child: Center(
                                  child: Text('You’ve reached the end',
                                      style: TextStyle(
                                          color: VendorTheme.textMuted, fontSize: 12)),
                                ),
                              );
                            }
                            return const SizedBox(height: 12);
                          }
                          return _OrderCard(order: items[i]);
                        },
                      ),
              ),
            );
          },
        );
      },
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
                        if (order.isDineIn)
                          Text(order.displayRef,
                              style: const TextStyle(color: VendorTheme.primary,
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  _StatusChip(status: order.status, label: order.statusLabel),
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
                      Icon(Icons.support_agent_rounded,
                          color: VendorTheme.warning, size: 13),
                      SizedBox(width: 6),
                      Text('Issue under review',
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

            // Unpaid prepaid order — let the buyer complete payment. (POD never
            // needs this; paid orders move to confirmed and lose "pending".)
            if (order.status == OrderStatus.pending && !order.isPod) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Complete payment',
                        icon: Icons.account_balance_wallet_outlined,
                        color: VendorTheme.primary,
                        onTap: () => _payNow(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
                          label: 'Report an issue',
                          icon: Icons.flag_outlined,
                          color: VendorTheme.warning,
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
                          label: 'Confirm Receipt',
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

  // Re-open the universal PaymentSheet for an UNPAID order. entityId = order.id,
  // so on success the backend marketplace_order handler confirms this exact
  // order. On success we refresh so it leaves the "pending" bucket.
  Future<void> _payNow(BuildContext context) async {
    final res = await PaymentSheet.show(
      context,
      amount: order.totalAmount,
      entityType: 'marketplace_order',
      entityId: order.id,
      productName: 'Order from ${order.vendorName}',
    );
    if (res != null && context.mounted) {
      context.read<OrderListProvider>().fetchOrders();
    }
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
  final String? label;
  const _StatusChip({required this.status, this.label});

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
        label ?? status.label,
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

// ─── Loading skeleton ─────────────────────────────────────────────────────────
class _OrderListSkeleton extends StatefulWidget {
  const _OrderListSkeleton();

  @override
  State<_OrderListSkeleton> createState() => _OrderListSkeletonState();
}

class _OrderListSkeletonState extends State<_OrderListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: 5,
      itemBuilder: (_, __) => FadeTransition(
        opacity: Tween(begin: 0.45, end: 0.85).animate(_c),
        child: Container(
          height: 96,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: VendorTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VendorTheme.divider),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: VendorTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(120, 13),
                    const SizedBox(height: 8),
                    _bar(80, 11),
                    const SizedBox(height: 14),
                    _bar(double.infinity, 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: VendorTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ─── 2-column order grid (tablet / desktop) ───────────────────────────────────
// Renders orders in pairs of two, each pair in a Row. Row height adapts to the
// taller of the two cards so variable-height content (step bars, action
// buttons) is never clipped.
class _OrderGrid extends StatelessWidget {
  final List<OrderModel> items;
  final OrderListProvider provider;
  final String bucket;

  const _OrderGrid({
    required this.items,
    required this.provider,
    required this.bucket,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
      itemCount: (items.length / 2).ceil() + 1,
      itemBuilder: (_, rowIdx) {
        // Footer row
        if (rowIdx == (items.length / 2).ceil()) {
          if (provider.loadingMoreFor(bucket)) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: VendorTheme.primary),
                ),
              ),
            );
          }
          if (!provider.hasMoreFor(bucket)) {
            return const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 28),
              child: Center(
                child: Text("You've reached the end",
                    style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              ),
            );
          }
          return const SizedBox(height: 12);
        }

        final left = rowIdx * 2;
        final right = left + 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _OrderCard(order: items[left])),
              const SizedBox(width: 12),
              right < items.length
                  ? Expanded(child: _OrderCard(order: items[right]))
                  : const Expanded(child: SizedBox()),
            ],
          ),
        );
      },
    );
  }
}