import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constraints/vendor_theme.dart';

import '../../../core/constant/api_constants.dart';
import '../../../features/marketPlace/providers/vendor_provider.dart';
import '../models/vendor_model.dart';
import '../providers/table_session_provider.dart';
import '../widgets/navigation.dart';
import '../widgets/qr_share_sheet.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/trust_badge.dart';
import 'checkout.dart';

class VendorDetailPage extends StatefulWidget {
  final String vendorId;
  final String? tableId;
  const VendorDetailPage({super.key, required this.vendorId, this.tableId});

  @override
  State<VendorDetailPage> createState() => _VendorDetailPageState();
}

class _VendorDetailPageState extends State<VendorDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorDetailProvider>().loadVendor(widget.vendorId);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<TableSessionProvider>();
      if (widget.tableId != null) {
        session.attachTable(vendorId: widget.vendorId, tableId: widget.tableId!);
      } else {
        // Opened normally — drop any dine-in session from another store.
        session.clearIfOtherStore(widget.vendorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<VendorDetailProvider, CartProvider, TableSessionProvider>(
      builder: (context, detail, cart, session, _) {
        if (detail.loading) {
          return const Scaffold(
            backgroundColor: VendorTheme.background,
            body: Center(child: CircularProgressIndicator(color: VendorTheme.primary)),
          );
        }
        if (detail.error != null || detail.vendor == null) {
          return Scaffold(
            backgroundColor: VendorTheme.background,
            appBar: AppBar(backgroundColor: VendorTheme.background, elevation: 0),
            body: VErrorState(
              message: detail.error ?? 'Vendor not found',
              onRetry: () => detail.loadVendor(widget.vendorId),
            ),
          );
        }
        final vendor = detail.vendor!;
        return Scaffold(
          backgroundColor: VendorTheme.background,
          body: CustomScrollView(
            slivers: [
              _sliverAppBar(vendor),
              SliverToBoxAdapter(child: _vendorInfo(vendor)),
              SliverToBoxAdapter(child: _branchSelector(vendor, detail)),
              if (session.isDineIn || session.storeId == widget.vendorId)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: VendorTheme.primary.withOpacity(0.12),
                      child: Row(
                        children: [
                          const Icon(Icons.table_restaurant, size: 18, color: VendorTheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dine-in · Ordering for Table ${session.tableNumber ?? ''}',
                              style: const TextStyle(
                                  color: VendorTheme.primary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      const Text('Products',
                          style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Spacer(),
                      Text('${detail.menuItems.length} items',
                          style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              if (detail.isBranchLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: LinearProgressIndicator(color: VendorTheme.primary, backgroundColor: VendorTheme.surface,),
                  ),
                ),
              detail.menuItems.isEmpty
                  ? const SliverFillRemaining(
                  child: VEmptyState(icon: Icons.restaurant_menu, title: 'No menu items yet'))
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _MenuItemTile(
                      item: detail.menuItems[i],
                      vendor: vendor,
                      branchId: detail.selectedBranchId!,
                    ),
                    childCount: detail.menuItems.length,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: cart.isEmpty || cart.vendorId != widget.vendorId
              ? null
              : _cartBar(cart),
        );
      },
    );
  }

  Widget _cartBar(CartProvider cart) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: VendorTheme.surface,
        border: Border(top: BorderSide(color: VendorTheme.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: VendorTheme.surfaceVariant, borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${cart.totalItems} item${cart.totalItems == 1 ? '' : 's'}',
                    style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
                Text('₦${kFormatter.format(cart.subtotal)}',
                    style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VButton(
              label: 'Proceed to Checkout',
              onTap: () => vendorPush(context, CheckoutPage())),
            ),
        ],
      ),
    );
  }

  SliverAppBar _sliverAppBar(VendorModel vendor) {
    return SliverAppBar(
      backgroundColor: VendorTheme.background,
      expandedHeight: 200,
      pinned: true,
      actions: [
        // Share this store — opens the QR + link sheet (matches back-button style).
        GestureDetector(
          onTap: () => QRShareSheet.show(
            context,
            url: ApiConstants.storeUrl(vendor.id),
            entity: QREntity.store,
            entityId: vendor.id,
            name: vendor.name,
            logoUrl: vendor.logo,
          ),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.black54, shape: BoxShape.circle),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.ios_share_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
      leading: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/'),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: vendor.logo.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: vendor.logo,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: VendorTheme.surface),
          errorWidget: (_, __, ___) => Container(color: VendorTheme.surface),
        )
            : Container(
          color: VendorTheme.surface,
          child: const Icon(Icons.storefront, color: VendorTheme.textMuted, size: 60),
        ),
      ),
    );
  }

  Widget _vendorInfo(VendorModel vendor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(vendor.name,
                    style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              TrustBadge(level: vendor.trustLevel ?? 0,
                  verifiedFallback: vendor.verified),
            ],
          ),
          const SizedBox(height: 4),
          Text(vendor.description, style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _badge(Icons.star_rounded, const Color(0xFFFFD700), vendor.rating.toStringAsFixed(1)),
              _badge(Icons.check_circle_outline, VendorTheme.accent, '${vendor.completionRate.toStringAsFixed(0)}% completion'),
              _badge(Icons.shopping_bag_outlined, VendorTheme.textMuted, '${vendor.totalCompletedOrders} orders'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: VendorTheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: VendorTheme.textSecondary, fontSize: 12)),
      ]),
    );
  }

  Widget _branchSelector(VendorModel vendor, VendorDetailProvider detail) {
    if (vendor.branches.isEmpty) return const SizedBox.shrink();
    final session = context.watch<TableSessionProvider>();
    final dineIn = session.isDineIn && session.storeId == widget.vendorId;
    if (dineIn && session.branchId != null &&
        detail.selectedBranchId != session.branchId) {
      WidgetsBinding.instance.addPostFrameCallback(
              (_) => detail.selectBranch(session.branchId!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(dineIn ? 'Your table' : 'Select Branch',
              style: const TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vendor.branches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final branch = vendor.branches[i];
              final sel = detail.selectedBranchId == branch.id;
              return GestureDetector(
                onTap: dineIn ? null : () => detail.selectBranch(branch.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 160,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: sel ? VendorTheme.primary.withOpacity(0.15) : VendorTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? VendorTheme.primary : VendorTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${branch.area}, ${branch.lga}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: sel ? VendorTheme.primary : VendorTheme.textPrimary,
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text('~${branch.estimatedDeliveryTime} min',
                          style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItemModel item;
  final VendorModel vendor;
  final String branchId;

  const _MenuItemTile({
    required this.item,
    required this.vendor,
    required this.branchId,
  });

  void _openDetail(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: cart,
        child: _ProductDetailSheet(
          item: item,
          vendor: vendor,
          branchId: branchId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final qty = cart.quantityOf(item.id);

        return GestureDetector(
          onTap: () => _openDetail(context, cart),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VendorTheme.divider),
            ),
            child: Row(
              children: [
                // ── Thumbnail ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.images.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: item.images.first,
                          width: 78,
                          height: 78,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _Placeholder(),
                          errorWidget: (_, __, ___) => _Placeholder(),
                        )
                            : _Placeholder(),
                      ),
                      // Unavailable dim overlay
                      if (!item.isAvailable)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              color: Colors.black.withOpacity(0.50),
                              alignment: Alignment.center,
                              child: const Text(
                                'Unavailable',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Multi-image badge
                      if (item.images.length > 1)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.62),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined,
                                    color: Colors.white, size: 9),
                                const SizedBox(width: 2),
                                Text(
                                  '${item.images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info ───────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: VendorTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: VendorTheme.textMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₦${kFormatter.format(item.price)}',
                          style: const TextStyle(
                            color: VendorTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Cart control ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: item.isAvailable
                      ? (qty == 0
                      ? GestureDetector(
                    onTap: () => cart.add(
                        item, vendor.id, branchId,
                        vendor.vendorAllowsPod),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: VendorTheme.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.white, size: 18),
                    ),
                  )
                      : _QuantityControl(
                    qty: qty,
                    onDecrement: () => cart.decrement(item.id),
                    onIncrement: () => cart.add(item, vendor.id,
                        branchId, vendor.vendorAllowsPod),
                  ))
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── _ProductDetailSheet ──────────────────────────────────────────────────────

class _ProductDetailSheet extends StatefulWidget {
  final MenuItemModel item;
  final VendorModel vendor;
  final String branchId;

  const _ProductDetailSheet({
    required this.item,
    required this.vendor,
    required this.branchId,
  });

  @override
  State<_ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<_ProductDetailSheet> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final vendor = widget.vendor;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final qty = cart.quantityOf(item.id);

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: VendorTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Drag handle ─────────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 2),
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: VendorTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Scrollable body ─────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image gallery / single image + share overlay
                          Stack(
                            children: [
                              _buildImageSection(item),
                              Positioned(
                                top: 10,
                                left: 12,
                                child: GestureDetector(
                                  onTap: () => QRShareSheet.show(
                                    context,
                                    url: ApiConstants.productUrl(item.id),
                                    entity: QREntity.product,
                                    entityId: item.id,
                                    name: item.name,
                                    logoUrl: vendor.logo, // store logo in QR centre
                                  ),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.ios_share_rounded,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Product info
                          Padding(
                            padding:
                            const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: VendorTheme.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                                    if (!item.isAvailable) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: VendorTheme.error
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Unavailable',
                                          style: TextStyle(
                                            color: VendorTheme.error,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₦${kFormatter.format(item.price)}',
                                  style: const TextStyle(
                                    color: VendorTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 26,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    color: VendorTheme.textSecondary,
                                    fontSize: 14,
                                    height: 1.65,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Vendor reviews ─────────────────────────────
                          if (vendor.reviews.isNotEmpty) ...[
                            const _SectionDivider(),
                            Padding(
                              padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.reviews_outlined,
                                      color: VendorTheme.textMuted, size: 16),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Vendor Reviews',
                                    style: TextStyle(
                                      color: VendorTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${vendor.reviews.length} total',
                                    style: const TextStyle(
                                        color: VendorTheme.textMuted,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            ...vendor.reviews
                                .take(4)
                                .map((r) => _ReviewTile(review: r)),
                          ],

                          // Bottom spacer so last content clears the bar
                          const SizedBox(height: 110),
                        ],
                      ),
                    ),
                  ),

                  // ── Sticky bottom action bar ────────────────────────────
                  if (item.isAvailable)
                    Container(
                      padding: EdgeInsets.fromLTRB(
                          20, 12, 20, bottomPad + 12),
                      decoration: const BoxDecoration(
                        color: VendorTheme.surface,
                        border: Border(
                            top: BorderSide(color: VendorTheme.divider)),
                      ),
                      child: qty == 0
                          ? VButton(
                        label:
                        'Add to Cart  •  ₦${item.price.toStringAsFixed(0)}',
                        onTap: () => cart.add(item, vendor.id,
                            widget.branchId, vendor.vendorAllowsPod),
                      )
                          : Row(
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      color: VendorTheme.textMuted,
                                      fontSize: 11)),
                              Text(
                                '₦${kFormatter.format(item.price * qty)}',
                                style: const TextStyle(
                                  color: VendorTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _QuantityControl(
                            qty: qty,
                            onDecrement: () =>
                                cart.decrement(item.id),
                            onIncrement: () => cart.add(
                                item,
                                vendor.id,
                                widget.branchId,
                                vendor.vendorAllowsPod),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageSection(MenuItemModel item) {
    const double h = 280;

    if (item.images.isEmpty) {
      return Container(
        height: 200,
        color: VendorTheme.surface,
        alignment: Alignment.center,
        child: const Icon(Icons.fastfood_outlined,
            color: VendorTheme.textMuted, size: 64),
      );
    }

    if (item.images.length == 1) {
      return CachedNetworkImage(
        imageUrl: item.images.first,
        height: h,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) =>
            Container(height: h, color: VendorTheme.surface),
        errorWidget: (_, __, ___) => Container(
            height: h,
            color: VendorTheme.surface,
            alignment: Alignment.center,
            child: const Icon(Icons.fastfood_outlined,
                color: VendorTheme.textMuted, size: 60)),
      );
    }

    // Multiple images → PageView carousel
    return Stack(
      children: [
        SizedBox(
          height: h,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: item.images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: item.images[i],
              height: h,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(height: h, color: VendorTheme.surface),
              errorWidget: (_, __, ___) => Container(
                  height: h,
                  color: VendorTheme.surface,
                  alignment: Alignment.center,
                  child: const Icon(Icons.fastfood_outlined,
                      color: VendorTheme.textMuted, size: 60)),
            ),
          ),
        ),

        // Counter badge (top-right)
        Positioned(
          top: 14,
          right: 14,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_currentPage + 1} / ${item.images.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Animated pill dot indicators (bottom-center)
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              item.images.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? VendorTheme.primary
                      : Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _QuantityControl extends StatelessWidget {
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityControl({
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VendorTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBtn(
              icon: Icons.remove,
              onTap: onDecrement,
              filled: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$qty',
              style: const TextStyle(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          _IconBtn(
              icon: Icons.add,
              onTap: onIncrement,
              filled: true),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _IconBtn(
      {required this.icon, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: filled ? VendorTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : VendorTheme.textSecondary,
          size: 16,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(child: Container(height: 1, color: VendorTheme.divider)),
          const SizedBox(width: 20),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review; // your ReviewModel

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final String name = review.userName;
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar circle
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: VendorTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: VendorTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: VendorTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _timeAgo(review.createdAt),
                      style: const TextStyle(
                          color: VendorTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              _StarRow(rating: (review.rating as num).toDouble()),
            ],
          ),
          if ((review.comment).isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                color: VendorTheme.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _StarRow extends StatelessWidget {
  final double rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star_rounded,
              color: Color(0xFFFFD700), size: 14);
        } else if (i < rating) {
          return const Icon(Icons.star_half_rounded,
              color: Color(0xFFFFD700), size: 14);
        } else {
          return const Icon(Icons.star_outline_rounded,
              color: VendorTheme.textMuted, size: 14);
        }
      }),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      color: VendorTheme.surfaceVariant,
      child: const Icon(Icons.fastfood_outlined, color: VendorTheme.textMuted),
    );
  }
}