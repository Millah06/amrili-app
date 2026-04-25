import 'package:flutter/foundation.dart';
import 'package:everywhere/models/transaction_model.dart';

import '../services/transaction.dart';

/// Manages all transaction state for the app.
///
/// Register in your MultiProvider:
/// ```dart
/// ChangeNotifierProvider(create: (_) => TransactionProvider()..loadInitial()),
/// ```
class TransactionProvider extends ChangeNotifier {
  final _service = TransactionService();

  // ── State ──────────────────────────────────────────────────────────────────
  List<TransactionModel> _transactions = [];
  TransactionModel? _selectedTransaction;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingDetail = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  static const _pageSize = 10;

  // ── Getters ────────────────────────────────────────────────────────────────
  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  TransactionModel? get selectedTransaction => _selectedTransaction;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingDetail => _isLoadingDetail;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isEmpty => _transactions.isEmpty;

  // ── Initial load (call on app start or first open of history screen) ───────
  Future<void> loadInitial() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.fetchTransactions(page: 1, limit: _pageSize);
      _transactions = result.data;
      _page = 1;
      _hasMore = result.hasMore;
    } catch (e) {
      _error = _cleanError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Infinite scroll — call when ScrollController nears the bottom ──────────
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      final next = _page + 1;
      final result = await _service.fetchTransactions(page: next, limit: _pageSize);
      _transactions = [..._transactions, ...result.data];
      _page = next;
      _hasMore = result.hasMore;
    } catch (_) {
      // silent — the user can scroll again to retry
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Pull to refresh ────────────────────────────────────────────────────────
  Future<void> refresh() async {
    _transactions = [];
    _page = 1;
    _hasMore = true;
    _error = null;
    await loadInitial();
  }

  // ── Transaction detail ─────────────────────────────────────────────────────
  Future<void> loadDetail(String id) async {
    // Use cached detail if we already loaded it
    final cached = _transactions.where((t) => t.id == id && t.meta != null).firstOrNull;
    if (cached != null) {
      _selectedTransaction = cached;
      notifyListeners();
      return;
    }

    _isLoadingDetail = true;
    _selectedTransaction = null;
    _error = null;
    notifyListeners();

    try {
      _selectedTransaction = await _service.fetchTransactionDetail(id);
      // Optionally update the list item with the enriched detail
      final idx = _transactions.indexWhere((t) => t.id == id);
      if (idx != -1) _transactions[idx] = _selectedTransaction!;
    } catch (e) {
      _error = _cleanError(e);
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clearDetail() {
    _selectedTransaction = null;
    _error = null;
  }

  // ── Client-side date filter (applied on top of loaded pages) ──────────────
  List<TransactionModel> filtered(String filter) {
    final now = DateTime.now();
    switch (filter) {
      case 'Today':
        return _transactions.where((t) =>
        t.createdAt.year == now.year &&
            t.createdAt.month == now.month &&
            t.createdAt.day == now.day,
        ).toList();
      case 'This Month':
        return _transactions.where((t) =>
        t.createdAt.year == now.year && t.createdAt.month == now.month,
        ).toList();
      case 'This Year':
        return _transactions.where((t) => t.createdAt.year == now.year).toList();
      default:
        return _transactions;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '').replaceFirst('exception: ', '');
}