// lib/features/payment/widgets/payment_sheet.dart
//
// ─────────────────────────────────────────────────────────────────────────────
// Amril universal PaymentSheet — ONE sheet for every paid action in the app.
//
// This is the single component that replaces ConfirmationPage + per-screen
// payment UIs. Open it with an amount + what the payment is for, and await a
// bool: `true` only when the BACKEND confirms the money landed (wallet debited,
// or OPay verified). The UI never decides success on its own (spec §12).
//
//   final paid = await PaymentSheet.show(
//     context,
//     amount: 2500,
//     entityType: PaymentEntity.utility,   // or marketplaceOrder, dineInOrder…
//     entityId: requestId,
//     productName: 'MTN ₦2,500 Airtime',
//   );
//   if (paid) { /* show receipt / navigate */ }
//
// DESIGN NOTES (why it looks the way it does):
//  • Two methods are shown as a SELECTOR (not instant-action rows) so the user
//    sees both, with a smart default already chosen: Wallet when the balance
//    covers it, OPay otherwise. One primary CTA confirms the choice.
//  • Wallet balance is read LIVE from UserProvider and checked LOCALLY — if the
//    balance can't cover the amount we never hit the backend for wallet; we
//    disable it, explain, and steer to OPay. On wallet success we optimistically
//    update the local balance (UserProvider.applyWalletDelta) so the wallet
//    screen is correct instantly, no refetch round-trip.
//  • OPay is presented as "Open OPay" (one tap into the OPay app via evokeOpay),
//    not as a "secure web checkout". We launch the cashier link with
//    url_launcher in external mode so the OPay app intercepts it; the in-app
//    WebView is only a fallback when the external launch fails.
//  • Brand marks: your app icon on Wallet, the OPay logo on OPay (asset with a
//    graceful icon fallback if the asset isn't bundled yet).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:everywhere/components/transacrtion_pin.dart';
import 'package:everywhere/constraints/constants.dart';
import 'package:everywhere/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/payment_models.dart';
import '../services/payment_service.dart';

// Palette — matches the app's existing dark system.
const _kBg = Color(0xFF0F172A);
const _kSurface = Color(0xFF1E293B);
const _kAccent = Color(0xFF21D3ED);
const _kTeal = Color(0xFF177E85);
const _kOpayGreen = Color(0xFF1DC962); // OPay brand green (for the fallback badge)

// Drop these into pubspec `assets:` to show real logos; if absent, the sheet
// falls back to styled icon badges automatically (see _BrandBadge).
const _kAmrilIconAsset = 'images/amril_icon.png';
const _kOpayLogoAsset = 'images/opay_logo.png';

/// Internal phases. `walletPinEntry` is delegated to the existing TransactionPin
/// modal, so the sheet jumps straight to `walletVerifying` once the PIN passes.
enum _Phase {
  selecting,
  walletVerifying,
  coinExecuting, // gifting / coin-ledger payments (separate from the fiat engine)
  opayLaunching,
  opayVerifying,
  success,
  failed
}

class PaymentSheet extends StatefulWidget {
  /// Amount to charge, in Naira.
  final double amount;

  /// What the payment is for — drives backend dispatch. Use the engine's
  /// entity constants ('marketplace_order' | 'utility' | 'dine_in_order' | …).
  final String entityType;

  /// Id of the thing being paid for (orderId, utilityRequestId, …).
  final String entityId;

  /// Human label shown on the sheet + the OPay cashier page.
  final String? productName;

  /// Optional extra data forwarded to the backend (stored on the Payment and
  /// read by its handler — e.g. utility service params).
  final Map<String, dynamic>? meta;

  /// Restrict to a single provider (e.g. OPay-only for non-wallet contexts).
  final PaymentProvider? lockProvider;

  /// Override the wallet balance shown/checked. When null, read live from
  /// UserProvider — the normal case.
  final double? walletBalanceOverride;

  /// Extra spendable beyond available balance — e.g. usable reward balance for
  /// utilities (option B). Used ONLY for the local affordability gate; the
  /// backend (`calculateTransaction`) remains authoritative on the real split.
  final double walletExtraSpendable;

  /// When true the sheet skips its own success celebration and pops immediately
  /// with the result, so the caller can show its own receipt (e.g. utilities,
  /// which show a token/PIN receipt). Avoids a double "success" screen.
  final bool suppressSuccessScreen;

