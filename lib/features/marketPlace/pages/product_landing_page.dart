// lib/features/marketPlace/pages/product_landing_page.dart
//
// PHASE 1 — FOUNDATION
//
// A shared `amril.app/product/{menuItemId}` link needs a real full-screen
// destination. In normal in-app flow a product is shown as a bottom sheet
// (`_ProductDetailSheet` inside VendorDetailPage), but a deep link can arrive
// with no store context, so we render a standalone page that:
//   • fetches the product from the public read endpoint,
//   • shows polished skeleton → success / empty / error states,
//   • offers a clear primary action: open the owning store.
//
// DATA CONTRACT: this calls `GET /web/product/:menuItemId` (the optional-auth
// endpoint built in the BACKEND half of Phase 1). The handler `getProductPublic`
// returns the MenuItem plus its owning `vendorId` so we can route to the store.
// Until that endpoint is deployed this page degrades gracefully to the error
// state with a "Browse marketplace" fallback — it never crashes.
//
// Field access is defensive (null-safe) because the exact JSON shape is
// finalised by the backend handler; we only rely on the documented MenuItem
// fields: name, description, price, images[] (String[]), and the joined vendorId.
//
import 'package:everywhere/shared/widgets/net_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../core/constant/api_constants.dart';
import '../../../services/api_service.dart';

class ProductLandingPage extends StatefulWidget {
  final String menuItemId;
  const ProductLandingPage({super.key, required this.menuItemId});

  @override
  State<ProductLandingPage> createState() => _ProductLandingPageState();
}

enum _LoadState { loading, success, empty, error }

class _ProductLandingPageState extends State<ProductLandingPage> {
  final ApiService _api = ApiService();

  _LoadState _state = _LoadState.loading;
  Map<String, dynamic>? _product;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = _LoadState.loading);
    try {
      // Public read endpoint (Phase 1 backend). ApiService.get returns decoded
      // JSON; we treat a missing/empty body as the "not found" state.
      final data = await _api.get('/web/product/${widget.menuItemId}');
      if (!mounted) return;
      if (data == null || (data is Map && data.isEmpty)) {
        setState(() => _state = _LoadState.empty);
        return;
      }
      setState(() {
        _product = Map<String, dynamic>.from(data as Map);
        _state = _LoadState.success;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  // ── Defensive field extractors ────────────────────────────────────────────
  String get _name => (_product?['name'] as String?)?.trim().isNotEmpty == true
      ? _product!['name'] as String
      : 'Product';

  String? get _description {
    final d = _product?['description'] as String?;
    return (d != null && d.trim().isNotEmpty) ? d : null;
  }

  String get _priceLabel {
    final raw = _product?['price'];
    final num? value = raw is num ? raw : num.tryParse('$raw');
    if (value == null) return '';
    final fmt = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);
    return fmt.format(value);
  }

  String? get _heroImage {
    final imgs = _product?['images'];
    if (imgs is List && imgs.isNotEmpty && imgs.first is String) {
      return imgs.first as String;
    }
    return null;
  }

  String? get _vendorId => _product?['vendorId'] as String?;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        // Deep-link arrivals have no back stack, so the leading control should
        // take the user somewhere sensible rather than dead-ending.
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Product',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
      ),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: switch (_state) {
        _LoadState.loading => const _ProductSkeleton(),
        _LoadState.success => _ProductBody(
          name: _name,
          description: _description,
          priceLabel: _priceLabel,
          heroImage: _heroImage,
          vendorId: _vendorId,
        ),
        _LoadState.empty => _StatusView(
          icon: Icons.search_off_rounded,
          title: 'Product not available',
          message:
          'This item may have been removed or is no longer on sale.',
          primaryLabel: 'Browse marketplace',
          onPrimary: () => context.go('/'),
        ),
        _LoadState.error => _StatusView(
          icon: Icons.wifi_off_rounded,
          title: 'Couldn’t load this product',
          message: 'Check your connection and try again.',
          primaryLabel: 'Retry',
          onPrimary: _load,
          secondaryLabel: 'Browse marketplace',
          onSecondary: () => context.go('/'),
        ),
      })),
    );
  }
}

// ── Success body ──────────────────────────────────────────────────────────
// Layout intent: a tall hero image anchors the page (products are visual),
// followed by name → price → description in a clear vertical hierarchy, with a
// pinned bottom CTA so the primary action is always reachable without scrolling.
class _ProductBody extends StatelessWidget {
  final String name;
  final String? description;
  final String priceLabel;
  final String? heroImage;
  final String? vendorId;

  const _ProductBody({
    required this.name,
    required this.description,
    required this.priceLabel,
    required this.heroImage,
    required this.vendorId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero
                AspectRatio(
                  aspectRatio: 1, // square hero reads well for food/retail
                  child: heroImage != null
                      ? NetImage(
                    url: heroImage!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorChild: const _ImageFallback(),
                  )
                      : const _ImageFallback(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2)),
                      if (priceLabel.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(priceLabel,
                            style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: VendorTheme.primary)),
                      ],
                      if (description != null) ...[
                        const SizedBox(height: 18),
                        Text(description!,
                            style: GoogleFonts.inter(
                                fontSize: 14.5,
                                height: 1.55,
                                color: Colors.white70)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Pinned CTA — opens the owning store (where the user can actually add
        // to cart / checkout). Disabled only if the backend didn't return a
        // vendorId, in which case we fall back to the marketplace.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => vendorId != null
                    ? context.go('/store/$vendorId')
                    : context.go('/'),
                child: Text(
                  vendorId != null ? 'View in store' : 'Browse marketplace',
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => Container(
    color: VendorTheme.surface,
    child: const Center(
      child: Icon(Icons.fastfood_rounded,
          size: 56, color: VendorTheme.textMuted),
    ),
  );
}

// ── Skeleton loader ─────────────────────────────────────────────────────────
// Mirrors the success layout (square hero + title + price + lines) so the
// transition to loaded content is calm rather than a layout jump.
class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(color: VendorTheme.surface),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(220, 24),
                const SizedBox(height: 14),
                bar(120, 20),
                const SizedBox(height: 22),
                bar(double.infinity, 14),
                const SizedBox(height: 10),
                bar(double.infinity, 14),
                const SizedBox(height: 10),
                bar(200, 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable status view (empty / error) ────────────────────────────────────
class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: VendorTheme.textMuted),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, height: 1.5, color: Colors.white60)),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: VendorTheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: onPrimary,
                child: Text(primaryLabel,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!,
                    style: GoogleFonts.inter(
                        color: VendorTheme.textMuted,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}