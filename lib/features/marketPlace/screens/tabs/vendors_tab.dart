import 'package:everywhere/screens/pages/transaction_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../pages/vendor_detail_page.dart';
import '../../providers/vendor_provider.dart';
import '../../widgets/navigation.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/vendor_card.dart';



class VendorsTab extends StatefulWidget {

  final String ? searchParameter;
  const VendorsTab({super.key, this.searchParameter});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final p = context.read<VendorListProvider>();
      p.setVendorType(widget.searchParameter);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: Consumer<VendorListProvider>(
          builder: (context, p, _) {


            return Column(
              children: [
                _buildHeader(p),
                _buildFilterBar(p),
                Expanded(child: _buildBody(p)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(VendorListProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Stores',
              style: TextStyle(color: VendorTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
            onChanged: (S) {
              p.setSearch(S);
            },
            decoration: InputDecoration(
              hintText: 'Search stores...',
              hintStyle: const TextStyle(color: VendorTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: VendorTheme.textMuted, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                onTap: () { _searchCtrl.clear(); p.setSearch(''); },
                child: const Icon(Icons.close, color: VendorTheme.textMuted, size: 18),
              )
                  : null,
              filled: true,
              fillColor: VendorTheme.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(VendorListProvider p) {
    const types = <String?>[null, 'restaurant', 'grocery', 'drinks', 'retail'];
    const labels = ['All', 'Restaurant', 'Grocery', 'Drinks', 'Retail'];
    const sorts = ['rating', 'completionRate', 'totalCompletedOrders'];
    const sortLabels = ['Top Rated', 'Reliable', 'Popular'];

    String rowSelected = p.selectedVendorType ?? 'All';
    String selected = rowSelected[0].toUpperCase() + rowSelected.substring(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilterBar(
          selected: selected,
          filters: labels,
          onSelect: (String value) {
            p.setVendorType(value == 'All' ? null : value.toLowerCase());
          },
        ),
        // SizedBox(
        //   height: 38,
        //   child: ListView.separated(
        //     scrollDirection: Axis.horizontal,
        //     padding: const EdgeInsets.symmetric(horizontal: 16),
        //     itemCount: types.length,
        //     separatorBuilder: (_, __) => const SizedBox(width: 8),
        //     itemBuilder: (_, i) {
        //       final sel = p.selectedVendorType == types[i];
        //       return GestureDetector(
        //         onTap: () => p.setVendorType(types[i]),
        //         child: AnimatedContainer(
        //           duration: const Duration(milliseconds: 150),
        //           padding: const EdgeInsets.symmetric(horizontal: 14),
        //           alignment: Alignment.center,
        //           decoration: BoxDecoration(
        //             color: sel ? VendorTheme.primary : VendorTheme.surface,
        //             borderRadius: BorderRadius.circular(20),
        //             border: Border.all(color: sel ? VendorTheme.primary : VendorTheme.divider),
        //           ),
        //           child: Text(labels[i],
        //               style: TextStyle(
        //                   color: sel ? VendorTheme.background : VendorTheme.textSecondary,
        //                   fontSize: 13, fontWeight: FontWeight.w500)),
        //         ),
        //       );
        //     },
        //   ),
        // ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Sort:', style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(width: 8),
              ...List.generate(sorts.length, (i) {
                final sel = p.sortBy == sorts[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => p.setSortBy(sorts[i]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: sel ? VendorTheme.primary.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: sel ? VendorTheme.primary : VendorTheme.divider),
                      ),
                      child: Text(sortLabels[i],
                          style: TextStyle(
                              color: sel ? VendorTheme.primary : VendorTheme.textMuted,
                              fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBody(VendorListProvider p) {
    if (p.loading) return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
    if (p.error != null) return VErrorState(message: p.error!, onRetry: p.fetchVendors);
    if (p.vendors.isEmpty) {
      return const VEmptyState(
        icon: Icons.storefront_outlined,
        title: 'No vendors found',
        subtitle: 'Try adjusting your filters or search term',
      );
    }
    return RefreshIndicator(
      color: VendorTheme.primary,
      backgroundColor: VendorTheme.surface,
      onRefresh: p.fetchVendors,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: p.vendors.length,
        itemBuilder: (_, i) => VendorCard(
          vendor: p.vendors[i],
          onTap: () => vendorPush(context, VendorDetailPage(vendorId: p.vendors[i].id)),

        ),
      ),
    );
  }

}