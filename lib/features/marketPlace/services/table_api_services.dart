// lib/services/tables_api_service.dart
//
// PHASE 7 — DINE-IN
//
// HTTP for dine-in tables, built on the shared `ApiService` (it handles base URL,
// the Bearer token, and response decoding). Two surfaces:
//   • PUBLIC  — getTablePublic() uses optionalHeader:true so a guest who scans a
//     table QR can attach a session and browse with no account.
//   • MERCHANT — create/list/update/delete are authed (default headers).
//
import '../../../services/api_service.dart';
import '../models/restaurant_table_model.dart';

class TablesApiService {
  final ApiService _api = ApiService();

  // ── PUBLIC: dine-in landing read (guests allowed) ─────────────────────────
  // Returns { table:{...}, store:{...}, items:[...] }.
  Future<Map<String, dynamic>> getTablePublic({
    required String vendorId,
    required String tableId,
  }) async {
    final data = await _api.get(
      '/web/store/$vendorId/table/$tableId',
      optionalHeader: true,
    );
    return Map<String, dynamic>.from(data as Map);
  }

  // ── MERCHANT: list tables for a branch ────────────────────────────────────
  Future<List<RestaurantTableModel>> listTables({
    required String vendorId,
    required String branchId,
  }) async {
    final data = await _api.get('/tables/$vendorId/$branchId');
    return (data as List)
        .map((e) => RestaurantTableModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ── MERCHANT: create a table ──────────────────────────────────────────────
  Future<RestaurantTableModel> createTable({
    required String branchId,
    required String tableNumber,
    int capacity = 4,
  }) async {
    final data = await _api.post('/tables/create', {
      'branchId': branchId,
      'tableNumber': tableNumber,
      'capacity': capacity,
    });
    return RestaurantTableModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ── MERCHANT: update (rename / capacity / active toggle) ──────────────────
  Future<RestaurantTableModel> updateTable({
    required String tableId,
    String? tableNumber,
    int? capacity,
    bool? isActive,
  }) async {
    final data = await _api.put('/tables/$tableId', {
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (capacity != null) 'capacity': capacity,
      if (isActive != null) 'isActive': isActive,
    });
    return RestaurantTableModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ── MERCHANT: delete (server blocks if active orders) ─────────────────────
  Future<void> deleteTable(String tableId) async {
    await _api.delete('/tables/$tableId');
  }
}