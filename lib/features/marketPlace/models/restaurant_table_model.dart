// lib/features/marketPlace/models/restaurant_table_model.dart
//
// PHASE 7 — DINE-IN
//
// Plain data model for a dine-in table. Mirrors the backend RestaurantTable.
//
class RestaurantTableModel {
  final String id;
  final String vendorId;
  final String branchId;
  final String tableNumber;
  final int capacity;
  final bool isActive;

  const RestaurantTableModel({
    required this.id,
    required this.vendorId,
    required this.branchId,
    required this.tableNumber,
    required this.capacity,
    required this.isActive,
  });

  factory RestaurantTableModel.fromJson(Map<String, dynamic> j) =>
      RestaurantTableModel(
        id: j['id'] as String,
        vendorId: j['vendorId'] as String,
        branchId: j['branchId'] as String,
        tableNumber: (j['tableNumber'] ?? '').toString(),
        capacity: (j['capacity'] as num?)?.toInt() ?? 4,
        isActive: j['isActive'] as bool? ?? true,
      );
}