// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../constraints/vendor_theme.dart';
// import '../../../models/order_model.dart';
// import '../../../providers/order_provider.dart';
// import '../../../providers/vendor_provider.dart';
// import '../widgets/shared_widgets.dart';
//
// class CheckoutPage extends StatelessWidget {
//   const CheckoutPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: VendorTheme.background,
//       appBar: AppBar(
//         backgroundColor: VendorTheme.background,
//         elevation: 0,
//         title: const Text('Checkout', style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold)),
//         leading: GestureDetector(
//           onTap: () => Navigator.pop(context),
//           child: const Icon(Icons.arrow_back, color: VendorTheme.textPrimary),
//         ),
//       ),
//       body: Consumer2<CheckoutProvider, CartProvider>(
//         builder: (context, checkout, cart, _) {
//           return ListView(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
//             children: [
//               _Section(title: 'Delivery Address', child: _LocationForm(checkout: checkout, cart: cart)),
//               const SizedBox(height: 16),
//               _Section(title: 'Order Summary', child: _OrderSummary(cart: cart, checkout: checkout)),
//               if (checkout.error != null) ...[
//                 const SizedBox(height: 12),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: VendorTheme.error.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(checkout.error!,
//                       style: const TextStyle(color: VendorTheme.error, fontSize: 13)),
//                 ),
//               ],
//             ],
//           );
//         },
//       ),
//       bottomNavigationBar: Consumer2<CheckoutProvider, CartProvider>(
//         builder: (context, checkout, cart, _) {
//           return Container(
//             padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
//             decoration: const BoxDecoration(
//               color: VendorTheme.surface,
//               border: Border(top: BorderSide(color: VendorTheme.divider)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text('Total', style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
//                     Text(
//                       '₦${(cart.subtotal + checkout.deliveryFee).toStringAsFixed(0)}',
//                       style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 VButton(
//                   label: 'Place Order',
//                   loading: checkout.placingOrder,
//                   onTap: checkout.canCheckout && !checkout.placingOrder
//                       ? () => _placeOrder(context, checkout, cart)
//                       : null,
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   void _placeOrder(BuildContext context, CheckoutProvider checkout, CartProvider cart) async {
//     final success = await checkout.placeOrder(
//       vendorId: cart.vendorId!,
//       branchId: cart.branchId!,
//       items: cart.items.toList(),
//     );
//     if (success && context.mounted) {
//       cart.clear();
//       checkout.reset();
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => _OrderPlacedDialog(
//           orderId: checkout.placedOrder!.id,
//           onDone: () {
//             Navigator.of(context).pop(); // dialog
//             Navigator.of(context).pop(); // checkout
//             Navigator.of(context).pop(); // vendor detail
//           },
//         ),
//       );
//     }
//   }
// }
//
// class _LocationForm extends StatelessWidget {
//   final CheckoutProvider checkout;
//   final CartProvider cart;
//
//   const _LocationForm({required this.checkout, required this.cart});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // State
//         VDropdown<LocationState>(
//           label: 'Select State',
//           value: checkout.selectedState,
//           items: checkout.states
//               .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
//               .toList(),
//           onChanged: (s) { if (s != null) checkout.pickState(s); },
//         ),
//         const SizedBox(height: 10),
//         // LGA
//         VDropdown<LocationLga>(
//           label: 'Select LGA',
//           value: checkout.selectedLga,
//           enabled: checkout.selectedState != null,
//           items: checkout.lgas
//               .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
//               .toList(),
//           onChanged: (l) { if (l != null) checkout.pickLga(l); },
//         ),
//         const SizedBox(height: 10),
//         // Area
//         VDropdown<LocationArea>(
//           label: 'Select Area',
//           value: checkout.selectedArea,
//           enabled: checkout.selectedLga != null,
//           items: checkout.areas
//               .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
//               .toList(),
//           onChanged: (a) { if (a != null) checkout.pickArea(a, cart.branchId!); },
//         ),
//         const SizedBox(height: 10),
//         // Street
//         VDropdown<LocationStreet>(
//           label: 'Select Street',
//           value: checkout.selectedStreet,
//           enabled: checkout.selectedArea != null,
//           items: checkout.streets
//               .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
//               .toList(),
//           onChanged: (s) { if (s != null) checkout.pickStreet(s); },
//         ),
//         if (checkout.selectedArea != null && checkout.deliveryFee == 0) ...[
//           const SizedBox(height: 8),
//           const Text(
//             'No delivery zone set up for this area',
//             style: TextStyle(color: VendorTheme.warning, fontSize: 12),
//           ),
//         ],
//       ],
//     );
//   }
// }
//
// class _OrderSummary extends StatelessWidget {
//   final CartProvider cart;
//   final CheckoutProvider checkout;
//
//   const _OrderSummary({required this.cart, required this.checkout});
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ...cart.items.map((item) => Padding(
//           padding: const EdgeInsets.only(bottom: 8),
//           child: Row(
//             children: [
//               Text('${item.quantity}x',
//                   style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(item.menuItem.name,
//                     style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13)),
//               ),
//               Text('₦${item.total.toStringAsFixed(0)}',
//                   style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 13)),
//             ],
//           ),
//         )),
//         const Divider(color: VendorTheme.divider),
//         _row('Subtotal', '₦${cart.subtotal.toStringAsFixed(0)}'),
//         const SizedBox(height: 6),
//         _row(
//           'Delivery fee',
//           checkout.deliveryFee > 0 ? '₦${checkout.deliveryFee.toStringAsFixed(0)}' : '—',
//           valueColor: checkout.deliveryFee > 0 ? VendorTheme.textSecondary : VendorTheme.textMuted,
//         ),
//         const SizedBox(height: 6),
//         _row('Transaction fee', '₦0', valueColor: VendorTheme.accent),
//       ],
//     );
//   }
//
//   Widget _row(String label, String value, {Color valueColor = VendorTheme.textSecondary}) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(label, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
//         Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
// }
//
// class _Section extends StatelessWidget {
//   final String title;
//   final Widget child;
//
//   const _Section({required this.title, required this.child});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: VendorTheme.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: VendorTheme.divider),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
//           const SizedBox(height: 14),
//           child,
//         ],
//       ),
//     );
//   }
// }
//
// class _OrderPlacedDialog extends StatelessWidget {
//   final String orderId;
//   final VoidCallback onDone;
//
//   const _OrderPlacedDialog({required this.orderId, required this.onDone});
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: VendorTheme.surface,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(28),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 64, height: 64,
//               decoration: BoxDecoration(
//                 color: VendorTheme.accent.withOpacity(0.15),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.check_circle, color: VendorTheme.accent, size: 36),
//             ),
//             const SizedBox(height: 16),
//             const Text('Order Placed!',
//                 style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
//             const SizedBox(height: 8),
//             const Text(
//               'Your order has been placed and payment is held in escrow. We will notify you of any updates.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: VendorTheme.textSecondary, fontSize: 13),
//             ),
//             const SizedBox(height: 20),
//             VButton(label: 'View My Orders', onTap: onDone),
//           ],
//         ),
//       ),
//     );
//   }
// }