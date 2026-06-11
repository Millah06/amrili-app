import 'package:everywhere/screens/pages/transaction_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../constraints/constants.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../../../shared/widgets/amril_scan_button.dart';
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
          // Title + scan affordance on one row. Scan sits top-right, the
          // conventional spot for a primary action and clear of the search field.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text('Stores',
                    style: kTopAppbars.copyWith(
                        fontFamily:  'DejaVu Sans', fontSize: 23),
                    // style: TextStyle(
                    //     color: VendorTheme.textPrimary,
                    //     fontSize: 22,
                    //     fontWeight: FontWeight.bold)
                ),
              ),
              AmrilScanButton(
                // TODO(abdullahi): wire to the scanner route, e.g.
                  onTap: () => context.push('/scan'),
                size: 34,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            cursorColor: Colors.white,
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
    // First load / refresh → skeletons (not a bare spinner) for a smoother feel.
    if ((!p.hasLoadedOnce || p.loading) && p.vendors.isEmpty) {
      return const _VendorListSkeleton();
    }
    // Hard error with nothing to show.
    if (p.error != null && p.vendors.isEmpty) {
      return VErrorState(message: p.error!, onRetry: p.refresh);
    }
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
      onRefresh: p.refresh,
      child: NotificationListener<ScrollNotification>(
        // Kick off the next page ~400px before the end so it feels seamless.
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
            p.fetchMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          // +1 trailing slot for the loader / end-of-list marker.
          itemCount: p.vendors.length + 1,
          itemBuilder: (_, i) {
            if (i == p.vendors.length) return _buildFooter(p);
            return VendorCard(
              vendor: p.vendors[i],
              onTap: () => vendorPush(
                context,
                // Seed the detail page so its header renders instantly.
                VendorDetailPage(
                  vendorId: p.vendors[i].id,
                  initialVendor: p.vendors[i],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Bottom-of-list footer: spinner while loading more, a subtle end marker when
  /// the list is exhausted, otherwise just breathing room.
  Widget _buildFooter(VendorListProvider p) {
    if (p.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
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
    if (!p.hasMore && p.vendors.isNotEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 18, bottom: 28),
        child: Center(
          child: Text('You’ve reached the end',
              style: TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
        ),
      );
    }
    return const SizedBox(height: 12);
  }

}

// ─── Loading skeletons ────────────────────────────────────────────────────────
// Lightweight, dependency-free placeholder list shown on first load / refresh.
// A single controller pulses opacity so the grey blocks "breathe" like a skeleton
// without pulling in a shimmer package.

class _VendorListSkeleton extends StatefulWidget {
  const _VendorListSkeleton();

  @override
  State<_VendorListSkeleton> createState() => _VendorListSkeletonState();
}

class _VendorListSkeletonState extends State<_VendorListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 6,
      itemBuilder: (_, __) => FadeTransition(
        opacity: Tween(begin: 0.45, end: 0.85).animate(_c),
        child: const _VendorCardSkeleton(),
      ),
    );
  }
}

class _VendorCardSkeleton extends StatelessWidget {
  const _VendorCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: VendorTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Row(
        children: [
          // Logo placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: VendorTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(140, 14),
                const SizedBox(height: 8),
                bar(90, 11),
                const SizedBox(height: 12),
                Row(
                  children: [
                    bar(48, 18),
                    const SizedBox(width: 8),
                    bar(48, 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}