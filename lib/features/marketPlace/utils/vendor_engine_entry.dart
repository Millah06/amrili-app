import 'package:everywhere/features/marketPlace/utils/vendor_engine_shell.dart';
import 'package:everywhere/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../providers/vendor_center_provider.dart';
import '../providers/vendor_provider.dart';
import '../../../services/api_service.dart';

class VendorEngineEntry extends StatelessWidget {

  final String ? searchParam;
  const VendorEngineEntry({super.key, this.searchParam});

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
        ChangeNotifierProvider(create: (_) => LocationProvider(api: api))
      ],

      child: VendorEngineShell(searchParam: searchParam,),
    );
  }
}