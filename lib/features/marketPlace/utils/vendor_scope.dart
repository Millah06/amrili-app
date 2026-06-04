// lib/features/marketPlace/utils/vendor_scope.dart
//
// PHASE 3 (deep-link hotfix)
//
// The marketplace providers are intentionally NOT mounted at the app root — a
// social-only / guest user shouldn't pay for them. They live in
// `VendorEngineEntry`, which a user passes through when they tap into the
// marketplace tab.
//
// But a DEEP LINK jumps straight to `/store/:id` or `/product/:id` without ever
// going through `VendorEngineEntry`, so the landing page calls
// `context.read<VendorDetailProvider>()` with no provider ancestor →
// ProviderNotFoundException.
//
// `VendorScope` is the single source of truth for that provider set. It wraps
// any subtree (the engine shell, OR a single deep-link landing page) in exactly
// the providers the marketplace expects — including everything `vendorPush`
// re-injects, so navigating deeper from a deep link never crashes.
//
// Lazy creation note: ChangeNotifierProvider.create is lazy, so a deep-link
// store view only instantiates the providers the page actually reads
// (VendorDetailProvider + CartProvider). The auth-only fetches
// (OrderListProvider..fetchOrders, VendorCenterProvider..init) do NOT run unless
// something reads those providers, so a guest deep-linking to a store makes no
// pointless authed calls.
//
import 'package:everywhere/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../providers/vendor_center_provider.dart';
import '../providers/vendor_provider.dart';
import '../../../services/api_service.dart';

class VendorScope extends StatelessWidget {
  final Widget child;
  const VendorScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final api = ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => VendorListProvider(api: api)..fetchVendors()),
        ChangeNotifierProvider(create: (_) => VendorDetailProvider(api: api)),
        ChangeNotifierProvider(create: (_) => CheckoutProvider(api: api)..loadStates()),
        ChangeNotifierProvider(create: (_) => OrderListProvider(api: api)..fetchOrders()),
        ChangeNotifierProvider(create: (_) => OrderChatProvider(api: api)),
        ChangeNotifierProvider(create: (_) => VendorCenterProvider(api: api)..init()),
        ChangeNotifierProvider(create: (_) => LocationProvider(api: api)),
      ],
      child: child,
    );
  }
}