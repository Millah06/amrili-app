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
      // ListenableBuilder ensures the footer + appended items repaint on
      // notifyListeners() even though `p` is passed in directly.
      body: ListenableBuilder(
        listenable: p,
        builder: (context, _) {
          if (p.menuItems.isEmpty) {
            return const VEmptyState(
              icon: Icons.restaurant_menu,
              title: 'No menu items yet',
              subtitle: 'Tap + to add your first item',
            );
          }
          return NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
                p.fetchMoreMenu();
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: p.menuItems.length + 1,
              itemBuilder: (_, i) {
                if (i == p.menuItems.length) {
                  if (p.menuLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: VendorTheme.primary),
                        ),
                      ),
                    );
                  }
                  if (!p.menuHasMore) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 24),
                      child: Center(
                        child: Text('You’ve reached the end',
                            style: TextStyle(
                                color: VendorTheme.textMuted, fontSize: 12)),
                      ),
                    );
                  }
                  return const SizedBox(height: 12);
                }
                return ProductManageCard(item: p.menuItems[i], p: p);
              },
            ),
          );
        },
      ),
    );
  }

}