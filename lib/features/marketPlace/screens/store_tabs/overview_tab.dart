import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import '../../../../constraints/vendor_theme.dart';
import '../../pages/merchant_balance_page.dart';
import '../../pages/table_management_page.dart';
import '../../providers/vendor_center_provider.dart';
import '../../widgets/metrics_grid.dart';
import '../../widgets/shared_widgets.dart';
import '../../widgets/navigation.dart';

class OverviewTab extends StatelessWidget {
  final VendorCenterProvider p;
  const OverviewTab({super.key, required this.p});

  @override
  Widget build(BuildContext context) {
    final m = p.metrics;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (m != null) ...[
          MetricsGrid(metrics: m),
          const SizedBox(height: 16),
        ],
        // Earnings card — settlement language (was "Escrow Breakdown").
        // Pending = money clearing the settlement window; Available = settled
        // to the owner's balance. Tapping opens the full balance + withdrawal.
        GestureDetector(
          onTap: () => vendorPush(context, const MerchantBalancePage()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: VendorTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VendorTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Earnings',
                        style: TextStyle(
                            color: VendorTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const Spacer(),
                    const Text('Balance',
                        style: TextStyle(
                            color: VendorTheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    const Icon(Icons.chevron_right,
                        color: VendorTheme.primary, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                _erow(
                    'Pending settlement',
                    m != null ? '₦${kFormatter.format(m.pendingEscrow)}' : '—',
                    VendorTheme.warning),
                const SizedBox(height: 6),
                _erow(
                    'Available balance',
                    m != null
                        ? '₦${kFormatter.format(m.releasedEarnings)}'
                        : '—',
                    VendorTheme.accent),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Dine-in — the headline feature. Gradient tile (echoes the Earnings card's
        // shape) that opens table management + QR generation.
        GestureDetector(
          onTap: () {
            final v = p.myVendor!;
            vendorPush(context, TableManagementPage(
              vendorId: v.id,
              vendorName: v.name,
              vendorLogo: v.logo,
              branches: v.branches
                  .map((b) => TableBranchOption(id: b.id, label: '${b.area}, ${b.lga}'))
                  .toList(),
            ));
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // Subtle brand gradient so it reads as premium, not just another row.
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  VendorTheme.primary.withOpacity(0.18),
                  VendorTheme.accent.withOpacity(0.10),
                ],
              ),
              border: Border.all(color: VendorTheme.primary.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                // Icon medallion
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: VendorTheme.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded,
                      color: VendorTheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('Dine-in Ordering',
                            style: TextStyle(
                                color: VendorTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        const SizedBox(width: 6),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: VendorTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('NEW',
                              style: TextStyle(
                                  color: VendorTheme.primary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 3),
                      const Text(
                        'Print a QR for each table — guests scan, order, and pay '
                            'without waiting on staff.',
                        style: TextStyle(
                            color: VendorTheme.textSecondary,
                            fontSize: 12,
                            height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      const Row(children: [
                        Text('Set up tables',
                            style: TextStyle(
                                color: VendorTheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                        SizedBox(width: 2),
                        Icon(Icons.arrow_forward_rounded,
                            color: VendorTheme.primary, size: 14),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // In _OverviewTab build(), after existing metrics grid:
        if (p.myVendor!.branches.any((b) => b.isMainBranch)) ...[
          const SizedBox(height: 16),
          _AdvancedMetricsSection(p: p),
        ],
      ],
    );
  }

  Widget _erow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _AdvancedMetricsSection extends StatefulWidget {
  final VendorCenterProvider p;
  const _AdvancedMetricsSection({required this.p});

  @override
  State<_AdvancedMetricsSection> createState() => _AdvancedMetricsSectionState();
}

class _AdvancedMetricsSectionState extends State<_AdvancedMetricsSection> {
  @override
  void initState() {
    super.initState();
    widget.p.loadAdvancedMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.p.advancedMetrics;
    if (m == null) return const SizedBox.shrink();

    final summary       = m['summary'];
    final branchBreakdown = m['branchBreakdown'] as List;
    final topItems      = m['topItems'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with crown
        Row(children: [
          const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 18),
          const SizedBox(width: 6),
          const Text('Advanced Analytics',
              style: TextStyle(color: VendorTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Main Branch', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 12),

        // Net earnings breakdown
        VSurface(
          child: Column(
            children: [
              _mRow('Gross Revenue',  '₦${summary['totalRevenue'].toStringAsFixed(0)}',  VendorTheme.primary),
              _mRow('Platform Commission', '- ₦${summary['totalCommission'].toStringAsFixed(0)}', VendorTheme.error),
              const Divider(color: VendorTheme.divider),
              _mRow('Net Earnings',   '₦${summary['netEarnings'].toStringAsFixed(0)}',   VendorTheme.accent, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Order breakdown
        VSurface(
          child: Wrap(
            spacing: 16, runSpacing: 8,
            children: [
              _stat('Total',     '${summary['totalOrders']}',     VendorTheme.textSecondary),
              _stat('Ongoing',   '${summary['ongoingOrders']}',   VendorTheme.warning),
              _stat('Completed', '${summary['completedOrders']}', VendorTheme.accent),
              _stat('Cancelled', '${summary['cancelledOrders']}', VendorTheme.error),
              _stat('Appealed',  '${summary['appealedOrders']}',  VendorTheme.warning),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Branch breakdown
        if (branchBreakdown.isNotEmpty) ...[
          const Text('Per-Branch Performance',
              style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...branchBreakdown.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VSurface(
              child: Row(children: [
                if (b['isMainBranch'] == true)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 14),
                  ),
                Expanded(
                  child: Text('${b['area']}, ${b['lga']}',
                      style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13)),
                ),
                Text('${b['completedOrders']} orders',
                    style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
                const SizedBox(width: 12),
                Text('₦${(b['revenue'] as num).toStringAsFixed(0)}',
                    style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          )),
          const SizedBox(height: 4),
        ],

        // Top selling items
        if (topItems.isNotEmpty) ...[
          const Text('Top Selling Items',
              style: TextStyle(color: VendorTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...topItems.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: VendorTheme.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${e.key + 1}',
                      style: const TextStyle(color: VendorTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(e.value['name'], style: const TextStyle(color: VendorTheme.textPrimary, fontSize: 13))),
              Text('×${e.value['qty']}', style: const TextStyle(color: VendorTheme.textMuted, fontSize: 12)),
              const SizedBox(width: 12),
              Text('₦${(e.value['revenue'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(color: VendorTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ]),
          )),
        ],
      ],
    );
  }

  Widget _mRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 13)),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: VendorTheme.textMuted, fontSize: 11)),
      ],
    );
  }
}