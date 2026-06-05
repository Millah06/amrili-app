// lib/features/utility/services/utility_purchase.dart
//
// One entry point every utility screen uses, replacing ConfirmationPage +
// TransactionService.handlePurchase + the per-service purchase_service methods.
//
// It owns the WHOLE flow so each screen is a single call and shows nothing
// itself:
//   1. opens the universal PaymentSheet (success screen SUPPRESSED — we don't
//      want a double "success"),
//   2. the backend engine takes the money (wallet w/ reward-spend, or OPay) and
//      the `utility` handler fulfils with VTPass,
//   3. UtilityPurchase shows ONE screen — the receipt — which is the success
//      UI AND shows the token/PIN or a "pending" state instantly, so the user
//      never has to dig through transaction history.
//
// Returns true if the purchase was paid (delivered or pending). The calling
// screen typically just resets its form on true.

import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/features/payment/models/payment_models.dart';
import 'package:everywhere/features/payment/widgets/payment_sheet.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kAccent = Color(0xFF21D3ED);
const _kTeal = Color(0xFF177E85);

class UtilityPurchase {
  UtilityPurchase._();

  /// Pay for a utility and show the receipt. Returns true if paid.
  static Future<bool> buy(
      BuildContext context, {
        required double amount,
        required String productName,
        required String service, // 'airtime'|'data'|'electricity'|'cable'|'smile'|'jamb'|'waec'|'waec-registration'
        required String serviceID, // VTPass serviceID, e.g. 'mtn', 'ikeja-electric', 'dstv'
        String? phone,
        String? variationCode,
        String? billersCode,
        String? subscriptionType,
        int? quantity,
        bool useReward = false, // option B — spend reward balance toward this purchase
        bool isRecharge = false,
      }) async {
    // Reward balance the wallet can also draw on (for the local affordability
    // gate). The backend `calculateTransaction` is authoritative on the split.
    final rewardBalance =
        context.read<UserProvider>().user?.wallet.fiat.rewardBalance ?? 0.0;

    final meta = <String, dynamic>{
      'service': service,
      'serviceID': serviceID,
      if (phone != null) 'phone': phone,
      'amount': amount,
      if (variationCode != null) 'variationCode': variationCode,
      if (billersCode != null) 'billersCode': billersCode,
      if (subscriptionType != null) 'subscriptionType': subscriptionType,
      if (quantity != null) 'quantity': quantity,
      'productName': productName,
      'useReward': useReward,
      'isRecharge': isRecharge,
    };

    final result = await PaymentSheet.show(
      context,
      amount: amount,
      entityType: 'utility',
      entityId: 'utility', // request lives in meta; not a DB row
      productName: productName,
      meta: meta,
      walletExtraSpendable: useReward ? rewardBalance : 0,
      suppressSuccessScreen: true, // the receipt below IS the success UI
    );

    if (result == null || result.status != PaymentStatus.success) return false;
    if (!context.mounted) return false;

    await _showReceipt(context, result, productName: productName);
    return true;
  }

  static Future<void> _showReceipt(
      BuildContext context,
      PaymentResult result, {
        required String productName,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UtilityReceiptSheet(result: result, productName: productName),
    );
  }
}

class _UtilityReceiptSheet extends StatelessWidget {
  final PaymentResult result;
  final String productName;
  const _UtilityReceiptSheet({required this.result, required this.productName});

  // delivery = { status, token, tokens, productName, bonusEarned }
  String get _deliveryStatus =>
      (result.delivery?['status'] as String?) ?? 'delivered';
  String? get _token => result.delivery?['token'] as String?;
  dynamic get _tokens => result.delivery?['tokens'];

  bool get _isPending => _deliveryStatus == 'pending';
  bool get _isRefunded => _deliveryStatus == 'refunded';

  String _money(double v) {
    final whole = v.truncateToDouble() == v;
    final s = v
        .toStringAsFixed(whole ? 0 : 2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '₦$s';
  }

  @override
  Widget build(BuildContext context) {
    // Pick the headline state.
    final Color ringColor;
    final IconData icon;
    final String title;
    final String subtitle;
    if (_isPending) {
      ringColor = Colors.amber;
      icon = Icons.hourglass_top_rounded;
      title = 'Payment received';
      subtitle = 'Your purchase is processing and will complete shortly.';
    } else if (_isRefunded) {
      ringColor = Colors.redAccent;
      icon = Icons.error_outline_rounded;
      title = 'Could not complete';
      subtitle = 'We couldn\'t deliver this, so the amount was refunded to your wallet.';
    } else {
      ringColor = _kAccent;
      icon = Icons.check_rounded;
      title = 'Successful';
      subtitle = productName;
    }

    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: EdgeInsets.fromLTRB(
          22, 14, 22, MediaQuery.of(context).viewInsets.bottom + 26),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 22),

            // Status badge.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isRefunded || _isPending
                      ? null
                      : const LinearGradient(colors: [_kTeal, _kAccent]),
                  color: _isRefunded
                      ? Colors.redAccent.withOpacity(0.15)
                      : _isPending
                      ? Colors.amber.withOpacity(0.15)
                      : null,
                ),
                child: Icon(icon,
                    color: _isRefunded || _isPending ? ringColor : Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13.5, height: 1.4)),
            ),
            const SizedBox(height: 20),

            // Amount row.
            _row('Amount', _money(result.amount)),
            const SizedBox(height: 10),
            _row('Reference', result.paymentId,
                copyable: true, context: context),

            // Token / PIN(s) — the whole point of an instant receipt.
            if (!_isRefunded && _token != null && _token!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _TokenBox(label: 'Token', value: _token!.trim()),
            ],
            if (!_isRefunded && _tokens != null) ...[
              const SizedBox(height: 16),
              _TokenBox(label: 'Tokens / PINs', value: _tokens.toString()),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kButtonColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Done',
                    style: GoogleFonts.inter(
                        color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool copyable = false, BuildContext? context}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (copyable && context != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 15, color: _kAccent),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// Prominent, copyable token/PIN block.
class _TokenBox extends StatelessWidget {
  final String label;
  final String value;
  const _TokenBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  color: Colors.white38, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(value,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.copy_rounded, size: 18, color: _kAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}