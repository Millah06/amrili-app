
import '../../features/marketPlace/models/order_model.dart';
import '../api_service.dart';

// ─── ORDER REPOSITORY ─────────────────────────────────────────────────────────

class OrderRepository {
  final ApiService api;
  OrderRepository({required this.api});

  Future<OrderModel> placeOrder({
    required String vendorId,
    required String branchId,
    required List<CartItem> items,
    required DeliveryAddress deliveryAddress,
  }) async {
    final body = {
      'vendorId': vendorId,
      'branchId': branchId,
      'items': items.map((i) => i.toOrderPayload()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
    };
    final data = await api.post('/orders', body);
    return OrderModel.fromJson(data);
  }

  Future<List<OrderModel>> fetchMyOrders({String? status}) async {
    final query = <String, String>{
      if (status != null) 'status': status,
    };
    final data = await api.get('/orders/me', query: query) as List;
    return data.map((o) => OrderModel.fromJson(o)).toList();
  }

  Future<OrderModel> fetchOrderById(String orderId) async {
    final data = await api.get('/orders/$orderId');
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> confirmDelivery(String orderId) async {
    final data = await api.post('/orders/$orderId/confirm', {});
    return OrderModel.fromJson(data);
  }

  Future<OrderModel> appealOrder(String orderId, String reason) async {
    final data = await api.post('/orders/$orderId/appeal', {'reason': reason});
    return OrderModel.fromJson(data);
  }

  Future<List<ChatMessageModel>> fetchOrderChat(String orderId) async {
    final data = await api.get('/orders/$orderId/chat') as List;
    return data.map((m) => ChatMessageModel.fromFirestore(m.data(), m.id, orderId)).toList();
  }

  Future<ChatMessageModel> sendChatMessage(
      String orderId, String message) async {
    final data = await api.post('/orders/$orderId/chat', {'message': message});
    return ChatMessageModel.fromFirestore(data.data(), data.id, orderId);
  }

  // ─── Vendor order management ─────────────────────────────────────────────────

  Future<List<OrderModel>> fetchVendorOrders({String? status}) async {
    final query = <String, String>{
      if (status != null) 'status': status,
    };
    final data = await api.get('/orders/vendor', query: query) as List;
    return data.map((o) => OrderModel.fromJson(o)).toList();
  }

  Future<OrderModel> updateOrderStatus(String orderId, String status) async {
    final data = await api.put('/orders/$orderId/status', {'status': status});
    return OrderModel.fromJson(data);
  }
}