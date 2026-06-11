import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/pagination/cursor_page.dart';
import '../../../services/api_service.dart';
import '../models/order_model.dart';



// ─── CheckoutProvider ─────────────────────────────────────────────────────────

// Represents one delivery zone shown as a selectable option
class DeliveryZoneOption {
  final String id;
  final String area;
  final String lga;
  final String state;
  final double deliveryFee;

  const DeliveryZoneOption({
    required this.id,
    required this.area,
    required this.lga,
    required this.state,
    required this.deliveryFee,
  });

  factory DeliveryZoneOption.fromJson(Map<String, dynamic> j) => DeliveryZoneOption(
    id: j['id'],
    area: j['area'],
    lga: j['lga'],
    state: j['state'],
    deliveryFee: (j['deliveryFee'] as num).toDouble(),
  );

  String get label => '$area, $lga';
}

class CheckoutProvider extends ChangeNotifier {
  final ApiService api;
  CheckoutProvider({required this.api});

  // Step 1 — state
  LocationState? selectedState;
  List<LocationState> states = [];

  // Step 2 — lga
  LocationLga? selectedLga;
  List<LocationLga> lgas = [];

  // Step 3 — delivery zone (from branch zones filtered by lga)
  DeliveryZoneOption? selectedZone;
  List<DeliveryZoneOption> availableZones = [];

  bool loadingLocation = false;
  bool loadingZones = false;
  bool placingOrder = false;
  String? error;
  OrderModel? placedOrder;

  double get deliveryFee => selectedZone?.deliveryFee ?? 0;

  // Ready to place order when a zone is selected
  bool  get  canCheckout => selectedZone != null;

  Future<void> loadStates() async {
    loadingLocation = true;
    notifyListeners();
    try {
      final data = await api.get('/location/states') as List;
      states = data.map((s) => LocationState.fromJson(s)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingLocation = false;
      notifyListeners();
    }
  }

  Future<void> pickState(LocationState state) async {
    selectedState = state;
    selectedLga = null;
    selectedZone = null;
    lgas = [];
    availableZones = [];
    notifyListeners();
    try {
      final data = await api.get('/location/lgas/${state.id}') as List;
      lgas = data.map((l) => LocationLga.fromJson(l)).toList();
    } catch (e) {
      error = e.toString();
    }
    notifyListeners();
  }

  Future<void> pickLga(LocationLga lga, String branchId) async {
    selectedLga = lga;
    selectedZone = null;
    availableZones = [];
    loadingZones = true;
    notifyListeners();
    try {
      // Fetch all delivery zones for this branch
      final data = await api.get('/branch/$branchId/delivery-zones') as List;
      // Filter to only zones matching the selected LGA
      availableZones = data
          .map((z) => DeliveryZoneOption.fromJson(z))
          .where((z) => z.lga.toLowerCase() == lga.name.toLowerCase())
          .toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loadingZones = false;
      notifyListeners();
    }
  }

  void pickZone(DeliveryZoneOption zone) {
    selectedZone = zone;
    notifyListeners();
  }

  String paymentMethod = 'prepaid'; // was 'escrow'

  void setPaymentMethod(String method) {
    paymentMethod = method;
    print('the payment method has been set to $method');
    notifyListeners();
  }

  Future<bool> placeOrder({required String vendorId, required String branchId,
    required List<CartItem> items, required String  fulfillmentType, String? tableId, bool isDine = false}) async {
    if (!canCheckout && !isDine) {
      error = 'Please select a delivery zone';
      notifyListeners();
      return false;
    }
    placingOrder = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.post('/order/place', {
        'vendorId': vendorId,
        'branchId': branchId,
        'items': items.map((i) => i.toOrderPayload()).toList(),
        'fulfillmentType':  fulfillmentType,
        if (tableId != null) 'tableId': tableId,
        'deliveryAddress': isDine ? null : {
          'state': selectedZone!.state,
          'lga': selectedZone!.lga,
          'area': selectedZone!.area,
          'street': '',
        },
        'paymentMethod': paymentMethod,
      });
      placedOrder = OrderModel.fromJson(data);
      print(data);
      return true;
    } catch (e) {
      error = e.toString();
      print(e);
      return false;
    } finally {
      placingOrder = false;
      notifyListeners();
    }
  }
  void reset() {
    selectedState = null;
    selectedLga = null;
    selectedZone = null;
    availableZones = [];
    lgas = [];
    placedOrder = null;
    error = null;
    notifyListeners();
  }
}

class OrderListProvider extends ChangeNotifier {
  final ApiService api;
  OrderListProvider({required this.api});

  static const int _pageSize = 20;

  /// Tab order — index-aligned with the TabBar in OrdersTab.
  static const List<String> buckets = [
    'ongoing',
    'completed',
    'cancelled',
    'appealed',
  ];

  final Map<String, _OrderBucket> _b = {
    'ongoing': _OrderBucket(),
    'completed': _OrderBucket(),
    'cancelled': _OrderBucket(),
    'appealed': _OrderBucket(),
  };

  String activeBucket = 'ongoing';
  String? error;

  // ── Backward-compatible getters (used across the orders UI) ──────────────
  List<OrderModel> get ongoing => _b['ongoing']!.items;
  List<OrderModel> get completed => _b['completed']!.items;
  List<OrderModel> get cancelled => _b['cancelled']!.items;
  List<OrderModel> get appealed => _b['appealed']!.items;

  /// All currently-loaded orders across buckets (drives the header count). This
  /// is "loaded", not an absolute total — it grows as the user paginates.
  List<OrderModel> get orders => [for (final k in buckets) ..._b[k]!.items];

