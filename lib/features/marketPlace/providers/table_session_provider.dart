// lib/features/marketPlace/providers/table_session_provider.dart
//
// PHASE 7 — DINE-IN
//
// Holds the "I am sitting at table X of store Y" session for the current
// browsing flow. It is deliberately ephemeral (in-memory, not persisted): a
// dine-in session is meaningful only while the customer is actually in the
// store on this screen. It clears when they place an order or leave the store —
// so a stale table never silently rides along to an unrelated checkout.
//
// Lifecycle:
//   • A table QR scan / deep link → /store/:vendorId/table/:tableId →
//     VendorDetailPage calls attachTable(vendorId, tableId).
//   • attachTable() fetches the public table read, VERIFIES the table belongs
//     to the store being viewed (storeId match — guards against a QR for one
//     store opening inside another), and stores tableNumber + branchId.
//   • Checkout reads isDineIn / tableId / tableNumber / branchId.
//   • clear() is called after a successful order and when leaving the store.
//
import 'package:flutter/foundation.dart';
import '../services/table_api_services.dart';

class TableSessionProvider extends ChangeNotifier {
  final TablesApiService _api;
  TableSessionProvider({TablesApiService? api})
      : _api = api ?? TablesApiService();

  String? _storeId; // vendorId this session is bound to
  String? _tableId;
  String? _tableNumber; // human label, e.g. "5"
  String? _branchId; // resolved from the table — checkout needs it

  bool _attaching = false;
  String? _error;

  // ── Public state ──────────────────────────────────────────────────────────
  bool get isDineIn => _tableId != null;
  String? get storeId => _storeId;
  String? get tableId => _tableId;
  String? get tableNumber => _tableNumber;
  String? get branchId => _branchId;
  bool get attaching => _attaching;
  String? get error => _error;

  /// True when an existing session is for a DIFFERENT store than [vendorId].
  /// Used to decide whether to clear before attaching a new store's table.
  bool isForOtherStore(String vendorId) =>
      _storeId != null && _storeId != vendorId;

  /// Attach a dine-in session for [tableId] under [vendorId].
  ///
  /// Returns true on success. Fetches the public table read to resolve the
  /// table number + branch, and enforces the store-match guard. On any failure
  /// the session is left CLEARED (we never half-attach), and [error] is set.
  Future<bool> attachTable({
    required String vendorId,
    required String tableId,
  }) async {
    // Idempotent: re-attaching the same table is a no-op (avoids refetch churn
    // when VendorDetailPage rebuilds).
    if (_tableId == tableId && _storeId == vendorId) return true;

    _attaching = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getTablePublic(
        vendorId: vendorId,
        tableId: tableId,
      );
      final table = data['table'] as Map<String, dynamic>;

      // STORE-MATCH GUARD: the table's vendor must equal the store we opened
      // it under. Protects against a mismatched/spoofed link.
      final tableVendorId = table['vendorId'] as String?;
      if (tableVendorId != vendorId) {
        _clearInternal();
        _error = 'This table belongs to a different store.';
        _attaching = false;
        notifyListeners();
        return false;
      }

      _storeId = vendorId;
      _tableId = tableId;
      _tableNumber = (table['tableNumber'] ?? '').toString();
      _branchId = table['branchId'] as String?;
      _attaching = false;
      notifyListeners();
      return true;
    } catch (_) {
      _clearInternal();
      _error = 'This table isn’t available right now.';
      _attaching = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear the session (after order placed, or on leaving the store).
  void clear() {
    if (_storeId == null && _tableId == null) return;
    _clearInternal();
    notifyListeners();
  }

  /// Clear only if the bound store differs from [vendorId]. Called when opening
  /// a store normally (no table) so a lingering dine-in session from another
  /// store doesn't leak in.
  void clearIfOtherStore(String vendorId) {
    if (isForOtherStore(vendorId)) clear();
  }

  void _clearInternal() {
    _storeId = null;
    _tableId = null;
    _tableNumber = null;
    _branchId = null;
    _error = null;
  }
}