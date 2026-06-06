import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  bool get canCheckout => selectedZone != null;

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

  String paymentMethod = 'escrow'; // default

  void setPaymentMethod(String method) {
    paymentMethod = method;
    print('the payment method has been set to $method');
    notifyListeners();
  }

  Future<bool> placeOrder({required String vendorId, required String branchId,
    required List<CartItem> items,}) async {
    if (!canCheckout) {
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
        'deliveryAddress': {
          'state': selectedZone!.state,
          'lga': selectedZone!.lga,
          'area': selectedZone!.area,
          'street': '',
        },
        'paymentMethod': paymentMethod,
      });
      placedOrder = OrderModel.fromJson(data);
      return true;
    } catch (e) {
      error = e.toString();
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

  List<OrderModel> orders = [];
  bool loading = false;
  String? error;

  List<OrderModel> get ongoing =>
      orders.where((o) => o.status.isOngoing).toList();
  List<OrderModel> get completed =>
      orders.where((o) => o.status == OrderStatus.completed).toList();
  List<OrderModel> get cancelled =>
      orders.where((o) => o.status == OrderStatus.cancelled).toList();
  List<OrderModel> get appealed =>
      orders.where((o) => o.status == OrderStatus.appealed).toList();

  Future<void> fetchOrders() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.get('/order/mine') as List;
      orders = data.map((o) => OrderModel.fromJson(o)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> confirmDelivery(String orderId) async {
    try {
      final data = await api.post('/order/$orderId/confirm', {});
      _replace(OrderModel.fromJson(data));
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> appealOrder(String orderId, String reason) async {
    try {
      final data = await api.post('/order/$orderId/appeal', {'reason': reason});
      _replace(OrderModel.fromJson(data));
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
      await fetchOrders();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Called by the counterparty (not the appellant) to concede the appeal.
  /// Backend resolves fund direction based on who originally appealed.
  Future<bool> concedeAppeal(String orderId) async {
    try {
      await api.post('/order/$orderId/concede-appeal', {});
      await fetchOrders();
      return true;
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void _replace(OrderModel updated) {
    final i = orders.indexWhere((o) => o.id == updated.id);
    if (i != -1) {
      orders[i] = updated;
      notifyListeners();
    }
  }

  StreamSubscription<DocumentSnapshot>? _pingSubscription;

  /// Call once after login, passing the current user's backend userId.
  void watchRealtime(String userId) {
    _pingSubscription?.cancel();
    _pingSubscription = FirebaseFirestore.instance
        .doc('orderPings/$userId')
        .snapshots()
        .skip(1) // skip the initial snapshot so we don't double-fetch on startup
        .listen((_) => fetchOrders());
  }

  @override
  void dispose() {
    _pingSubscription?.cancel();
    super.dispose();
  }

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

