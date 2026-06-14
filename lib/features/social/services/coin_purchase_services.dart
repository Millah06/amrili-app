// lib/features/social/services/coin_purchase_service.dart
//
// PHASE 10 — the NON-NG coin funding rail (Apple App Store / Google Play).
//
// This wraps the `in_app_purchase` plugin so the UI never deals with store
// plumbing. The flow:
//   1. queryProducts(ids)  — ask the store for our coin packs. The store returns
//      each product with a LOCALIZED price string ("$4.99", "€4,99", "¥30") — we
//      display that exactly; we never compute currency ourselves.
//   2. buy(product)        — launch the native purchase sheet.
//   3. purchaseStream      — when the store confirms, we send the receipt/token
//      to our backend (/coins/purchase/iap) which verifies it and mints PURCHASED
//      coins, then we completePurchase() so the store stops re-delivering it.
//
// IMPORTANT: coins are granted by the BACKEND after verification, never by the
// client. The store only proves the money was paid.
//
// Requires `in_app_purchase: ^3.2.0` in pubspec (added in this phase) and the
// six consumable products registered in App Store Connect / Play Console with
// IDs matching `coinProductIds` below.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'social_api_service.dart';

/// Store SKUs — must EXACTLY match the products you register in both consoles
/// and the backend `COIN_PACKS`. The number after the last dot is the coin count.
const Set<String> coinProductIds = {
  'com.amril.app.coins.100',
  'com.amril.app.coins.500',
  'com.amril.app.coins.1000',
  'com.amril.app.coins.2500',
  'com.amril.app.coins.5000',
  'com.amril.app.coins.10000',
};

/// How many coins a product grants (client-side, for display only; the backend
/// is authoritative). Parsed from the SKU suffix so it can never drift.
int coinsForProduct(String productId) =>
    int.tryParse(productId.split('.').last) ?? 0;

class CoinPurchaseService {
  CoinPurchaseService._();
  static final CoinPurchaseService instance = CoinPurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  final SocialApiService _api = SocialApiService();

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _initialized = false;

  /// Called by the UI when a purchase finishes verifying on our backend.
  /// (productId, success)
  void Function(String productId, bool success)? onDelivered;

  /// True if the device can do IAP at all (e.g. false on web / unsupported).
  Future<bool> get isAvailable => _iap.isAvailable();

  /// Start listening to the purchase stream. Safe to call once (e.g. on the buy
  /// screen's initState). The stream fires for new buys AND for pending/restored
  /// purchases the OS hands us on launch.
  void init() {
    if (_initialized) return;
    _initialized = true;
    _sub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _initialized = false;
  }

  /// Ask the store for our coin packs, sorted by coin amount ascending.
  Future<List<ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails(coinProductIds);
    final products = response.productDetails.toList()
      ..sort((a, b) => coinsForProduct(a.id).compareTo(coinsForProduct(b.id)));
    return products;
  }

  /// Launch the native purchase. Coins are consumable, so use buyConsumable.
  Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  // ── Purchase stream handler ────────────────────────────────────────────────
  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      switch (p.status) {
        case PurchaseStatus.pending:
        // UI may show a spinner; nothing to do here.
          break;
        case PurchaseStatus.error:
          debugPrint('IAP error: ${p.error}');
          onDelivered?.call(p.productID, false);
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final ok = await _verifyOnBackend(p);
          onDelivered?.call(p.productID, ok);
          // Always complete so the store stops re-delivering; if our backend was
          // briefly down the client can re-trigger restorePurchases() later.
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          break;
        case PurchaseStatus.canceled:
          onDelivered?.call(p.productID, false);
          if (p.pendingCompletePurchase) await _iap.completePurchase(p);
          break;
      }
    }
  }

  /// Send the store receipt/token to the backend, which verifies + mints coins.
  Future<bool> _verifyOnBackend(PurchaseDetails p) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'apple' : 'google';
      // Apple: the base64 server-verification data. Google: the purchase token.
      final token = p.verificationData.serverVerificationData;
      final res = await _api.verifyIapPurchase(
        platform: platform,
        productId: p.productID,
        token: token,
      );
      return res['success'] == true;
    } catch (e) {
      debugPrint('IAP backend verify failed: $e');
      return false; // store keeps the purchase pending → can retry via restore
    }
  }

  /// Re-deliver any owned-but-unverified purchases (e.g. backend was down).
  Future<void> restore() => _iap.restorePurchases();
}