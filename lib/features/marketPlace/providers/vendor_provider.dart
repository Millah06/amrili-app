import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';
import '../../../core/pagination/cursor_page.dart';
import '../models/order_model.dart';
import '../models/vendor_model.dart';

// ─── VendorListProvider ───────────────────────────────────────────────────────

// class VendorListProvider extends ChangeNotifier {
//   final ApiService api;
//   VendorListProvider({required this.api});
//
//   List<VendorModel> vendors = [];
//   bool loading = false;
//   String? error;
//   String? selectedVendorType;
//   String? selectedState;
//   String? selectedLga;
//   String sortBy = 'rating';
//   String search = '';
//
//   Future<void> fetchVendors() async {
//     loading = true;
//     error = null;
//     notifyListeners();
//     try {
//       final query = <String, String>{
//         'sortBy': sortBy,
//         if (selectedVendorType != null) 'vendorType': selectedVendorType!,
//         if (selectedState != null) 'state': selectedState!,
//         if (selectedLga != null) 'lga': selectedLga!,
//         if (search.isNotEmpty) 'search': search,
//       };
//       final data = await api.get('/vendor/list', query: query) as List;
//       vendors = data.map((v) => VendorModel.fromJson(v)).toList();
//       print(vendors);
//     } catch (e) {
//       print(e);
//       error = e.toString();
//     } finally {
//       loading = false;
//       notifyListeners();
//     }
//   }
//
//   void setVendorType(String? type) {
//     selectedVendorType = type;
//     fetchVendors();
//   }
//
//   void setState(String? state) {
//     selectedState = state;
//     selectedLga = null;
//     fetchVendors();
//   }
//
//   void setLga(String? lga) {
//     selectedLga = lga;
//     fetchVendors();
//   }
//
//   void setSortBy(String sort) {
//     sortBy = sort;
//     fetchVendors();
//   }
//
//   void setSearch(String q) {
//     search = q;
//     fetchVendors();
//   }
//
//   void clearTypeFilter () {}
// }

// ─── VendorDetailProvider ─────────────────────────────────────────────────────

class VendorListProvider extends ChangeNotifier {
  final ApiService api;
  VendorListProvider({required this.api});

  // ── List state ──────────────────────────────────────────────────────────
  List<VendorModel> vendors = [];
  bool loading = false;       // first page / refresh (drives the skeleton)
  bool loadingMore = false;   // bottom "load more" spinner
  bool hasMore = true;        // is there another page after what we have?
  bool hasLoadedOnce = false; // distinguishes "not fetched yet" from "empty"
  String? error;

  String? _nextCursor;        // opaque token for the next page

  // ── Filters ─────────────────────────────────────────────────────────────
  String? selectedVendorType;
  String? selectedState;
  String? selectedLga;
  String sortBy = 'rating';
  String search = '';

  static const int _pageSize = 20;

  Timer? _searchDebounce;

  /// The filter/sort query shared by the first page and every subsequent page.
  Map<String, String> _baseQuery() => {
    'sortBy': sortBy,
    'limit': '$_pageSize',
    if (selectedVendorType != null) 'vendorType': selectedVendorType!,
    if (selectedState != null) 'state': selectedState!,
    if (selectedLga != null) 'lga': selectedLga!,
    if (search.isNotEmpty) 'search': search,
  };

  /// Load page 1. Called on init and whenever a filter/sort/search changes.
  /// Resets the cursor so we never mix pages from different filters.
  Future<void> refresh() async {
    loading = true;
    error = null;
    _nextCursor = null;
    hasMore = true;
    notifyListeners();
    try {
      final res = await api.get('/vendor/list', query: _baseQuery());
      final page = CursorPage.fromJson(res, (j) => VendorModel.fromJson(j));
      vendors = page.items;
      _nextCursor = page.nextCursor;
      hasMore = page.hasMore;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      hasLoadedOnce = true;
      notifyListeners();
    }
  }

