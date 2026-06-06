import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// NOTE: verify this relative path matches your repo — MerchantTrustPage (Phase 4)
// lives in this same `pages/` folder and reaches the provider the same way.
import '../../../constraints/vendor_theme.dart';
import '../providers/vendor_center_provider.dart';


/// Phase 6 — Merchant Balance & Settlement dashboard.
///
/// Reads `GET /vendor/balance` and presents the three balances the merchant
/// reasons about, in the order of what they can act on:
///   • Available — withdrawable now (read live from the wallet)
///   • Pending   — paid by customers, clearing after the settlement window
///   • Paid out  — lifetime withdrawn
///
/// Below the hero, a "settlement timeline" lists recent holds so the merchant
/// can see exactly when each order's money clears. Design intent: one calm,
/// scannable screen — a single bright hero number (Available), muted supporting
/// stats, and a quiet list. No chart noise; merchants want "how much, when".
class MerchantBalancePage extends StatefulWidget {
  const MerchantBalancePage({super.key});

  @override
  State<MerchantBalancePage> createState() => _MerchantBalancePageState();
}

class _MerchantBalancePageState extends State<MerchantBalancePage> {
  _BalanceData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Keep the skeleton on the very first load; on pull-to-refresh we let the
    // RefreshIndicator own the spinner and just swap data underneath.
    if (_data == null) setState(() => _loading = true);
    try {
      final api = context.read<VendorCenterProvider>().api;
      final json = await api.get('/merchant/balance') as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _data = _BalanceData.fromJson(json);
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text('Balance & Settlements',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        iconTheme: const IconThemeData(color: VendorTheme.textPrimary),
      ),
      body: RefreshIndicator(
        color: VendorTheme.accent,
        backgroundColor: VendorTheme.surface,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const _BalanceSkeleton();
    if (_error != null) return _ErrorState(message: _error!, onRetry: _load);

    final d = _data!;
    // The dashboard is intentionally usable even before the settlement tables
    // are migrated: the API returns ready:false with zeroes, and we show a
    // gentle "coming online" banner instead of fake numbers.
    return ListView(
      // AlwaysScrollable so pull-to-refresh works even when content is short.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _HeroCard(data: d),
        const SizedBox(height: 14),
        _SettlementExplainer(hours: d.settlementHours, trustLevel: d.trustLevel),
        const SizedBox(height: 22),
        Text('Settlement timeline',
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        const SizedBox(height: 12),
        if (d.holds.isEmpty)
          const _EmptyHolds()
        else
          ...d.holds.map((h) => _HoldTile(hold: h)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — the one bright number (Available) + two muted supporting stats.
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});
  final _BalanceData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Subtle brand gradient anchors the screen without shouting.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VendorTheme.accent.withOpacity(0.16),
            const Color(0xFF177E85).withOpacity(0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VendorTheme.accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: VendorTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text('Available to withdraw',
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 10),
          // The headline figure — large, high-contrast, the focal point.
          Text(_fmt(data.available),
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.0)),
          const SizedBox(height: 18),
          // Supporting stats sit quietly beneath, split evenly.
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Pending',
                  value: _fmt(data.pending),
                  icon: Icons.hourglass_bottom_rounded,
                  color: VendorTheme.gold,
                ),
              ),
              Container(
                  width: 1, height: 34, color: VendorTheme.divider),
              Expanded(
                child: _MiniStat(
                  label: 'Paid out',
                  value: _fmt(data.paidOut),
                  icon: Icons.north_east_rounded,
                  color: VendorTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label,
        required this.value,
        required this.icon,
        required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(label,
                  style: GoogleFonts.inter(
                      color: VendorTheme.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Settlement explainer — sets expectations ("funds clear in Xh"), tied to trust.
// ─────────────────────────────────────────────────────────────────────────────
class _SettlementExplainer extends StatelessWidget {
  const _SettlementExplainer({required this.hours, required this.trustLevel});
  final int hours;
  final int trustLevel;

  @override
  Widget build(BuildContext context) {
    final window = hours % 24 == 0 ? '${hours ~/ 24} day(s)' : '${hours}h';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              color: VendorTheme.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                    color: VendorTheme.textMuted, fontSize: 12.5, height: 1.4),
                children: [
                  const TextSpan(text: 'Customer payments clear from '),
                  TextSpan(
                      text: 'Pending → Available',
                      style: GoogleFonts.inter(
                          color: VendorTheme.textPrimary,
                          fontWeight: FontWeight.w600)),
                  TextSpan(text: ' about $window after delivery. '),
                  TextSpan(
                      text: 'Higher trust settles faster.',
                      style: GoogleFonts.inter(color: VendorTheme.textMuted)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _TrustChip(level: trustLevel),
        ],
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  const _TrustChip({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: VendorTheme.accent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Trust L$level',
          style: GoogleFonts.inter(
              color: VendorTheme.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hold tile — one order's money, with a status pill + when it settles.
// ─────────────────────────────────────────────────────────────────────────────
class _HoldTile extends StatelessWidget {
  const _HoldTile({required this.hold});
  final _Hold hold;

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle(hold.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VendorTheme.divider),
      ),
      child: Row(
        children: [
          // Leading source badge (wallet vs OPay) — quick visual grouping.
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
                hold.source == 'opay'
                    ? Icons.account_balance_rounded
                    : Icons.account_balance_wallet_rounded,
                color: s.color,
                size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${hold.orderId.substring(0, hold.orderId.length.clamp(0, 8))}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: VendorTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(_subtitle(hold),
                    style: GoogleFonts.inter(
                        color: VendorTheme.textMuted, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(hold.net),
                  style: GoogleFonts.poppins(
                      color: VendorTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s.label,
                    style: GoogleFonts.inter(
                        color: s.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Contextual subtitle: when pending, show the clear date; otherwise the outcome.
  String _subtitle(_Hold h) {
    switch (h.status) {
      case 'pending':
        return 'Clears ${_date(h.settleAt)}';
      case 'frozen':
        return 'Frozen — dispute in progress';
      case 'released':
        return 'Settled ${_date(h.releasedAt ?? h.settleAt)}';
      case 'refunded':
        return 'Refunded ${_date(h.refundedAt ?? h.settleAt)}';
      case 'cancelled':
        return 'Cancelled';
      default:
        return '';
    }
  }
}

class _StatusStyle {
  const _StatusStyle(this.label, this.color);
  final String label;
  final Color color;
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case 'pending':
      return _StatusStyle('PENDING', VendorTheme.gold);
    case 'frozen':
      return _StatusStyle('FROZEN', VendorTheme.warning);
    case 'released':
      return _StatusStyle('SETTLED', VendorTheme.accent);
    case 'refunded':
      return _StatusStyle('REFUNDED', VendorTheme.error);
    case 'cancelled':
      return _StatusStyle('CANCELLED', VendorTheme.textMuted);
    default:
      return _StatusStyle(status.toUpperCase(), VendorTheme.textMuted);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// States: skeleton, empty, error.
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, double w) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: VendorTheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          height: 168,
          decoration: BoxDecoration(
            color: VendorTheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 14),
        bar(48, double.infinity),
        const SizedBox(height: 22),
        bar(16, 160),
        const SizedBox(height: 12),
        ...List.generate(
            4,
                (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: bar(66, double.infinity),
            )),
      ],
    );
  }
}

class _EmptyHolds extends StatelessWidget {
  const _EmptyHolds();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded,
              color: VendorTheme.textMuted.withOpacity(0.5), size: 40),
          const SizedBox(height: 12),
          Text('No settlements yet',
              style: GoogleFonts.poppins(
                  color: VendorTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Paid orders will appear here as they clear.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  color: VendorTheme.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // ListView so the RefreshIndicator still engages in the error state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      children: [
        Icon(Icons.cloud_off_rounded, color: VendorTheme.textMuted, size: 44),
        const SizedBox(height: 16),
        Text('Couldn’t load your balance',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: VendorTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style:
            GoogleFonts.inter(color: VendorTheme.textMuted, fontSize: 12)),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: VendorTheme.accent),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            ),
            child: Text('Retry',
                style: GoogleFonts.inter(
                    color: VendorTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lightweight models + formatting (kept local — this is the only screen reading
// the /vendor/balance shape).
// ─────────────────────────────────────────────────────────────────────────────
class _BalanceData {
  _BalanceData({
    required this.pending,
    required this.available,
    required this.paidOut,
    required this.settlementHours,
    required this.trustLevel,
    required this.holds,
  });

  final double pending;
  final double available;
  final double paidOut;
  final int settlementHours;
  final int trustLevel;
  final List<_Hold> holds;

  factory _BalanceData.fromJson(Map<String, dynamic> j) => _BalanceData(
    pending: _d(j['pending']),
    available: _d(j['available']),
    paidOut: _d(j['paidOut']),
    settlementHours: (j['settlementHours'] as num?)?.toInt() ?? 48,
    trustLevel: (j['trustLevel'] as num?)?.toInt() ?? 1,
    holds: ((j['holds'] as List?) ?? [])
        .map((h) => _Hold.fromJson(h as Map<String, dynamic>))
        .toList(),
  );
}

class _Hold {
  _Hold({
    required this.id,
    required this.orderId,
    required this.net,
    required this.status,
    required this.source,
    required this.settleAt,
    this.releasedAt,
    this.refundedAt,
  });

  final String id;
  final String orderId;
  final double net;
  final String status;
  final String source;
  final DateTime settleAt;
  final DateTime? releasedAt;
  final DateTime? refundedAt;

  factory _Hold.fromJson(Map<String, dynamic> j) => _Hold(
    id: j['id']?.toString() ?? '',
    orderId: j['orderId']?.toString() ?? '',
    net: _d(j['net']),
    status: j['status']?.toString() ?? 'pending',
    source: j['source']?.toString() ?? 'wallet',
    settleAt: _parseDate(j['settleAt']) ?? DateTime.now(),
    releasedAt: _parseDate(j['releasedAt']),
    refundedAt: _parseDate(j['refundedAt']),
  );
}

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// ₦ with thousands separators, no decimals when whole.
String _fmt(double amount) {
  final whole = amount.truncate();
  final str = whole.toString();
  final buf = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
    buf.write(str[i]);
  }
  return '₦$buf';
}

/// Compact date like "12 Jun" / "12 Jun, 14:30" for today-ish entries.
String _date(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final now = DateTime.now();
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  final t =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (sameDay) return 'today $t';
  return '${d.day} ${months[d.month - 1]}';
}