import 'package:flutter/material.dart';

import '../../../../constraints/vendor_theme.dart';

import '../../models/order_model.dart';
import '../../providers/vendor_center_provider.dart';
import '../../widgets/appeal_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.vendorCenterProvider.api.get('/order/vendor/list') as List;
      setState(() {
        _orders = data.map((o) => OrderModel.fromJson(o)).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() { if (context.mounted) _loading = false;});
    }
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return VendorTheme.warning;
      case OrderStatus.confirmed: return VendorTheme.primary;
      default: return VendorTheme.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
    if (_orders.isEmpty) return const VEmptyState(icon: Icons.receipt_long_outlined, title: 'No incoming orders yet');

    final pending = _orders.where((o) =>
        ['pending', 'confirmed', 'preparing', 'outForDelivery',
          'delivered'].contains(o.status.name)).toList();
    final done    = _orders.where((o) => ['completed', 'cancelled', 'appealed'].contains(o.status.name)).toList();

    return RefreshIndicator(
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            const Text('Incoming / Active', style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...pending.map((o) => VendorOrderCard(order: o, onStatusChanged: _load,
              onAppeal: () {
                _showAppealDialog(context, widget.vendorCenterProvider, o);
              },)),
            const SizedBox(height: 16),
          ],
          if (done.isNotEmpty) ...[
            const Text('Past Orders', style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...done.map((o) => VendorOrderCard(order: o, onStatusChanged: _load)),
          ],
        ],
      ),
    );
  }

  void _showAppealDialog(BuildContext context, VendorCenterProvider vendorCenterProvider, OrderModel order) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) =>  AppealWidget( ctrl: ctrl,
        vendorCenterProvider: vendorCenterProvider, order: order,),
    );
  }
}