  /// Mirrors the active bucket's first-page load.
  bool get loading => _b[activeBucket]!.loading;

  // ── Per-bucket accessors for the tab widgets ─────────────────────────────
  List<OrderModel> itemsFor(String bucket) => _b[bucket]!.items;
  bool loadingFor(String bucket) => _b[bucket]!.loading;
  bool loadingMoreFor(String bucket) => _b[bucket]!.loadingMore;
  bool hasMoreFor(String bucket) => _b[bucket]!.hasMore;
  bool loadedOnceFor(String bucket) => _b[bucket]!.loadedOnce;

  Map<String, String> _query(String bucket, {String? cursor}) => {
    'bucket': bucket,
    'limit': '$_pageSize',
    if (cursor != null) 'cursor': cursor,
  };

  /// Load page 1 of [bucket]. Resets the cursor so pages never mix.
  Future<void> refreshBucket(String bucket) async {
    final b = _b[bucket]!;
    b.loading = true;
    b.cursor = null;
    b.hasMore = true;
    error = null;
    notifyListeners();
    try {
      final res = await api.get('/order/mine', query: _query(bucket));
      final page = CursorPage.fromJson(res, (j) => OrderModel.fromJson(j));
      b.items = page.items;
      b.cursor = page.nextCursor;
      b.hasMore = page.hasMore;
    } catch (e) {
      error = e.toString();
    } finally {
      b.loading = false;
      b.loadedOnce = true;
      notifyListeners();
    }
  }

  /// Append the next page of [bucket].
  Future<void> fetchMoreBucket(String bucket) async {
    final b = _b[bucket]!;
    if (b.loadingMore || b.loading || !b.hasMore || b.cursor == null) return;
    b.loadingMore = true;
    notifyListeners();
    try {
      final res =
      await api.get('/order/mine', query: _query(bucket, cursor: b.cursor));
      final page = CursorPage.fromJson(res, (j) => OrderModel.fromJson(j));
      b.items = [...b.items, ...page.items];
      b.cursor = page.nextCursor;
      b.hasMore = page.hasMore;
    } catch (e) {
      error = e.toString();
    } finally {
      b.loadingMore = false;
      notifyListeners();
    }
  }

  /// Switch tabs: lazy-load the bucket's first page the first time it's shown.
  void setActiveBucket(String bucket) {
    activeBucket = bucket;
    final b = _b[bucket]!;
    if (!b.loadedOnce && !b.loading) {
      refreshBucket(bucket);
    } else {
      notifyListeners();
    }
  }

  /// Initial entry / retry — loads the active bucket (ongoing by default).
  Future<void> fetchOrders() => refreshBucket(activeBucket);

  // ── Order actions (signatures unchanged) ─────────────────────────────────
  // A successful action usually moves the order to a different bucket, so we
  // refresh the active bucket (the item leaves it). The destination bucket
  // refreshes when visited or via the realtime ping.

  Future<bool> confirmDelivery(String orderId) async {
    try {
      await api.post('/order/$orderId/confirm', {});
      await refreshBucket(activeBucket);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> appealOrder(String orderId, String reason) async {
    try {
      await api.post('/order/$orderId/appeal', {'reason': reason});
      await refreshBucket(activeBucket);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelAppeal(String orderId) async {
    try {
      await api.post('/order/$orderId/cancel-appeal', {});
      await refreshBucket(activeBucket);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Called by the counterparty (not the appellant) to concede the appeal.
  Future<bool> concedeAppeal(String orderId) async {
    try {
      await api.post('/order/$orderId/concede-appeal', {});
      await refreshBucket(activeBucket);
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // ── Realtime ping ────────────────────────────────────────────────────────
  StreamSubscription<DocumentSnapshot>? _pingSubscription;

  /// Call once after login with the current user's backend userId. On a ping we
  /// refresh only the active bucket — 1 request, same cost as pre-pagination.
  void watchRealtime(String userId) {
    _pingSubscription?.cancel();
    _pingSubscription = FirebaseFirestore.instance
        .doc('orderPings/$userId')
        .snapshots()
        .skip(1) // skip initial snapshot so we don't double-fetch on startup
        .listen((_) => refreshBucket(activeBucket));
  }

  @override
  void dispose() {
    _pingSubscription?.cancel();
    super.dispose();
  }
}

/// Per-tab pagination state.
class _OrderBucket {
  List<OrderModel> items = [];
  String? cursor;
  bool hasMore = true;
  bool loading = false;
  bool loadingMore = false;
  bool loadedOnce = false;
}

// ─── OrderChatProvider ────────────────────────────────────────────────────────

class OrderChatProvider extends ChangeNotifier {
  final ApiService api;
  OrderChatProvider({required this.api});

  bool sending = false;
  String? error;

  static final _phonePattern = RegExp(r'(\+?\d[\d\s\-]{8,}\d)');
  bool containsPhone(String msg) => _phonePattern.hasMatch(msg);

  Stream<List<ChatMessageModel>> messageStream(String orderId) {
    return FirebaseFirestore.instance
        .collection('orderChats')
        .doc(orderId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) =>
        ChatMessageModel.fromFirestore(d.data(), d.id, orderId))
        .toList());
  }

  Future<bool> sendMessage(String orderId, String message,
      {String? imageUrl}) async {
    if (containsPhone(message)) {
      error = 'Phone numbers not allowed';
      notifyListeners();
      return false;
    }
    sending = true;
    error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{'message': message};
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      await api.post('/chat/$orderId/send', body);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// Convenience: send a bare image with an empty or caption text.
  Future<bool> sendImage(String orderId, String imageUrl,
      {String caption = ''}) =>
      sendMessage(orderId, caption, imageUrl: imageUrl);
}

