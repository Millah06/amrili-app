
import '../../features/marketPlace/models/vendor_model.dart';

import '../api_service.dart';

// ─── VENDOR REPOSITORY ────────────────────────────────────────────────────────

class VendorRepository {
  final ApiService api;
  VendorRepository({required this.api});

  Future<List<VendorModel>> fetchVendors({
    String? vendorType,
    String? state,
    String? lga,
    String? search,
    String sortBy = 'rating', // rating | completionRate | totalCompletedOrders
  }) async {
    final query = <String, String>{
      'sortBy': sortBy,
      if (vendorType != null) 'vendorType': vendorType,
      if (state != null) 'state': state,
      if (lga != null) 'lga': lga,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final data = await api.get('/vendors', query: query) as List;
    final vendors = data.map((v) => VendorModel.fromJson(v)).toList();
    return _rankVendors(vendors, sortBy);
  }

  // Ranking algorithm: weighted composite score
  List<VendorModel> _rankVendors(List<VendorModel> vendors, String sortBy) {
    return vendors..sort((a, b) {
      switch (sortBy) {
        case 'completionRate':
          return b.completionRate.compareTo(a.completionRate);
        case 'totalCompletedOrders':
          return b.totalCompletedOrders.compareTo(a.totalCompletedOrders);
        case 'rating':
        default:
        // Composite: 50% rating + 30% completionRate + 20% orders (normalized)
          final scoreA = (a.rating / 5) * 0.5 +
              (a.completionRate / 100) * 0.3 +
              (a.totalCompletedOrders / 1000).clamp(0, 1) * 0.2;
          final scoreB = (b.rating / 5) * 0.5 +
              (b.completionRate / 100) * 0.3 +
              (b.totalCompletedOrders / 1000).clamp(0, 1) * 0.2;
          return scoreB.compareTo(scoreA);
      }
    });
  }

  Future<VendorModel> fetchVendorById(String vendorId) async {
    final data = await api.get('/vendors/$vendorId');
    return VendorModel.fromJson(data);
  }

  Future<List<MenuItemModel>> fetchMenuItems(String branchId) async {
    final data = await api.get('/branches/$branchId/menu') as List;
    return data.map((m) => MenuItemModel.fromJson(m)).toList();
  }

  Future<List<DeliveryZoneModel>> fetchDeliveryZones(String branchId) async {
    final data = await api.get('/branches/$branchId/delivery-zones') as List;
    return data.map((z) => DeliveryZoneModel.fromJson(z)).toList();
  }

  Future<Map<String, dynamic>> fetchLocationHierarchy() async {
    return await api.get('/locations/hierarchy');
  }

  Future<VendorModel?> fetchMyVendorProfile() async {
    try {
      final data = await api.get('/vendors/me');
      return VendorModel.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ─── Vendor Center ───────────────────────────────────────────────────────────

  Future<MenuItemModel> addMenuItem(
      String branchId, Map<String, dynamic> item) async {
    final data = await api.post('/branches/$branchId/menu', item);
    return MenuItemModel.fromJson(data);
  }

  Future<MenuItemModel> updateMenuItem(
      String itemId, Map<String, dynamic> updates) async {
    final data = await api.put('/menu/$itemId', updates);
    return MenuItemModel.fromJson(data);
  }

  Future<void> deleteMenuItem(String itemId) async {
    await api.delete('/menu/$itemId');
  }

  Future<BranchModel> addBranch(Map<String, dynamic> branch) async {
    final data = await api.post('/branches', branch);
    return BranchModel.fromJson(data);
  }

  Future<BranchModel> updateBranch(
      String branchId, Map<String, dynamic> updates) async {
    final data = await api.put('/branches/$branchId', updates);
    return BranchModel.fromJson(data);
  }

  Future<void> deleteBranch(String branchId) async {
    await api.delete('/branches/$branchId');
  }

  Future<DeliveryZoneModel> addDeliveryZone(
      String branchId, Map<String, dynamic> zone) async {
    final data = await api.post('/branches/$branchId/delivery-zones', zone);
    return DeliveryZoneModel.fromJson(data);
  }

  Future<Map<String, dynamic>> fetchVendorMetrics() async {
    return await api.get('/vendors/me/metrics');
  }

  Future<void> applyAsVendor(Map<String, dynamic> application) async {
    await api.post('/vendors/apply', application);
  }
}