import 'dart:convert';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TransactionMeta
// Wraps the raw metaData JSON from the backend.
// Add typed accessors here as your categories grow — never change the consumer
// widgets, just add a new getter.
// ─────────────────────────────────────────────────────────────────────────────
class TransactionMeta {
  final Map<String, dynamic> raw;
  const TransactionMeta(this.raw);

  // ── Common typed accessors ─────────────────────────────────────────────────
  String? get productName      => _s('productName');
  String? get businessName     => _s('Business Name') ?? _s('businessName');
  String? get network          => _s('network');
  String? get phone            => _s('phone');
  String? get meterNumber      => _s('meterNumber');
  String? get token            => _s('token');
  String? get schoolName       => _s('School Name') ?? _s('schoolName');
  String? get bonusEarned      => _s('Bonus Earned') ?? _s('bonusEarned');
  String? get recipientName    => _s('recipientName');
  String? get recipientBank    => _s('recipientBank');
  String? get recipientAccount => _s('recipientAccount');
  String? get numberOfCards    => _s('numberOfCards');
  String? get numberOfStudents => _s('Number Of Student') ?? _s('numberOfStudents');
  String? get actualAmount     => _s('Actual Amount') ?? _s('actualAmount');

  // ── Bulk data fields ───────────────────────────────────────────────────────
  List<String>? get pins   => _strList('pins');
  List<String>? get serial => _strList('serial');

  List<String>? get waecRegistrationTokens {
    final v = raw['waec_registration-tokens'];
    if (v == null) return null;
    if (v is String) {
      try { return (jsonDecode(v) as List).map((e) => '$e').toList(); }
      catch (_) { return null; }
    }
    return (v as List).map((e) => '$e').toList();
  }

  List<Map<String, dynamic>>? get waecResultCards {
    final v = raw['waec_result_cards'];
    if (v == null) return null;
    if (v is String) {
      try { return (jsonDecode(v) as List).cast<Map<String, dynamic>>(); }
      catch (_) { return null; }
    }
    return (v as List).cast<Map<String, dynamic>>();
  }

  // ── Display helpers ────────────────────────────────────────────────────────

  /// Keys excluded from the generic key-value display section.
  static const _alwaysHidden = {
    'pins', 'serial',
    'waec_registration-tokens', 'waec_result_cards',
    'request_id', 'requestId',
  };

  /// Filtered, display-ready key-value pairs.
  Map<String, String> get displayFields => Map.fromEntries(
    raw.entries
        .where((e) => !_alwaysHidden.contains(e.key) && e.value != null)
        .map((e) => MapEntry(e.key, e.value.toString())),
  );

  // ── Privates ───────────────────────────────────────────────────────────────
  String? _s(String k) => raw[k]?.toString();

  List<String>? _strList(String k) {
    final v = raw[k];
    if (v == null) return null;
    return (v as List).map((e) => '$e').toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TransactionModel
// ─────────────────────────────────────────────────────────────────────────────
class TransactionModel {
  final String id;
  final String type;    // e.g. 'airtime', 'data', 'waec_reg', 'transfer_debit'
  final double amount;
  final String status;  // 'success' | 'failed' | 'pending'
  final String? message;
  final String? transactionRef;
  final String? humanRef;
  final DateTime createdAt;

  /// null for list items; populated after the detail endpoint is called.
  final TransactionMeta? meta;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    this.message,
    this.transactionRef,
    this.humanRef,
    required this.createdAt,
    this.meta,
  });

  // ── Factories ──────────────────────────────────────────────────────────────

  factory TransactionModel.fromListJson(Map<String, dynamic> j) => TransactionModel(
    id:             j['id'] as String,
    type:           (j['type'] as String?)?.toLowerCase() ?? 'unknown',
    amount:         (j['amount'] as num).toDouble(),
    status:         _resolveStatus(j),
    message:        j['message'] as String?,
    transactionRef: j['transactionRef'] as String?,
    humanRef:       j['humanRef'] as String?,
    createdAt:      DateTime.parse(j['createdAt'] as String),
  );

  factory TransactionModel.fromDetailJson(Map<String, dynamic> j) {
    final raw = j['metaData'];
    return TransactionModel(
      id:             j['id'] as String,
      type:           (j['type'] as String?)?.toLowerCase() ?? 'unknown',
      amount:         (j['amount'] as num).toDouble(),
      status:         _resolveStatus(j),
      message:        j['message'] as String?,
      transactionRef: j['transactionRef'] as String?,
      humanRef:       j['humanRef'] as String?,
      createdAt:      DateTime.parse(j['createdAt'] as String),
      meta:           raw != null
          ? TransactionMeta(Map<String, dynamic>.from(raw as Map))
          : null,
    );
  }

  static String _resolveStatus(Map<String, dynamic> j) =>
      (j['transactionStatus'] ?? j['status'] ?? 'pending').toString().toLowerCase();

  // ── Derived display properties ─────────────────────────────────────────────

  /// Human-readable label. Prefers metaData product names over type-based defaults.
  String get displayLabel {
    if (meta?.productName != null) return meta!.productName!;
    if (meta?.businessName != null) return meta!.businessName!;
    switch (type) {
      case 'airtime':           return 'Airtime Top-Up';
      case 'data':              return 'Data Bundle';
      case 'electricity':       return 'Electricity';
      case 'cable':             return 'Cable TV';
      case 'waec_reg':          return 'WAEC Registration';
      case 'waec_result':       return 'WAEC Result';
      case 'transfer_debit':    return 'Transfer Sent';
      case 'transfer_credit':   return 'Transfer Received';
      case 'wallet_funding':    return 'Wallet Funded';
      case 'order_payment':     return 'Order Payment';
      case 'wallet_withdrawal': return 'Wallet Withdrawal';
      case 'order_refund':      return 'Order Refund';
      case 'gift':              return 'Gift Card';
      default:
        return type.replaceAll('_', ' ').split(' ').map((w) =>
        w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}',
        ).join(' ');
    }
  }

  bool get isCredit => type == 'transfer_credit' ||
      type == 'wallet_funding'   ||
      type == 'order_refund';
  bool get isSuccess => status == 'success';
  bool get isFailed  => status == 'failed';
  bool get isPending => status == 'pending';

  Color get statusColor {
    if (isSuccess) return const Color(0xFF22C55E);
    if (isFailed)  return const Color(0xFFEF4444);
    return const Color(0xFFF59E0B);
  }

  String get statusLabel => status[0].toUpperCase() + status.substring(1);

  /// The visible reference shown on receipts (human-readable if available).
  String get displayRef => humanRef ?? transactionRef ?? id;
}

// ─────────────────────────────────────────────────────────────────────────────
// PaginatedTransactions
// ─────────────────────────────────────────────────────────────────────────────
class PaginatedTransactions {
  final List<TransactionModel> data;
  final int total;
  final int page;
  final int pages;

  const PaginatedTransactions({
    required this.data,
    required this.total,
    required this.page,
    required this.pages,
  });

  factory PaginatedTransactions.fromJson(Map<String, dynamic> j) {
    final m = j['meta'] as Map<String, dynamic>;
    return PaginatedTransactions(
      data:  (j['data'] as List)
          .map((e) => TransactionModel.fromListJson(e as Map<String, dynamic>))
          .toList(),
      total: m['total'] as int,
      page:  m['page'] as int,
      pages: m['pages'] as int,
    );
  }

  bool get hasMore => page < pages;
}