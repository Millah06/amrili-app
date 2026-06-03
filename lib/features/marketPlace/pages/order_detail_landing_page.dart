// lib/features/marketPlace/pages/order_detail_landing_page.dart
//
// PHASE 1 — FOUNDATION
//
// Destination for `amril.app/order/{orderId}`. Unlike store/product, an order is
// PRIVATE — the router already gates this route with `_requireAuth`, so by the
// time we render the user is authenticated. We fetch the order via the existing
// authenticated endpoint `GET /order/:orderId` (verified in the route table) and
// present a clean receipt-style summary with loading / error states.
//
// Why a thin landing page (vs. routing straight into an existing order screen):
// a deep link can arrive with an empty navigation stack, so we need a
// self-contained page that owns its own fetch + back behaviour. It deliberately
// shows only safe, already-modelled fields (status, total, vendor name, item
// count) and links onward; it is NOT the full order-management surface.
//
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../constraints/vendor_theme.dart';
import '../../../services/api_service.dart';

class OrderDetailLandingPage extends StatefulWidget {
  final String orderId;
  const OrderDetailLandingPage({super.key, required this.orderId});

  @override
  State<OrderDetailLandingPage> createState() => _OrderDetailLandingPageState();
}

enum _S { loading, success, error }

class _OrderDetailLandingPageState extends State<OrderDetailLandingPage> {
  final ApiService _api = ApiService();
  _S _s = _S.loading;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _s = _S.loading);
    try {
      final data = await _api.get('/order/${widget.orderId}');
      if (!mounted) return;
      setState(() {
        _order = (data is Map) ? Map<String, dynamic>.from(data) : null;
        _s = _order == null ? _S.error : _S.success;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _s = _S.error);
    }
  }

  String get _vendorName =>
      (_order?['vendorName'] as String?) ?? 'Your order';

  String get _statusLabel {
    final raw = (_order?['status'] as String?) ?? '';
    if (raw.isEmpty) return 'Order';
    // OrderStatus is camelCase (e.g. outForDelivery); humanise for display.
    final spaced = raw.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  String get _totalLabel {
    final raw = _order?['totalAmount'];
    final num? v = raw is num ? raw : num.tryParse('$raw');
    if (v == null) return '';
    return NumberFormat.currency(
        locale: 'en_NG', symbol: '₦', decimalDigits: 0)
        .format(v);
  }

  int get _itemCount {
    final items = _order?['items'];
    return items is List ? items.length : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text('Order',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
      ),
      body: switch (_s) {
        _S.loading => const Center(
            child: CircularProgressIndicator(color: VendorTheme.primary)),
        _S.error => _ErrorView(onRetry: _load),
        _S.success => _OrderBody(
          vendorName: _vendorName,
          statusLabel: _statusLabel,
          totalLabel: _totalLabel,
          itemCount: _itemCount,
        ),
      },
    );
  }
}

class _OrderBody extends StatelessWidget {
  final String vendorName;
  final String statusLabel;
  final String totalLabel;
  final int itemCount;

  const _OrderBody({
    required this.vendorName,
    required this.statusLabel,
    required this.totalLabel,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status chip — the single most important piece of order info.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: VendorTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(statusLabel,
                style: GoogleFonts.inter(
                    color: VendorTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(height: 20),
          Text(vendorName,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 24),
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _row('Items', '$itemCount'),
                const Divider(color: VendorTheme.divider, height: 24),
                _row('Total', totalLabel, emphasise: true),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: () => context.go('/'),
              child: Text('Go to app',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasise = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 14)),
        Text(value,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: emphasise ? 18 : 14,
                fontWeight: emphasise ? FontWeight.w800 : FontWeight.w600)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 64, color: VendorTheme.textMuted),
            const SizedBox(height: 18),
            Text('Couldn’t load this order',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('It may not belong to this account, or the network dropped.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 14, height: 1.5, color: Colors.white60)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
              onPressed: onRetry,
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}