  /// Resume an already-created payment (resume-recovery): opens straight into
  /// "Verifying…" and polls.
  final String? recoverPaymentId;

  // ── Coin mode (gifting) ─────────────────────────────────────────────────
  // Coins are a SEPARATE ledger from the fiat wallet/OPay engine, so coin
  // payments don't create a backend Payment row — they call `onCoinConfirm`
  // (e.g. the gift-send endpoint) directly. We keep them in this same sheet so
  // gifting looks and behaves identically to every other payment in the app.
  // Funding coins themselves (buy coins via OPay / Apple Pay / Google Pay) is a
  // later phase and WILL go through the fiat engine above.
  final bool coinMode;
  final int coinCost;
  final int coinBalance;
  final Future<bool> Function()? onCoinConfirm;
  final VoidCallback? onGetCoins; // shown when coins are short AND no wallet fallback
  // Gift coins-else-wallet: when coins are short, the backend auto-charges the
  // wallet for the shortfall. If provided, the sheet shows this ₦ note and
  // proceeds (with PIN) instead of blocking.
  final double? coinShortfallNaira;

  const PaymentSheet({
    super.key,
    required this.amount,
    required this.entityType,
    required this.entityId,
    this.productName,
    this.meta,
    this.lockProvider,
    this.walletBalanceOverride,
    this.walletExtraSpendable = 0,
    this.suppressSuccessScreen = false,
    this.recoverPaymentId,
    this.coinMode = false,
    this.coinCost = 0,
    this.coinBalance = 0,
    this.onCoinConfirm,
    this.onGetCoins,
    this.coinShortfallNaira,
  });

  /// Present the sheet. Returns the final [PaymentResult] on success (so the
  /// caller can read `delivery` for a receipt), or null if not completed.
  static Future<PaymentResult?> show(
      BuildContext context, {
        required double amount,
        required String entityType,
        required String entityId,
        String? productName,
        Map<String, dynamic>? meta,
        PaymentProvider? lockProvider,
        double? walletBalanceOverride,
        double walletExtraSpendable = 0,
        bool suppressSuccessScreen = false,
        String? recoverPaymentId,
      }) async {
    return showModalBottomSheet<PaymentResult?>(
      context: context,
      isScrollControlled: true,
      enableDrag: false, // the sheet manages its own close so a payment is never
      isDismissible: true, //   left half-resolved on screen
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(
        amount: amount,
        entityType: entityType,
        entityId: entityId,
        productName: productName,
        meta: meta,
        lockProvider: lockProvider,
        walletBalanceOverride: walletBalanceOverride,
        walletExtraSpendable: walletExtraSpendable,
        suppressSuccessScreen: suppressSuccessScreen,
        recoverPaymentId: recoverPaymentId,
      ),
    );
  }

