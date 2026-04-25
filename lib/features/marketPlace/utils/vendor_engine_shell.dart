

import 'package:flutter/material.dart';

import '../../../constraints/vendor_theme.dart';
import '../screens/tabs/orders_tab.dart';
import '../screens/tabs/profile_tab.dart';
import '../screens/tabs/vendor_center_tab.dart';
import '../screens/tabs/vendors_tab.dart';

class VendorEngineShell extends StatefulWidget {

  final String ? searchParam;
  const VendorEngineShell({super.key, this.searchParam});

  @override
  State<VendorEngineShell> createState() => _VendorEngineShellState();
}

class _VendorEngineShellState extends State<VendorEngineShell> {

  int _index = 0;



  @override
  Widget build(BuildContext context) {

    final tabs =  [
      VendorsTab(searchParameter: widget.searchParam,),
      OrdersTab(),
      VendorCenterTab(),
      ProfileTab(),
    ];

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
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined),  activeIcon: Icon(Icons.storefront),    label: 'Stores'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long),  label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined),     activeIcon: Icon(Icons.campaign),      label: 'Store Center'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline),        activeIcon: Icon(Icons.person),        label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN.DART INTEGRATION
// ─────────────────────────────────────────────────────────────────────────────
// Your main.dart does NOT need any changes for the Vendor Engine providers.
// All providers are scoped inside VendorEngineRoot above using MultiProvider.
// They are created when the user enters the Vendor Engine and disposed when
// they leave — they do not pollute your global app state.
//
// The only thing your main.dart needs (which you likely already have):
//
//   void main() async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await Firebase.initializeApp();   // already done
//     runApp(const MyApp());
//   }
//
// That is all. Navigate to VendorEngineRoot from anywhere in your app.
// ─────────────────────────────────────────────────────────────────────────────
