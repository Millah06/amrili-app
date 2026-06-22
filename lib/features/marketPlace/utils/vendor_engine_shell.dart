// lib/features/marketPlace/utils/vendor_engine_shell.dart
//
// PHASE 3 (fix): the "Store Center" tab is now shown ONLY to users who actually
// have a vendor profile. A regular shopper sees Stores / Orders / Profile; a
// vendor additionally sees Store Center. `myVendor` loads async, so the tab list
// can grow from 3 → 4 once it arrives — we clamp `_index` to stay in range.
//
// Bottom bar design: matches the main app's flat dark BottomAppBar style —
// Color(0xFF0F172A) background, hairline top border, cyan accent on selected.
//
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isVendor = context.watch<VendorCenterProvider>().myVendor != null;

    final tabs = <Widget>[
      VendorsTab(searchParameter: widget.searchParam),
      OrdersTab(),
      if (isVendor) VendorCenterTab(),
      ProfileTab(),
    ];

    // Keep the selected index valid when the tab count changes (vendor flips on).
    if (_index >= tabs.length) _index = tabs.length - 1;

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1024) {
        return _buildDesktopShell(context, tabs, isVendor);
      }
      return _buildMobileShell(context, tabs, isVendor);
    });
  }

  Scaffold _buildMobileShell(BuildContext context, List<Widget> tabs, bool isVendor) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0F172A),
        elevation: 0,
        height: 62,
        padding: EdgeInsets.zero,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x0FFFFFFF), width: 1)),
          ),
          child: Row(
            children: [
              _VNavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront,
                label: 'Stores',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _VNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Orders',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              if (isVendor)
                _VNavItem(
                  icon: Icons.campaign_outlined,
                  activeIcon: Icons.campaign,
                  label: 'Store Center',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
              _VNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                selected: _index == (isVendor ? 3 : 2),
                onTap: () => setState(() => _index = isVendor ? 3 : 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildDesktopShell(BuildContext context, List<Widget> tabs, bool isVendor) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: Row(
        children: [
          _VendorRail(
            index: _index,
            isVendor: isVendor,
            onIndexChanged: (i) => setState(() => _index = i),
            onBack: () => Navigator.of(context).pop(),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0x1AFFFFFF)),
          Expanded(child: IndexedStack(index: _index, children: tabs)),
        ],
      ),
    );
  }
}

// ── Desktop side rail ────────────────────────────────────────────────────────

class _VendorRail extends StatelessWidget {
  final int index;
  final bool isVendor;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onBack;

  const _VendorRail({
    required this.index,
    required this.isVendor,
    required this.onIndexChanged,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      color: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Divider(
              color: Color(0x1AFFFFFF),
              indent: 14,
              endIndent: 14,
              height: 20,
            ),
            _VRailItem(
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront,
              label: 'Stores',
              selected: index == 0,
              onTap: () => onIndexChanged(0),
            ),
            _VRailItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'Orders',
              selected: index == 1,
              onTap: () => onIndexChanged(1),
            ),
            if (isVendor)
              _VRailItem(
                icon: Icons.campaign_outlined,
                activeIcon: Icons.campaign,
                label: 'Store Center',
                selected: index == 2,
                onTap: () => onIndexChanged(2),
              ),
            _VRailItem(
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: 'Profile',
              selected: index == (isVendor ? 3 : 2),
              onTap: () => onIndexChanged(isVendor ? 3 : 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _VRailItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VRailItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: selected ? 1.0 : 0.88,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 22,
                  color: selected ? const Color(0xFF21D3ED) : Colors.white38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single nav item (mobile bottom bar) ───────────────────────────────────────
// Expanded so items fill the bar equally. AnimatedScale gives the subtle
// selection pulse that matches the main app's _NavItem behavior.
class _VNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Icon(
                  selected ? activeIcon : icon,
                  size: 22,
                  color: selected ? const Color(0xFF21D3ED) : Colors.white38,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
