import 'package:everywhere/features/marketPlace/providers/vendor_provider.dart';
import 'package:everywhere/features/social/providers/feed_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../constraints/vendor_theme.dart';



class SearchWidget extends StatefulWidget {

  final String ? searchParameter;
  const SearchWidget({super.key, this.searchParameter});

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
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
      final p = context.read<FeedProvider>();
      // p.setVendorType(widget.searchParameter);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: VendorTheme.background,
      body: SafeArea(
        child: Consumer<FeedProvider>(
          builder: (context, p, _) {


            return Column(
              children: [
                _buildHeader(p),
                _buildFilterBar(p),
                // Expanded(child: _buildBody(p)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(FeedProvider p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search',
              style: TextStyle(color: VendorTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                child: Icon(Icons.arrow_back_ios),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8,),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 14),
                  onChanged: (S) {
                    // p.setSearch(S);
                  },
                  keyboardType: TextInputType.webSearch,
                  decoration: InputDecoration(
                    hintText: 'Search ...',
                    hintStyle: const TextStyle(color: VendorTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, color: VendorTheme.textMuted, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        // _searchCtrl.clear(); p.setSearch('');
                      },
                      child: const Icon(Icons.close, color: VendorTheme.textMuted, size: 18),
                    )
                        : null,
                    filled: true,
                    fillColor: VendorTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8,),
              TextButton(onPressed: () {}, child: Text('search', ))
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFilterBar(FeedProvider p) {
    const types = <String?>[null, 'users', 'posts', 'hashtag'];
    const labels = ['Top', 'Users', 'Posts', 'Hashtag'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: types.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              // final sel = p.selectedVendorType == types[i];
              final sel = true;
              return GestureDetector(
                // onTap: () => p.setVendorType(types[i]),
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: sel ? VendorTheme.primary : VendorTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? VendorTheme.primary : VendorTheme.divider),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                          color: sel ? VendorTheme.background : VendorTheme.textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Widget _buildBody(VendorListProvider p) {
  //   if (p.loading) return const Center(child: CircularProgressIndicator(color: VendorTheme.primary));
  //   if (p.error != null) return VErrorState(message: p.error!, onRetry: p.fetchVendors);
  //   if (p.vendors.isEmpty) {
  //     return const VEmptyState(
  //       icon: Icons.storefront_outlined,
  //       title: 'No vendors found',
  //       subtitle: 'Try adjusting your filters or search term',
  //     );
  //   }
  //   return RefreshIndicator(
  //     color: VendorTheme.primary,
  //     backgroundColor: VendorTheme.surface,
  //     onRefresh: p.fetchVendors,
  //     child: ListView.builder(
  //       padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
  //       itemCount: p.vendors.length,
  //       itemBuilder: (_, i) => VendorCard(
  //         vendor: p.vendors[i],
  //         onTap: () => vendorPush(context, VendorDetailPage(vendorId: p.vendors[i].id)),
  //
  //       ),
  //     ),
  //   );
  // }

}
