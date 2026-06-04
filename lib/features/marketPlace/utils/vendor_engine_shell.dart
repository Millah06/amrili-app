// lib/features/marketPlace/utils/vendor_engine_shell.dart
//
// PHASE 3 (fix): the "Store Center" tab is now shown ONLY to users who actually
// have a vendor profile. A regular shopper sees Stores / Orders / Profile; a
// vendor additionally sees Store Center. `myVendor` loads async, so the tab list
// can grow from 3 → 4 once it arrives — we clamp `_index` to stay in range.
//
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../constraints/vendor_theme.dart';
import '../providers/vendor_center_provider.dart';
import '../screens/tabs/orders_tab.dart';
import '../screens/tabs/profile_tab.dart';
import '../screens/tabs/vendor_center_tab.dart';
import '../screens/tabs/vendors_tab.dart';

class VendorEngineShell extends StatefulWidget {
  final String? searchParam;
  const VendorEngineShell({super.key, this.searchParam});

  @override
  State<VendorEngineShell> createState() => _VendorEngineShellState();
}

class _VendorEngineShellState extends State<VendorEngineShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Is this user a vendor? Drives whether the Store Center tab exists at all.
    final isVendor = context.watch<VendorCenterProvider>().myVendor != null;

    final tabs = <Widget>[
      VendorsTab(searchParameter: widget.searchParam),
      OrdersTab(),
      if (isVendor) VendorCenterTab(),
      ProfileTab(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
          icon: Icon(Icons.storefront_outlined),
          activeIcon: Icon(Icons.storefront),
          label: 'Stores'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Orders'),
      if (isVendor)
        const BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Store Center'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile'),
    ];

    // Keep the selected index valid when the tab count changes (vendor flips on).
    if (_index >= tabs.length) _index = tabs.length - 1;

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: VendorTheme.surface,
          border: Border(top: BorderSide(color: VendorTheme.divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: VendorTheme.primary,
          unselectedItemColor: VendorTheme.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: items,
        ),
      ),
    );
  }
}