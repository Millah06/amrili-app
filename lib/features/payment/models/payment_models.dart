// lib/features/payment/models/payment_models.dart
//
// Client-side mirror of the backend payment engine's contract. The Flutter app
// only ever *reads* these — it never decides a payment succeeded. The backend
// (webhook + OPay verify) is the source of truth; the UI reacts to `status`.

/// Mirrors the Prisma `PaymentStatus` enum (string-identical on the wire).
enum PaymentStatus {
  created,
  pending,
  verifying,
  success,
  failed,
  expired,
  refunded,
  unknown;

  static PaymentStatus from(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'CREATED':
        return PaymentStatus.created;
      case 'PENDING':
        return PaymentStatus.pending;
      case 'VERIFYING':
        return PaymentStatus.verifying;
      case 'SUCCESS':
        return PaymentStatus.success;
      case 'FAILED':
        return PaymentStatus.failed;
      case 'EXPIRED':
        return PaymentStatus.expired;
      case 'REFUNDED':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.unknown;
    }
  }

  /// No further polling needed — the backend has reached a final decision.
  bool get isTerminal => const {
    PaymentStatus.success,
    PaymentStatus.failed,
    PaymentStatus.expired,
    PaymentStatus.refunded,
  }.contains(this);

  bool get isInFlight => const {
    PaymentStatus.created,
    PaymentStatus.pending,
    PaymentStatus.verifying,
  }.contains(this);
}

/// Supported providers. New providers slot in here + on the backend without
/// changing the sheet's flow.
enum PaymentProvider {
  wallet,
  opay;

  String get wire => name; // "wallet" | "opay"

  String get label => switch (this) {
    PaymentProvider.wallet => 'Amril Wallet',
    PaymentProvider.opay => 'Card / Bank / OPay',
  };
}

/// The backend `publicPayment(...)` shape.
class PaymentResult {
  final String paymentId;
  final PaymentStatus status;
  final String provider;
  final double amount;
  final String currency;
  final String entityType;
  final String entityId;

  /// Present for OPay — the cashier page to open in a WebView.
  final String? cashierUrl;

  /// Non-null if the money moved but the business handler errored (rare; the
  /// backend auto-refunds wallet in that case). Surfaced for support.
  final String? dispatchError;

  /// Server-provided error message, if any (e.g. "Insufficient wallet balance").
  final String? message;

  /// Utility delivery result (token/PIN/status) for instant receipts.
  /// Shape: { status: 'delivered'|'pending'|'refunded', token, tokens, productName, bonusEarned }.
  final Map<String, dynamic>? delivery;

  const PaymentResult({
    required this.paymentId,
    required this.status,
    required this.provider,
    required this.amount,
    required this.currency,
    required this.entityType,
    required this.entityId,
    this.cashierUrl,
    this.dispatchError,
    this.message,
    this.delivery,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> j) => PaymentResult(
    paymentId: j['paymentId'] ?? j['id'] ?? '',
    status: PaymentStatus.from(j['status']),
    provider: j['provider'] ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
    currency: j['currency'] ?? 'NGN',
    entityType: j['entityType'] ?? '',
    entityId: j['entityId'] ?? '',
    cashierUrl: j['cashierUrl'],
    dispatchError: j['dispatchError'],
    message: j['message'],
    delivery: j['delivery'] == null
        ? null
        : Map<String, dynamic>.from(j['delivery'] as Map),
  );
}