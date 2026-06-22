import 'package:everywhere/components/recent_frame.dart';
import 'package:everywhere/components/view_receipt.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/providers/transaction_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _filter = 'All';
  final _scrollCtrl = ScrollController();

  static const _filters = ['All', 'Today', 'This Month', 'This Year'];

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<TransactionProvider>();
      if (prov.isEmpty && !prov.isLoading) prov.loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 250) {
      context.read<TransactionProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900), child: Consumer<TransactionProvider>(
        builder: (_, prov, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilterBar(
              selected: _filter,
              filters: _filters,
              onSelect: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: 4),
            _CountLabel(count: prov.filtered(_filter).length, isLoading: prov.isLoading),
            const SizedBox(height: 4),
            Expanded(child: _Body(prov: prov, filter: _filter, scrollCtrl: _scrollCtrl)),
          ],
        ),
      ),
      ),
    ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: const Color(0xFF0F172A),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    leading: GestureDetector(
      onTap: () => Navigator.pop(context),
      child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
    ),
    title: Text(
      'Transactions',
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
    ),
  );
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class FilterBar extends StatelessWidget {
  final String selected;
  final List<String> filters;
  final ValueChanged<String> onSelect;
  const FilterBar({super.key, required this.selected, required this.filters, required this.onSelect});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: filters.map((f) {
        final active = f == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
          child: GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF177E85) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? const Color(0xFF177E85) : Colors.white10,
                ),
              ),
              child: Center(
                child: Text(
                  f,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _CountLabel extends StatelessWidget {
  final int count;
  final bool isLoading;
  const _CountLabel({required this.count, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        '$count ${count == 1 ? 'transaction' : 'transactions'}',
        style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final TransactionProvider prov;
  final String filter;
  final ScrollController scrollCtrl;
  const _Body({required this.prov, required this.filter, required this.scrollCtrl});

  @override
  Widget build(BuildContext context) {
    if (prov.isLoading) return const _SkeletonList();
    if (prov.error != null && prov.isEmpty) return _ErrorState(prov: prov);
    final items = prov.filtered(filter);
    if (items.isEmpty) return const _EmptyState();

    return RefreshIndicator(
      color: kIconColor,
      backgroundColor: kCardColor,
      onRefresh: prov.refresh,
      child: ListView.separated(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        itemCount: items.length + (prov.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          color: Colors.white.withOpacity(0.05),
          height: 1,
        ),
        itemBuilder: (ctx, i) {
          if (i == items.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: kIconColor,
                  ),
                ),
              ),
            );
          }
          final tx = items[i];
          return RecentFrame(
            beneficiary: tx.displayLabel,
            date: tx.createdAt,
            amount: tx.amount.toString(),
            status: tx.status,
            transactionType: tx.type,
            isCredit: tx.isCredit,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => ViewReceipt(transactionId: tx.id)),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.white10),
        const SizedBox(height: 16),
        Text(
          'No transactions found',
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'Pull down to refresh',
          style: GoogleFonts.inter(color: Colors.white12, fontSize: 12),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final TransactionProvider prov;
  const _ErrorState({required this.prov});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white12),
          const SizedBox(height: 16),
          Text(
            prov.error ?? 'Something went wrong',
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: prov.loadInitial,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF177E85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Try again',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Skeleton loading ─────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
    itemCount: 8,
    separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
    itemBuilder: (_, __) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _Shimmer(width: 44, height: 44, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Shimmer(width: 130, height: 13, radius: 6),
                    _Shimmer(width: 70, height: 13, radius: 6),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Shimmer(width: 110, height: 10, radius: 5),
                    _Shimmer(width: 55, height: 18, radius: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _Shimmer({required this.width, required this.height, required this.radius});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  late final Animation<double> _anim =
  Tween(begin: 0.04, end: 0.11).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(_anim.value),
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}