import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/marketPlace/screens/tabs/orders_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constraints/vendor_theme.dart';

import '../../../core/auth/guest_helper.dart';
import '../../../features/marketPlace/providers/order_provider.dart';
import '../../../features/marketPlace/providers/vendor_provider.dart';
import '../../payment/widgets/payment_sheet.dart';
import '../models/order_model.dart';
import '../providers/table_session_provider.dart';
import '../widgets/navigation.dart';
import '../widgets/shared_widgets.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pov = context.read<CheckoutProvider>();
      final states = pov.states;
      if (states.isEmpty) {
        pov.loadStates();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        backgroundColor: VendorTheme.background,
        elevation: 0,
        title: const Text('Checkout',
            style: TextStyle(
                color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
        ),
      ),
      body: Consumer2<CheckoutProvider, CartProvider>(
        builder: (context, checkout, cart, _) {
          final session = context.watch<TableSessionProvider>();
          print('❤️🔥${session.isDineIn}');
          print('❤️🔥${session.storeId == cart.vendorId}');
          final dineIn = session.isDineIn && session.storeId == cart.vendorId;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            children: [
              dineIn
                  ? _Section(
                title: 'Dine-in',
                child: Row(children: [
                  const Icon(Icons.table_restaurant,
                      color: VendorTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Table ${session.tableNumber ?? ''}',
                      style: const TextStyle(
                          color: VendorTheme.textPrimary,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              )
                  : _Section(
                title: 'Delivery Address',
                child: _DeliveryForm(checkout: checkout, cart: cart),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Order Summary',
                child: _OrderSummary(cart: cart, checkout: checkout,  dineIn: dineIn),
              ),
              if (checkout.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VendorTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(checkout.error!,
                      style: const TextStyle(
                          color: VendorTheme.error, fontSize: 13)),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer2<CheckoutProvider, CartProvider>(
        builder: (context, checkout, cart, _) {
          final session = context.watch<TableSessionProvider>();
          final dineIn = session.isDineIn && session.storeId == cart.vendorId;
          final total = dineIn ? cart.subtotal : cart.subtotal + checkout.deliveryFee;
          return Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: VendorTheme.surface,
              border: Border(top: BorderSide(color: VendorTheme.divider)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            color: VendorTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text('₦${kFormatter.format(total)}',
                        style: const TextStyle(
                            color: VendorTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 12),
                VButton(
                  label: 'Place Order',
                  loading: checkout.placingOrder,
                  onTap: (dineIn || checkout.canCheckout) && !checkout.placingOrder
                      ? () => GuestHelper.guardAction(
                      context, action: () => _placeOrder(context, checkout, cart),
                      reason: 'create post') : null,
                  // onTap: checkout.canCheckout && !checkout.placingOrder
                  //     ? () => _placeOrder(context, checkout, cart)
                  //     : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  void _placeOrder(BuildContext context, CheckoutProvider checkout, CartProvider cart,) async {
    final isPod = checkout.paymentMethod == 'pay_on_delivery';

    final session = context.read<TableSessionProvider>();
    final dineIn = session.isDineIn && session.storeId == cart.vendorId;

    final success = await checkout.placeOrder(
      vendorId: cart.vendorId!,
      branchId: dineIn ? session.branchId! : cart.branchId!,
      items: cart.items.toList(),
      fulfillmentType: dineIn ? 'dine_in' : 'delivery',
      tableId: dineIn ? session.tableId : null,
      isDine: dineIn
    );
    if (!success || !context.mounted) return;

    final order = checkout.placedOrder;            // capture BEFORE reset()
    final amount = order?.totalAmount ?? 0;
    final orderId = order?.id ?? '';
    final vendorName = order?.vendorName ?? 'your order';

    session.clear(); // end the dine-in session on success
    cart.clear();
    checkout.reset();



    // POD: nothing to charge — confirm placement.
    if (isPod) {
      _showPlacedDialog(context, paid: false);
      return;
    }

    // Prepaid: charge now (entityId = order.id → handler confirms this order).
    final result = await PaymentSheet.show(
      context,
      amount: amount,
      entityType: 'marketplace_order',
      entityId: orderId,
      productName: 'Order from $vendorName',
    );
    if (!context.mounted) return;

    if (result != null) {
      _showPlacedDialog(context, paid: true);
    } else {
      // Abandoned/failed — order is saved unpaid; pay later from My Orders.
      Navigator.of(context).pop(); // checkout
      Navigator.of(context).pop(); // vendor detail
      vendorPush(context, OrdersTab());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order saved. You can complete payment from My Orders.'),
        backgroundColor: VendorTheme.warning,
      ));
    }
  }

  void _showPlacedDialog(BuildContext context, {required bool paid}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrderPlacedDialog(
        paid: paid,
        onDone: () {
          Navigator.of(context).pop(); // dialog
          Navigator.of(context).pop(); // checkout
          Navigator.of(context).pop(); // vendor detail
          vendorPush(context, OrdersTab());
        },
      ),
    );
  }

}

// ─── Delivery Form ────────────────────────────────────────────────────────────

class _DeliveryForm extends StatelessWidget {
  final CheckoutProvider checkout;
  final CartProvider cart;

  const _DeliveryForm({required this.checkout, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1 — State
        VDropdown<LocationState>(
          label: checkout.loadingLocation ? 'Loading states...' : 'Select State',
          value: checkout.selectedState,
          enabled: !checkout.loadingLocation && checkout.states.isNotEmpty,
          items: checkout.states
              .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
              .toList(),
          onChanged: (s) {
            if (s != null) checkout.pickState(s);
          },
        ),

        // Step 2 — LGA (shown once state is picked)
        if (checkout.selectedState != null) ...[
          const SizedBox(height: 12),
          VDropdown<LocationLga>(
            label: 'Select Local Government',
            value: checkout.selectedLga,
            enabled: checkout.lgas.isNotEmpty,
            items: checkout.lgas
                .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                .toList(),
            onChanged: (l) {
              if (l != null) checkout.pickLga(l, cart.branchId!);
            },
          ),
        ],

        // Step 3 — Delivery zone cards (shown once LGA is picked)
        if (checkout.selectedLga != null && checkout.selectedState != null) ...[
          const SizedBox(height: 16),
          if (checkout.loadingZones)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: VendorTheme.primary, strokeWidth: 2),
              ),
            )
          else if (checkout.availableZones.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: VendorTheme.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: VendorTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_outlined,
                      color: VendorTheme.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This vendor does not deliver to ${checkout.selectedLga!.name} yet. '
                          'Try a different LGA.',
                      style: const TextStyle(
                          color: VendorTheme.error, fontSize: 12),
                    ),
                  ),
                ],
              ),
            )
          else ...[
              const Text('Select Delivery Zone',
                  style: TextStyle(
                      color: VendorTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...checkout.availableZones.map(
                    (zone) => _ZoneTile(
                  zone: zone,
                  isSelected: checkout.selectedZone?.id == zone.id,
                  onTap: () => checkout.pickZone(zone),
                ),
              ),
            ],
        ],

        // In _DeliveryForm, after zones list:
        if (checkout.selectedZone != null && cart.vendorAllowsPod) ...[
          const SizedBox(height: 16),
          const Text('Payment Method', style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _PaymentMethodSelector(checkout: checkout),
        ],
      ],
    );
  }
}

// ─── Zone Tile ────────────────────────────────────────────────────────────────

class _ZoneTile extends StatelessWidget {
  final DeliveryZoneOption zone;
  final bool isSelected;
  final VoidCallback onTap;

  const _ZoneTile({
    required this.zone,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected
              ? VendorTheme.primary.withOpacity(0.12)
              : VendorTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? VendorTheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? VendorTheme.primary : VendorTheme.textMuted,
                  width: 2,
                ),
                color: isSelected ? VendorTheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(zone.area,
                      style: TextStyle(
                          color: isSelected
                              ? VendorTheme.primary
                              : VendorTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(zone.lga,
                      style: const TextStyle(
                          color: VendorTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Text('₦${kFormatter.format(zone.deliveryFee)}',
                style: TextStyle(
                    color: isSelected ? VendorTheme.primary : VendorTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final CheckoutProvider checkout;
  const _PaymentMethodSelector({required this.checkout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option('prepaid', Icons.account_balance_wallet_outlined, 'Pay Now', 'Wallet or OPay', checkout),
        const SizedBox(width: 10),
        _option('pay_on_delivery', Icons.payments_outlined,
            'Pay on Delivery', 'Cash at doorstep', checkout),
      ],
    );
  }

  Widget _option(String value, IconData icon, String label, String sub, CheckoutProvider checkout) {
    final sel = checkout.paymentMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => checkout.setPaymentMethod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? VendorTheme.primary.withOpacity(0.12) : VendorTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? VendorTheme.primary : Colors.transparent, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: sel ? VendorTheme.primary : VendorTheme.textMuted, size: 20),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(color: sel ? VendorTheme.primary : VendorTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(sub, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Order Summary ────────────────────────────────────────────────────────────

class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  final CheckoutProvider checkout;
  final bool dineIn;

  const _OrderSummary({required this.cart, required this.checkout, this.dineIn = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...cart.items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('${item.quantity}x',
                  style: const TextStyle(
                      color: VendorTheme.textMuted, fontSize: 13)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.menuItem.name,
                    style: const TextStyle(
                        color: VendorTheme.textPrimary, fontSize: 13)),
              ),
              Text('₦${kFormatter.format(item.total)}',
                  style: const TextStyle(
                      color: VendorTheme.textSecondary, fontSize: 13)),
            ],
          ),
        )),
        const Divider(color: VendorTheme.divider),
        _row('Subtotal', '₦${cart.subtotal.toStringAsFixed(0)}'),
        const SizedBox(height: 6),
        _row(
          'Delivery fee',
          dineIn ? '₦0'
              : (checkout.selectedZone != null
              ? '₦${kFormatter.format(checkout.deliveryFee)}'
              : '—'),
          valueColor: dineIn
              ? VendorTheme.accent
              : (checkout.selectedZone != null
              ? VendorTheme.textSecondary
              : VendorTheme.textMuted),
        ),

        const SizedBox(height: 6),
        _row('Transaction fee', '₦0', valueColor: VendorTheme.accent),
        // Selected zone summary
        if (checkout.selectedZone != null) ...[
          const Divider(color: VendorTheme.divider),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: VendorTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                '${checkout.selectedZone!.area}, '
                    '${checkout.selectedZone!.lga}, '
                    '${checkout.selectedZone!.state}',
                style: const TextStyle(
                    color: VendorTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value,
      {Color valueColor = VendorTheme.textSecondary}) {
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
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: VendorTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── Order Placed Dialog ──────────────────────────────────────────────────────

class _OrderPlacedDialog extends StatelessWidget {
  final VoidCallback onDone;
  final bool paid;
  const _OrderPlacedDialog({required this.onDone, this.paid = false});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: VendorTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: VendorTheme.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: VendorTheme.accent, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(
                    color: VendorTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              paid ? 'Payment received and your order is placed. Track it in My Orders.'
                  : 'Your order is placed. Pay cash when it arrives.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            VButton(label: 'View My Orders', onTap: onDone),
          ],
        ),
      ),
    );
  }
}