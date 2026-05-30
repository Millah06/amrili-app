import 'dart:async';
import 'dart:io';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/widgets/shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../models/order_model.dart';
import '../pages/order_detail_page.dart';
import '../providers/order_provider.dart';
import 'navigation.dart';

class VendorOrderCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onStatusChanged;
  final VoidCallback? onAppeal;

  const VendorOrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
    this.onAppeal,
  });

  @override
  State<VendorOrderCard> createState() => _VendorOrderCardState();
}

class _VendorOrderCardState extends State<VendorOrderCard> {
  bool _busy = false;

  static const _nextStatus = {
    'pending':        'confirmed',
    'confirmed':      'preparing',
    'preparing':      'outForDelivery',
    'outForDelivery': 'delivered',
  };

  static const _nextLabel = {
    'pending':        'Accept Order',
    'confirmed':      'Start Preparing',
    'preparing':      'Out for Delivery',
    'outForDelivery': 'Mark Delivered',
  };

  static const _nextIcon = {
    'pending':        Icons.check_circle_outline,
    'confirmed':      Icons.restaurant_outlined,
    'preparing':      Icons.delivery_dining_outlined,
    'outForDelivery': Icons.done_all_rounded,
  };

  Future<void> _updateStatus(VendorCenterProvider p, String next) async {
    setState(() => _busy = true);
    try {
      await p.api.put('/order/${widget.order.id}/status', {'status': next});
      widget.onStatusChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: VendorTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _markDelivered(VendorCenterProvider p) async {
    // 1. Pick proof image (required)
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    setState(() => _busy = true);
    try {
      // 2. Upload proof + advance status
      final (ok, urls) = await p.markDeliveredWithProof(
        widget.order.id,
        [picked],
      );
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(p.error ?? 'Failed to mark delivered'),
          backgroundColor: VendorTheme.error,
        ));
        return;
      }
      // 3. Send proof as chat image
      if (urls.isNotEmpty) {
        await context.read<OrderChatProvider>().sendImage(
          widget.order.id,
          urls.first,
          caption: '📦 Proof of delivery attached',
        );
      }
      widget.onStatusChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelOrder(VendorCenterProvider p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VendorTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Order',
            style: TextStyle(color: VendorTheme.textPrimary)),
        content: const Text(
            'Cancel this order? The buyer will be refunded.',
            style: TextStyle(color: VendorTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back',
                style: TextStyle(color: VendorTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Order',
                style: TextStyle(
                    color: VendorTheme.error,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
    if (!confirmed) return;
    setState(() => _busy = true);
    try {
      await p.api.put('/order/${widget.order.id}/status', {'status': 'cancelled'});
      widget.onStatusChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: VendorTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmPod(VendorCenterProvider p) async {
    setState(() => _busy = true);
    try {
      await p.api.post('/order/${widget.order.id}/pod-confirm', {});
      widget.onStatusChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: VendorTheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<VendorCenterProvider>();
    final order = widget.order;
    final next = _nextStatus[order.status.name];
    final label = _nextLabel[order.status.name];
    final icon = _nextIcon[order.status.name];
    final isDeliveredStep = order.status.name == 'outForDelivery';
    final isAppealed = order.status == OrderStatus.appealed;
    final isPending = order.status == OrderStatus.pending;
    final isDelivered = order.status == OrderStatus.delivered;
    final isPod = order.isPod;

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
                : isPending
                ? VendorTheme.primary.withOpacity(0.3)
                : VendorTheme.divider,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: VendorTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.id.substring(0, 8).toUpperCase(),
                      style: const TextStyle(
                          color: VendorTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                  if (isPod) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: VendorTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('POD',
                          style: TextStyle(
                              color: VendorTheme.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                  const Spacer(),
                  _StatusChip(status: order.status),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Address
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: VendorTheme.textMuted, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(order.deliveryAddress.full,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: VendorTheme.textMuted, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Items
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

            // Amount + countdown
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 12),
              child: Row(
                children: [
                  Text('₦${kFormatter.format(order.totalAmount)}',
                      style: const TextStyle(
                          color: VendorTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const Spacer(),
                  if (isPending)
                    _CountdownChip(deadline: order.autoCancelAt),
                ],
              ),
            ),

            // Appeal frozen banner
            if (isAppealed) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: VendorTheme.warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: VendorTheme.warning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.gavel_rounded,
                          color: VendorTheme.warning, size: 12),
                      SizedBox(width: 6),
                      Text('Under dispute — admin reviewing',
                          style: TextStyle(
                              color: VendorTheme.warning, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],

            // Action buttons
            if (!isAppealed && (next != null || isPending || isDelivered)) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                height: 1,
                color: VendorTheme.divider,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: _busy
                    ? const Center(
                  child: SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(
                        color: VendorTheme.primary, strokeWidth: 2.5),
                  ),
                )
                    : _buildActions(p, next, label, icon, isDeliveredStep,
                    isPending, isDelivered, isPod),
              ),
            ],

            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(
      VendorCenterProvider p,
      String? next,
      String? label,
      IconData? icon,
      bool isDeliveredStep,
      bool isPending,
      bool isDelivered,
      bool isPod,
      ) {
    return Row(
      children: [
        // Cancel (pending only)
        if (isPending) ...[
          Expanded(
            child: _CardBtn(
              label: 'Cancel',
              icon: Icons.close_rounded,
              color: VendorTheme.error,
              outlined: true,
              onTap: () => _cancelOrder(p),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // POD: confirm cash received (delivered + pod + not yet confirmed)
        if (isPod && isDelivered && !widget.order.podConfirmed) ...[
          Expanded(
            child: _CardBtn(
              label: 'Confirm Cash',
              icon: Icons.payments_outlined,
              color: VendorTheme.accent,
              onTap: () => _confirmPod(p),
            ),
          ),
        ],

        // Main progress button (except outForDelivery → delivered which is special)
        if (next != null && label != null && !isDeliveredStep)
          Expanded(
            child: _CardBtn(
              label: label,
              icon: icon!,
              color: VendorTheme.primary,
              onTap: () => _updateStatus(p, next),
            ),
          ),

        // outForDelivery → delivered: requires proof upload
        if (isDeliveredStep)
          Expanded(
            child: _CardBtn(
              label: 'Mark Delivered',
              icon: Icons.add_a_photo_outlined,
              color: VendorTheme.primary,
              onTap: () => _markDelivered(p),
            ),
          ),

        // Appeal (non-POD only, canAppeal statuses)
        if (!isPod && widget.order.status.canAppealForVendor && widget.onAppeal != null) ...[
          const SizedBox(width: 8),
          _CardBtn(
            label: 'Appeal',
            icon: Icons.gavel_rounded,
            color: VendorTheme.error,
            outlined: true,
            onTap: widget.onAppeal!,
            compact: true,
          ),
        ],
      ],
    );
  }
}

// ─── Reusable card button ─────────────────────────────────────────────────────

class _CardBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;
  final bool compact;

  const _CardBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: 9, horizontal: compact ? 10 : 0),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
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

// ─── Status chip (same as user side) ─────────────────────────────────────────

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
      child: Text(status.label,
          style: TextStyle(
              color: _color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

// ─── Countdown chip (reused from user side) ───────────────────────────────────

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
  void dispose() { _timer.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_remaining == Duration.zero) {
      return const Text('Expiring…',
          style: TextStyle(color: VendorTheme.error, fontSize: 10));
    }
    final m = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final urgent = _remaining.inMinutes < 5;
    final color = urgent ? VendorTheme.error : VendorTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 11),
          const SizedBox(width: 4),
          Text('$m:$s',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}