  /// Load the next page and append. No-op while busy, out of pages, or cursorless.
  Future<void> fetchMore() async {
    if (loadingMore || loading || !hasMore || _nextCursor == null) return;
    loadingMore = true;
    notifyListeners();
    try {
      final res = await api.get(
        '/vendor/list',
        query: {..._baseQuery(), 'cursor': _nextCursor!},
      );
      final page = CursorPage.fromJson(res, (j) => VendorModel.fromJson(j));
      vendors = [...vendors, ...page.items];
      _nextCursor = page.nextCursor;
      hasMore = page.hasMore;
    } catch (e) {
      error = e.toString();
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  // ── Filter setters (each resets to page 1) ───────────────────────────────
  void setVendorType(String? type) {
    selectedVendorType = type;
    refresh();
  }

  void setState(String? state) {
    selectedState = state;
    selectedLga = null;
    refresh();
  }

  void setLga(String? lga) {
    selectedLga = lga;
    refresh();
  }

  void setSortBy(String sort) {
    sortBy = sort;
    refresh();
  }

  /// Debounced so typing doesn't fire a request per keystroke (cost + jank).
  void setSearch(String q) {
    search = q;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), refresh);
  }

  void clearTypeFilter() {}

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

class VendorDetailProvider extends ChangeNotifier {
  final ApiService api;
  VendorDetailProvider({required this.api});

  VendorModel? vendor;
  Map<String, List<MenuItemModel>> branchMenus = {};
  List<MenuItemModel> menuItems = [];
  String? selectedBranchId;
  bool loading = false;
  String? error;
  bool isBranchLoading = false;

  BranchModel? get selectedBranch {
    if (vendor == null || selectedBranchId == null) return null;
    return vendor!.branches.firstWhere(
          (b) => b.id == selectedBranchId,
      orElse: () => vendor!.branches.first,
    );
  }

  Future<void> loadVendor(String vendorId, {VendorModel? seed}) async {
    loading = true;
    error = null;

    branchMenus.clear();

    // Optimistic seed from the list: render the header immediately and clear any
    // stale vendor when there's no seed (scan/deep-link → skeleton shows).
    vendor = seed;
    if (seed != null && seed.branches.isNotEmpty) {
      selectedBranchId = seed.branches.first.id;
    }

    notifyListeners();

    try {
      final data = await api.get('/vendor/$vendorId');
      vendor = VendorModel.fromJson(data);
      if (vendor!.branches.isNotEmpty) {
        selectedBranchId = vendor!.branches.first.id;
        await fetchMenu(selectedBranchId!);
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectBranch(String branchId) async {
    selectedBranchId = branchId;
    if (branchMenus.containsKey(branchId)) {
      menuItems = branchMenus[branchId]!;
    }

    isBranchLoading = true;
    notifyListeners();

    await fetchMenu(branchId);

    isBranchLoading = false;
    notifyListeners();
  }

  Future<void> fetchMenu(String branchId) async {
    if (branchMenus.containsKey(branchId)) {
      menuItems = branchMenus[branchId]!;
      notifyListeners();
      return;
    }
    try {
      final data = await api.get('/branch/$branchId/menu') as List;
      final items = data.map((m) => MenuItemModel.fromJson(m)).toList();

      branchMenus[branchId] = items;
      menuItems = items;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}

// ─── CartProvider ─────────────────────────────────────────────────────────────

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String? vendorId;
  String? branchId;
  bool vendorAllowsPod = false;

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get totalItems => _items.fold(0, (s, i) => s + i.quantity);
  double get subtotal => _items.fold(0, (s, i) => s + i.total);

  int quantityOf(String menuItemId) =>
      _items.where((i) => i.menuItem.id == menuItemId).firstOrNull?.quantity ?? 0;

  void add(MenuItemModel item, String vId, String bId, bool allowsPod) {
    if (vendorId != null && (vendorId != vId || branchId != bId)) {
      _items.clear();
    }
    vendorId = vId;
    branchId = bId;
    vendorAllowsPod = allowsPod;
    final existing = _items.where((i) => i.menuItem.id == item.id).firstOrNull;
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(CartItem(menuItem: item));
    }
    notifyListeners();
  }

  void decrement(String menuItemId) {
    final item = _items.where((i) => i.menuItem.id == menuItemId).firstOrNull;
    if (item == null) return;
    if (item.quantity <= 1) {
      _items.removeWhere((i) => i.menuItem.id == menuItemId);
      if (_items.isEmpty) { vendorId = null; branchId = null; }
    } else {
      item.quantity--;
    }
    notifyListeners();
  }

  void remove(String menuItemId) {
    _items.removeWhere((i) => i.menuItem.id == menuItemId);
    if (_items.isEmpty) { vendorId = null; branchId = null; }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    vendorId = null;
    branchId = null;
    vendorAllowsPod = false;
    notifyListeners();
  }
}