import 'package:everywhere/constraints/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class RecentFrame extends StatelessWidget {
  final String beneficiary;
  final VoidCallback onTap;
  final DateTime date;
  final String status;
  final String amount;

  /// Transaction type string from [TransactionModel.type].
  /// Used for icon mapping. Defaults to 'unknown'.
  final String transactionType;

  /// When true, amount is shown in green with a '+' prefix.
  final bool isCredit;

  const RecentFrame({
    super.key,
    required this.beneficiary,
    required this.date,
    required this.amount,
    required this.status,
    required this.onTap,
    this.transactionType = 'unknown',
    this.isCredit = false,
  });

  // ── Icon mapping ───────────────────────────────────────────────────────────
  static IconData iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'airtime':           return Icons.phone_android_rounded;
      case 'data':              return Icons.wifi_rounded;
      case 'electricity':       return Icons.bolt_rounded;
      case 'cable':             return Icons.tv_rounded;
      case 'waec_reg':          return Icons.school_outlined;
      case 'waec_result':       return Icons.schedule_outlined;
      case 'transfer_debit':    return Icons.arrow_upward_rounded;
      case 'transfer_credit':   return Icons.arrow_downward_rounded;
      case 'wallet_funding':    return Icons.account_balance_wallet_rounded;
      case 'order_payment':     return Icons.shopping_bag_rounded;
      case 'gift':              return Icons.card_giftcard_rounded;
      case 'wallet_withdrawal': return Icons.account_balance_rounded;
      case 'order_refund':      return Icons.replay_rounded;
      default:                  return Icons.receipt_rounded;
    }
  }

  static Color _iconBgForType(String type) {
    switch (type.toLowerCase()) {
      case 'transfer_credit':
      case 'wallet_funding':    return const Color(0xFF22C55E).withOpacity(0.12);
      case 'transfer_debit':    return const Color(0xFFEF4444).withOpacity(0.12);
      case 'electricity':       return const Color(0xFFF59E0B).withOpacity(0.12);
      case 'gift':              return const Color(0xFFEC4899).withOpacity(0.12);
      case 'wallet_withdrawal': return const Color(0xFFEF4444).withOpacity(0.12);
      case 'order_refund':      return const Color(0xFF22C55E).withOpacity(0.12);
      default:                  return const Color(0xFF177E85).withOpacity(0.12);
    }
  }

  static Color _iconColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'transfer_credit':
      case 'wallet_funding':    return const Color(0xFF22C55E);
      case 'transfer_debit':    return const Color(0xFFEF4444);
      case 'electricity':       return const Color(0xFFF59E0B);
      case 'gift':              return const Color(0xFFEC4899);
      case 'wallet_withdrawal': return const Color(0xFFEF4444);
      case 'order_refund':      return const Color(0xFF22C55E);
      default:                  return const Color(0xFF21D3ED);
    }
  }

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'success': return const Color(0xFF22C55E);
      case 'failed':  return const Color(0xFFEF4444);
      default:        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon       = iconForType(transactionType);
    final iconBg     = _iconBgForType(transactionType);
    final iconColor  = _iconColorForType(transactionType);
    final statusC    = _statusColor();
    final amtColor   = isCredit ? const Color(0xFF22C55E) : Colors.white;
    final amtPrefix  = isCredit ? '+' : '';
    final parsedAmt  = double.tryParse(amount.split(' ').first) ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // ── Icon avatar ──────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Details ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: name + amount
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          beneficiary,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$amtPrefix₦${kFormatter.format(parsedAmt)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: amtColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Bottom row: date + status chip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM d, yyyy · hh:mm a').format(date),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w400,
                          fontSize: 11,
                          color: Colors.white38,
                        ),
                      ),
                      _StatusChip(label: status, color: statusC),
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
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 0.8),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}