// lib/features/payment/services/payment_service.dart
//
// Thin client for the backend payment engine. Uses the existing `ApiService`
// (http, Firebase-bearer auth, base url https://api.amril.app) so auth and
// error handling match the rest of the app. ApiService throws
// `Exception(body['message'])` on non-2xx, which the sheet catches.

import 'package:everywhere/services/api_service.dart';
import 'package:uuid/uuid.dart';

import '../models/payment_models.dart';

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  final _api = ApiService();
  static const _uuid = Uuid();

  /// Generate a fresh idempotency key for one payment attempt. Keep the SAME
  /// key across retries of the *same* logical payment so the backend dedupes.
  String newClientRequestId() => _uuid.v4();

  /// Create a payment. For OPay this returns PENDING + a `cashierUrl`; for
  /// wallet it executes inline and returns SUCCESS (or FAILED on funds).
  Future<PaymentResult> create({
    required PaymentProvider provider,
    required double amount,
    required String entityType,
    required String entityId,
    required String clientRequestId,
    String? productName,
    String? returnUrl,
    Map<String, dynamic>? meta,
  }) async {
    final res = await _api.post('/payment/create', {
      'provider': provider.wire,
      'amount': amount,
      'entityType': entityType,
      'entityId': entityId,
      'clientRequestId': clientRequestId,
      if (productName != null) 'productName': productName,
      if (returnUrl != null) 'returnUrl': returnUrl,
      if (meta != null) 'meta': meta,
    });
    print(res);
    return PaymentResult.fromJson(Map<String, dynamic>.from(res));
  }

  /// Wallet payment path. The PIN must already be verified client-side (the
  /// caller shows `TransactionPin` first) — this mirrors every other wallet
  /// action in the app, where `/auth/verify-pin` gates the action call.
  Future<PaymentResult> payWithWallet({
    required double amount,
    required String entityType,
    required String entityId,
    required String clientRequestId,
    String? productName,
    Map<String, dynamic>? meta,
  }) async {
    final res = await _api.post('/payment/wallet', {
      'amount': amount,
      'entityType': entityType,
      'entityId': entityId,
      'clientRequestId': clientRequestId,
      if (productName != null) 'productName': productName,
      if (meta != null) 'meta': meta,
    });
    return PaymentResult.fromJson(Map<String, dynamic>.from(res));
  }

  /// Poll a payment's status. For in-flight OPay payments this also nudges the
  /// backend to re-query OPay, so polling alone can resolve a payment even
  /// before the webhook lands.
  Future<PaymentResult> status(String paymentId) async {
    final res = await _api.get('/payment/$paymentId/status');
    return PaymentResult.fromJson(Map<String, dynamic>.from(res));
  }

  /// Unfinished payments for the current user — used for resume-recovery.
  Future<List<PaymentResult>> pending() async {
    final res = await _api.get('/payment/pending');
    final list = (res['data'] as List?) ?? const [];
    return list
        .map((e) => PaymentResult.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}