  /// Present the sheet for a COIN payment (gifting). Returns `true` when
  /// `onConfirm` reports success. Same look & feel as fiat payments.
  static Future<bool> coins(
      BuildContext context, {
        required int coinCost,
        required int coinBalance,
        required Future<bool> Function() onConfirm,
        String? productName,
        VoidCallback? onGetCoins,
        /// When the gift backend tops up the coin shortfall from the wallet, pass the
        /// ₦ shortfall here — the sheet shows it and proceeds (PIN) instead of
        /// blocking. Leave null to block when coins are short (and offer "Get coins").
        double? walletFallbackNaira,
      }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentSheet(
        amount: coinCost.toDouble(),
        entityType: 'gift',
        entityId: '',
        productName: productName,
        coinMode: true,
        coinCost: coinCost,
        coinBalance: coinBalance,
        onCoinConfirm: onConfirm,
        onGetCoins: onGetCoins,
        coinShortfallNaira: walletFallbackNaira,
      ),
    );
    return result ?? false;
  }

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final _svc = PaymentService.instance;

  _Phase _phase = _Phase.selecting;
  String? _error;
  String? _paymentId;

  /// The method the user has selected (smart default set in build()).
  PaymentProvider? _selected;

  /// Final payment state on success — returned to the caller (carries delivery).
  PaymentResult? _result;

  // One idempotency key per logical payment — reused across retries of the SAME
  // payment so the backend never double-charges; regenerated only on a fresh
  // "Try again".
  late String _clientRequestId = _svc.newClientRequestId();

  Timer? _pollTimer;
  int _pollTicks = 0;
  static const _pollEvery = Duration(seconds: 3);
  static const _pollMaxTicks = 40; // ~2 min before we surface a "still pending" CTA

  @override
  void initState() {
    super.initState();
    if (widget.recoverPaymentId != null) {
      _paymentId = widget.recoverPaymentId;
      _phase = _Phase.opayVerifying;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startPolling());
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ─── Wallet balance (read live from UserProvider, checked locally) ──────────

  double _walletBalance(BuildContext context) {
    if (widget.walletBalanceOverride != null) return widget.walletBalanceOverride!;
    // listen:false — we read it imperatively; the build reads it via watch.
    final up = context.read<UserProvider>();
    return up.user?.wallet.fiat.availableBalance ?? 0.0;
  }

  bool _walletCanCover(BuildContext context) =>
      (_walletBalance(context) + widget.walletExtraSpendable) >= widget.amount;

  // ─── Method availability ─────────────────────────────────────────────────
  bool get _walletAllowed =>
      widget.lockProvider == null || widget.lockProvider == PaymentProvider.wallet;
  bool get _opayAllowed =>
      widget.lockProvider == null || widget.lockProvider == PaymentProvider.opay;

  /// Smart default: Wallet if it covers the amount, else OPay. Computed once
  /// the first time we build the selector.
  void _ensureDefaultSelection(BuildContext context) {
    if (_selected != null) return;
    final canWallet = _walletAllowed && _walletCanCover(context);
    if (canWallet) {
      _selected = PaymentProvider.wallet;
    } else if (_opayAllowed) {
      _selected = PaymentProvider.opay;
    } else if (_walletAllowed) {
      _selected = PaymentProvider.wallet; // wallet-locked but short — handled at CTA
    }
  }

  // ─── Confirm (single CTA) ───────────────────────────────────────────────────

  void _confirm(BuildContext context) {
    if (widget.coinMode) {
      final short = widget.coinBalance < widget.coinCost;
      // If coins are short AND there's no wallet-fallback configured, block.
      if (short && widget.coinShortfallNaira == null) {
        setState(() => _error = 'You don\'t have enough coins.');
        return;
      }
      _startCoins(); // gift touches the wallet (coins-else-wallet) → PIN first
      return;
    }
    switch (_selected) {
      case PaymentProvider.wallet:
      // Local guard — never spend a backend call when we already know the
      // balance is short.
        if (!_walletCanCover(context)) {
          setState(() => _error = 'Your wallet balance is not enough for this payment.');
          return;
        }
        _startWallet();
        break;
      case PaymentProvider.opay:
        _startOpay();
        break;
      case null:
        break;
    }
  }

  // ─── Coin path (gifting) — PIN-gated, calls the gift endpoint ───────────────

  void _startCoins() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransactionPin(onSuccess: _executeCoins),
    );
  }

  Future<void> _executeCoins() async {
    setState(() {
      _phase = _Phase.coinExecuting;
      _error = null;
    });
    try {
      final ok = (await widget.onCoinConfirm?.call()) ?? false;
      if (!mounted) return;
      ok ? _goSuccess() : _goFailed('That didn\'t go through. Please try again.');
    } catch (e) {
      if (!mounted) return;
      _goFailed(_clean(e));
    }
  }

  // ─── Wallet path — reuse the existing TransactionPin (PIN/biometric) ────────

  void _startWallet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TransactionPin(onSuccess: _executeWallet),
    );
  }

  Future<void> _executeWallet() async {
    setState(() {
      _phase = _Phase.walletVerifying;
      _error = null;
    });
    try {
      final res = await _svc.payWithWallet(
        amount: widget.amount,
        entityType: widget.entityType,
        entityId: widget.entityId,
        clientRequestId: _clientRequestId,
        productName: widget.productName,
        meta: {...?widget.meta, 'platform': 'mobile'},
      );
      if (!mounted) return;
      if (res.status == PaymentStatus.success) {
        _result = res;
        // Refresh wallet so the (reward-adjusted) balance is correct.
        context.read<UserProvider>().applyWalletDelta(-widget.amount);
        _goSuccess();
      } else if (res.status == PaymentStatus.refunded) {
        _goFailed(res.message ??
            'The payment could not be completed and was refunded to your wallet.');
      } else {
        _goFailed(res.message ?? 'Wallet payment could not be completed.');
      }
    } catch (e) {
      if (!mounted) return;
      _goFailed(_clean(e));
    }
  }

  // ─── OPay path — open the OPay app first, WebView only as fallback ──────────

  Future<void> _startOpay() async {
    setState(() {
      _phase = _Phase.opayLaunching;
      _error = null;
    });
    try {
      const returnUrl = 'https://amril.app/checkout-success';
      final res = await _svc.create(
        provider: PaymentProvider.opay,
        amount: widget.amount,
        entityType: widget.entityType,
        entityId: widget.entityId,
        clientRequestId: _clientRequestId,
        productName: widget.productName,
        returnUrl: returnUrl,
        meta: {...?widget.meta, 'platform': 'ANDROID'},
      );
      print(res);
      if (!mounted) return;
      _paymentId = res.paymentId;

      final url = res.cashierUrl;
      if (url == null || url.isEmpty) {
        _goFailed('Could not start OPay. Please try again.');
        return;
      }

      // PRIORITY: hand the cashier link to the OS so the OPay app opens directly
      // (evokeOpay on the backend makes the link app-aware). If no handler can
      // take it, fall back to an in-app WebView so the user is never stuck.
      bool launched = false;
      try {
        launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        launched = false;
      }

      if (!launched) {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _OpayWebViewPage(cashierUrl: url, returnUrlPrefix: returnUrl),
          fullscreenDialog: true,
        ));
      }
      if (!mounted) return;

      // Either way the backend is the source of truth — go verify + poll.
      setState(() => _phase = _Phase.opayVerifying);
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      _goFailed(_clean(e));
    }
  }

  // ─── Polling (OPay verify + recovery) ──────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTicks = 0;
    _pollOnce(); // immediate
    _pollTimer = Timer.periodic(_pollEvery, (_) => _pollOnce());
  }

  Future<void> _pollOnce() async {
    final id = _paymentId;
    if (id == null) return;
    _pollTicks++;
    try {
      final res = await _svc.status(id);
      if (!mounted) return;
      switch (res.status) {
        case PaymentStatus.success:
          _result = res;
          _goSuccess();
          return;
        case PaymentStatus.failed:
        case PaymentStatus.expired:
          _goFailed('The payment did not go through. You can try again.');
          return;
        case PaymentStatus.refunded:
          _goFailed('The payment was received but could not be completed, so it was refunded.');
          return;
        default:
          break; // still in flight
      }
    } catch (_) {/* transient — keep polling */}
    if (_pollTicks >= _pollMaxTicks) {
      _pollTimer?.cancel();
      if (mounted) setState(() {}); // surface "still checking" CTA — not a failure
    }
  }

  // ─── Terminal transitions ──────────────────────────────────────────────────

  /// Pop with the right type: coin mode returns bool; fiat returns PaymentResult?.
  void _close(bool success) {
    Navigator.of(context).pop(widget.coinMode ? success : (success ? _result : null));
  }

  void _goSuccess() {
    _pollTimer?.cancel();
    // Utilities suppress the celebration and pop immediately so the caller can
    // show its own receipt (token/PIN) — no double success screen.
    if (widget.suppressSuccessScreen) {
      _close(true);
      return;
    }
    setState(() => _phase = _Phase.success);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _close(true);
    });
  }

  void _goFailed(String message) {
    _pollTimer?.cancel();
    setState(() {
      _phase = _Phase.failed;
      _error = message;
    });
  }

  void _retry() {
    _clientRequestId = _svc.newClientRequestId(); // fresh attempt
    _paymentId = null;
    setState(() {
      _phase = _Phase.selecting;
      _error = null;
    });
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '').trim();

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Watch UserProvider so the wallet card balance stays live.
    context.watch<UserProvider>();
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
            _grabber(),
            const SizedBox(height: 18),
            // AnimatedSize smooths the height change between states so the sheet
            // grows/shrinks gracefully instead of snapping to a tiny cut.
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, if (current != null) current],
                ),
                child: KeyedSubtree(
                  key: ValueKey(_phase),
                  child: _phaseBody(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grabber() => Container(
    width: 42,
    height: 5,
    decoration: BoxDecoration(
        color: Colors.white24, borderRadius: BorderRadius.circular(3)),
  );

  Widget _phaseBody(BuildContext context) {
    switch (_phase) {
      case _Phase.selecting:
        return _selecting(context);
      case _Phase.walletVerifying:
        return _busy('Processing your wallet payment…', key: 'wallet');
      case _Phase.coinExecuting:
        return _busy('Sending your gift…', key: 'coin');
      case _Phase.opayLaunching:
        return _busy('Opening OPay…', key: 'launch');
      case _Phase.opayVerifying:
        return _verifying();
      case _Phase.success:
        return _successView();
      case _Phase.failed:
        return _failedView();
    }
  }

  // ── Method selection ──

  Widget _selecting(BuildContext context) {
    // ── Coin mode (gifting): one "coins" method, local balance check ──────────
    if (widget.coinMode) {
      final short = widget.coinBalance < widget.coinCost;
      final hasFallback = widget.coinShortfallNaira != null; // wallet tops up the rest
      final canProceed = !short || hasFallback;
      return Column(
        key: const ValueKey('selecting_coins'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _amountHeader(),
          const SizedBox(height: 20),
          _MethodCard(
            brand: _BrandBadge(
              asset: _kAmrilIconAsset,
              fallbackIcon: Icons.monetization_on_rounded,
              fallbackBg: const Color(0xFFF5C84B), // coin gold
            ),
            title: 'Pay with coins',
            subtitle: short
                ? (hasFallback
                ? 'Balance ${_coins(widget.coinBalance)}'
                : 'Balance ${_coins(widget.coinBalance)} · not enough')
                : 'Balance ${_coins(widget.coinBalance)}',
            selected: canProceed,
            disabled: short && !hasFallback,
            onTap: null, // single method — nothing to toggle
          ),
          // Coins-else-wallet: tell the user the shortfall comes from the wallet.
          if (short && hasFallback) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.orangeAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_money(widget.coinShortfallNaira!)} will come from your wallet',
                    style: GoogleFonts.inter(color: Colors.orangeAccent.shade100, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: GoogleFonts.inter(color: Colors.redAccent.shade100, fontSize: 12.5)),
          ],
          const SizedBox(height: 18),
          if (short && !hasFallback && widget.onGetCoins != null)
            _PrimaryButton(
              label: 'Get more coins',
              icon: Icons.add_rounded,
              onTap: () {
                Navigator.of(context).pop(false);
                widget.onGetCoins!.call();
              },
            )
          else
            _PrimaryButton(
              label: canProceed ? 'Send ${_coins(widget.coinCost)}' : 'Not enough coins',
              onTap: canProceed ? () => _confirm(context) : null,
            ),
          const SizedBox(height: 12),
          _secureNote(),
        ],
      );
    }

    _ensureDefaultSelection(context);
    final balance = _walletBalance(context);
    final walletShort = !_walletCanCover(context);

    return Column(
      key: const ValueKey('selecting'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _amountHeader(),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Pay with',
              style: GoogleFonts.inter(
                  color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),

        if (_walletAllowed)
          _MethodCard(
            brand: _BrandBadge(
              asset: _kAmrilIconAsset,
              fallbackIcon: Icons.account_balance_wallet_rounded,
              fallbackBg: _kAccent,
            ),
            title: 'Amril Wallet',
            // The subtitle doubles as the local balance check + steer-to-OPay.
            subtitle: walletShort
                ? 'Balance ${_money(balance)} · not enough'
                : 'Balance ${_money(balance)}',
            selected: _selected == PaymentProvider.wallet,
            disabled: walletShort,
            onTap: walletShort
                ? null
                : () => setState(() {
              _selected = PaymentProvider.wallet;
              _error = null;
            }),
          ),

        if (_walletAllowed && _opayAllowed) const SizedBox(height: 10),

        if (_opayAllowed)
          _MethodCard(
            brand: _BrandBadge(
              asset: _kOpayLogoAsset,
              fallbackIcon: Icons.bolt_rounded,
              fallbackBg: _kOpayGreen,
            ),
            title: 'Pay with OPay',
            subtitle: 'One tap — opens the OPay app',
            selected: _selected == PaymentProvider.opay,
            onTap: () => setState(() {
              _selected = PaymentProvider.opay;
              _error = null;
            }),
          ),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              style: GoogleFonts.inter(color: Colors.redAccent.shade100, fontSize: 12.5)),
        ],

        const SizedBox(height: 18),
        _PrimaryButton(
          label: _ctaLabel(),
          icon: _selected == PaymentProvider.opay ? Icons.open_in_new_rounded : null,
          onTap: _selected == null ? null : () => _confirm(context),
        ),
        const SizedBox(height: 12),
        _secureNote(),
      ],
    );
  }

  String _ctaLabel() {
    switch (_selected) {
      case PaymentProvider.wallet:
        return 'Pay ${_money(widget.amount)}';
      case PaymentProvider.opay:
        return 'Open OPay · ${_money(widget.amount)}';
      case null:
        return 'Select a payment method';
    }
  }

  Widget _amountHeader() => Column(
    children: [
      Text(widget.coinMode ? 'Gift' : 'Amount to pay',
          style: GoogleFonts.inter(
              color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(widget.coinMode ? _coins(widget.coinCost) : _money(widget.amount),
          style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 33,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5)),
      if ((widget.productName ?? '').trim().isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(widget.productName!.trim(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
      ],
    ],
  );

  // "1,250 coins" / "1 coin"
  String _coins(int n) {
    final s = n.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '$s ${n == 1 ? 'coin' : 'coins'}';
  }

  Widget _secureNote() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.verified_user_rounded, size: 12, color: Colors.white24),
      const SizedBox(width: 6),
      Text('Completed securely by Amril',
          style: GoogleFonts.inter(color: Colors.white30, fontSize: 11)),
    ],
  );

  // ── Busy / verifying / success / failure ──

  // ── Busy / verifying / success / failure ──
  //
  // All transient states share a comfortable min-height so the sheet never
  // collapses into a tiny "cut" at the bottom. Content is vertically centred
  // inside that space with a branded ring indicator.

  static const double _statusMinHeight = 300;

  /// A 96px brand ring with either a spinner or an icon at its centre.
  Widget _statusRing({Widget? center, bool spinning = false}) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (spinning)
            const SizedBox(
              width: 96,
              height: 96,
              child: CircularProgressIndicator(strokeWidth: 3, color: _kAccent),
            ),
          // Soft inner disc so the centre reads as a deliberate badge.
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kAccent.withOpacity(0.10),
            ),
            child: Center(child: center),
          ),
        ],
      ),
    );
  }

  Widget _busy(String label, {required String key}) {
    final sub = widget.coinMode ? _coins(widget.coinCost) : _money(widget.amount);
    return ConstrainedBox(
      key: ValueKey(key),
      constraints: const BoxConstraints(minHeight: _statusMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusRing(
              spinning: true,
              center: Icon(
                key == 'launch'
                    ? Icons.open_in_new_rounded
                    : (widget.coinMode
                    ? Icons.card_giftcard_rounded
                    : Icons.account_balance_wallet_rounded),
                color: _kAccent,
                size: 26,
              ),
            ),
            const SizedBox(height: 26),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _verifying() {
    final timedOut = _pollTicks >= _pollMaxTicks;
    return ConstrainedBox(
      key: const ValueKey('verifying'),
      constraints: const BoxConstraints(minHeight: _statusMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statusRing(
              spinning: true,
              center: const Icon(Icons.shield_moon_rounded, color: _kAccent, size: 26),
            ),
            const SizedBox(height: 24),
            Text('Verifying payment…',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                timedOut
                    ? "Taking longer than usual. If you paid, it'll be confirmed shortly — you can keep this open or close and we'll finish it for you."
                    : "Confirming with OPay. You can finish in the OPay app and come back here.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white54, fontSize: 13.5, height: 1.5),
              ),
            ),
            if (timedOut) ...[
              const SizedBox(height: 22),
              Row(children: [
                Expanded(
                    child: _GhostButton(
                        label: 'Close', onTap: () => _close(false))),
                const SizedBox(width: 12),
                Expanded(
                    child: _PrimaryButton(
                        label: 'Check again',
                        onTap: () {
                          _pollTicks = 0;
                          _startPolling();
                          setState(() {});
                        })),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _successView() => ConstrainedBox(
    key: const ValueKey('success'),
    constraints: const BoxConstraints(minHeight: _statusMinHeight),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [_kTeal, _kAccent]),
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
            ),
          ),
          const SizedBox(height: 22),
          Text(widget.coinMode ? 'Gift sent' : 'Payment successful',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800), textAlign: TextAlign.center,),
          const SizedBox(height: 8),
          Text(widget.coinMode ? _coins(widget.coinCost) : _money(widget.amount),
              style: GoogleFonts.inter(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center,),
        ],
      ),
    ),
  );

  Widget _failedView() => ConstrainedBox(
    key: const ValueKey('failed'),
    constraints: const BoxConstraints(minHeight: _statusMinHeight),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: Colors.redAccent.withOpacity(0.14)),
            child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 40),
          ),
          const SizedBox(height: 18),
          Text('Payment not completed',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(_error ?? 'Something went wrong. Please try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 13.5, height: 1.5)),
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(
                child: _GhostButton(
                    label: 'Close', onTap: () => _close(false))),
            const SizedBox(width: 12),
            Expanded(child: _PrimaryButton(label: 'Try again', onTap: _retry)),
          ]),
        ],
      ),
    ),
  );

  // ₦ with thousands separators; no decimals for whole amounts.
  String _money(double v) {
    final whole = v.truncateToDouble() == v;
    final s = v
        .toStringAsFixed(whole ? 0 : 2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return '₦$s';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selectable method card — radio-style with brand badge, selected ring, and a
// disabled (insufficient) state. Big tap target + Semantics for accessibility.
// ─────────────────────────────────────────────────────────────────────────────
class _MethodCard extends StatelessWidget {
  final Widget brand;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;
  const _MethodCard({
    required this.brand,
    required this.title,
    required this.subtitle,
    required this.selected,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ring = selected ? _kAccent : Colors.white.withOpacity(0.07);
    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      label: '$title. $subtitle',
      child: Opacity(
        opacity: disabled ? 0.55 : 1,
        child: Material(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              constraints: const BoxConstraints(minHeight: 66),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: ring, width: selected ? 1.6 : 1),
              ),
              child: Row(children: [
                brand,
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              color: disabled
                                  ? Colors.orangeAccent.shade100
                                  : Colors.white54,
                              fontSize: 12.5)),
                    ],
                  ),
                ),
                // Radio indicator.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected ? _kAccent : Colors.white30, width: 2),
                    color: selected ? _kAccent : Colors.transparent,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.black)
                      : null,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// Brand badge — tries a bundled logo asset, falls back to a styled icon chip so
// the sheet looks right even before you add the PNGs to pubspec assets.
class _BrandBadge extends StatelessWidget {
  final String asset;
  final IconData fallbackIcon;
  final Color fallbackBg;
  const _BrandBadge({
    required this.asset,
    required this.fallbackIcon,
    required this.fallbackBg,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              color: fallbackBg.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(fallbackIcon, color: fallbackBg, size: 22),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.icon, this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kButtonColor,
          disabledBackgroundColor: kButtonColor.withOpacity(0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: Colors.black), const SizedBox(width: 8)],
            Text(label,
                style: GoogleFonts.inter(
                    color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fallback in-app WebView (only used if the OPay app / browser can't be opened
// externally). Closing it always returns to the sheet, which then VERIFIES with
// the backend — the redirect is never trusted as success.
// ─────────────────────────────────────────────────────────────────────────────
class _OpayWebViewPage extends StatefulWidget {
  final String cashierUrl;
  final String returnUrlPrefix;
  const _OpayWebViewPage({required this.cashierUrl, required this.returnUrlPrefix});
  @override
  State<_OpayWebViewPage> createState() => _OpayWebViewPageState();
}

class _OpayWebViewPageState extends State<_OpayWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_kBg)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          if (_isReturn(url)) _close();
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onNavigationRequest: (req) {
          // Non-http schemes (opay://, intent://, market://) → hand to the OS so
          // the OPay app opens, and keep the WebView where it is.
          final u = req.url;
          if (!u.startsWith('http')) {
            launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication)
                .catchError((_) => false);
            return NavigationDecision.prevent;
          }
          if (_isReturn(u)) {
            _close();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.cashierUrl));
  }

  bool _isReturn(String url) => url.startsWith(widget.returnUrlPrefix);
  void _close() {
    if (_closed) return;
    _closed = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text('OPay',
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          tooltip: 'Close',
          onPressed: _close, // closing still triggers backend verification
        ),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 3)),
      ]),
    );
  }
}