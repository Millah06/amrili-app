import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../models/order_model.dart';
import '../../providers/vendor_center_provider.dart';
import '../../widgets/appeal_widget.dart';
import '../../widgets/navigation.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/vendor_order_card.dart';

class StoreOrdersTab extends StatefulWidget {
  final VendorCenterProvider vendorCenterProvider;
  const StoreOrdersTab({super.key, required this.vendorCenterProvider});

  @override
  State<StoreOrdersTab> createState() => StoreOrdersTabState();
}

class StoreOrdersTabState extends State<StoreOrdersTab> {
  List<OrderModel> _orders = [];
  bool _loading = true;
  String? _error;
  StreamSubscription<DocumentSnapshot>? _pingSub;

  @override
  void initState() {
    super.initState();
    _load();
    _watchRealtime();
  }

  void _watchRealtime() {
    final vendorId = widget.vendorCenterProvider.myVendor?.id;
    if (vendorId == null) return;
    // Vendors are pinged by their branch managerId (which is their userId)
    // We use the vendor ownerId since that's what we write to orderPings
    final ownerId = widget.vendorCenterProvider.myVendor?.ownerId;
    if (ownerId == null) return;
    _pingSub = FirebaseFirestore.instance
        .doc('orderPings/$ownerId')
        .snapshots()
        .skip(1)
        .listen((_) => _load());
  }

  @override
  void dispose() {
    _pingSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.vendorCenterProvider.api.get('/order/vendor/list') as List;
      if (!mounted) return;
      setState(() {
        _orders = data.map((o) => OrderModel.fromJson(o)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  // Active = pending, confirmed, preparing, outForDelivery, delivered, appealed
  List<OrderModel> get _active => _orders.where((o) =>
      ['pending','confirmed','preparing','outForDelivery','delivered','appealed']
          .contains(o.status.name)).toList();

  // Past = completed, cancelled only
  List<OrderModel> get _past => _orders.where((o) =>
      ['completed','cancelled'].contains(o.status.name)).toList();

  @override
  Widget build(BuildContext context) {
    if (_loading && _orders.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
    }
    if (_error != null && _orders.isEmpty) {
      return VErrorState(message: _error!, onRetry: _load);
    }
    if (_orders.isEmpty) {
      return const VEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        subtitle: 'New orders will appear here automatically',
      );
    }

    return RefreshIndicator(
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          if (_active.isNotEmpty) ...[
            _SectionHeader(
              label: 'Active Orders',
              count: _active.length,
              color: VendorTheme.primary,
            ),
            const SizedBox(height: 10),
            ..._active.map((o) => VendorOrderCard(
              order: o,
              onStatusChanged: _load,
              onAppeal: o.status.canAppeal
                  ? () => _showAppeal(context, o)
                  : null,
            )),
            const SizedBox(height: 20),
          ],
          if (_past.isNotEmpty) ...[
            _SectionHeader(
              label: 'Past Orders',
              count: _past.length,
              color: VendorTheme.textMuted,
            ),
            const SizedBox(height: 10),
            ..._past.map((o) => VendorOrderCard(
              order: o,
              onStatusChanged: _load,
            )),
          ],
        ],
      ),
    );
  }

  void _showAppeal(BuildContext context, OrderModel order) {
    vendorPush(
      context,
      AppealWidget(
        vendorCenterProvider: widget.vendorCenterProvider,
        order: order,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionHeader({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}