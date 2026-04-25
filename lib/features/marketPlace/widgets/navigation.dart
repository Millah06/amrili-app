

// Use this instead of Navigator.push anywhere inside VendorEngineRoot.
// It re-injects all providers into the new route so they are available
// on every page, no matter how deep the navigation goes.

import 'package:provider/provider.dart';

import '../../../providers/location_provider.dart';
import '../../../features/marketPlace/providers/order_provider.dart';
import '../../../features/marketPlace/providers/vendor_center_provider.dart';
import '../../../features/marketPlace/providers/vendor_provider.dart';
import "package:flutter/material.dart";

Future<T?> vendorPush<T>(BuildContext context, Widget page) {
  // Capture all providers from the current context before pushing
  final cart          = context.read<CartProvider>();
  final vendorList    = context.read<VendorListProvider>();
  final vendorDetail  = context.read<VendorDetailProvider>();
  final checkout      = context.read<CheckoutProvider>();
  final orderList     = context.read<OrderListProvider>();
  final orderChat = context.read<OrderChatProvider>();
  final vendorCenter  = context.read<VendorCenterProvider>();
  final location = context.read<LocationProvider>();

  return Navigator.push<T>(
    context,
    MaterialPageRoute(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: cart),
          ChangeNotifierProvider.value(value: vendorList),
          ChangeNotifierProvider.value(value: vendorDetail),
          ChangeNotifierProvider.value(value: checkout),
          ChangeNotifierProvider.value(value: orderList),
          ChangeNotifierProvider.value(value: orderChat),
          ChangeNotifierProvider.value(value: vendorCenter),
          ChangeNotifierProvider.value(value: location),
        ],
        child: page,
      ),
    ),
  );
}
