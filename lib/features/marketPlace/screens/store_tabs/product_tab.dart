import 'package:flutter/material.dart';

import '../../../../constraints/vendor_theme.dart';

import '../../pages/add_product_item_page.dart';
import '../../providers/vendor_center_provider.dart';
import '../../widgets/navigation.dart';
import '../../widgets/product_manage_card.dart';
import '../../widgets/shared_widgets.dart';



class ProductTab extends StatelessWidget {
  final VendorCenterProvider p;
  const ProductTab({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: VendorTheme.primary,
        onPressed: () => vendorPush(context, AddMenuItemPage()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: p.menuItems.isEmpty
          ? const VEmptyState(
        icon: Icons.restaurant_menu,
        title: 'No menu items yet',
        subtitle: 'Tap + to add your first item',
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: p.menuItems.length,
        itemBuilder: (_, i) => ProductManageCard(item: p.menuItems[i], p: p),
      ),
    );
  }

}