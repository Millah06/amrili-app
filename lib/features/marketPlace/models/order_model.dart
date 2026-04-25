

// ─── order_model.dart ─────────────────────────────────────────────────────────



import 'package:everywhere/features/marketPlace/models/vendor_model.dart';

enum OrderStatus {
  pending, confirmed, preparing, outForDelivery,
  delivered, pendingFundRelease, completed, cancelled, appealed
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:        return 'Pending';
      case OrderStatus.confirmed:      return 'Confirmed';
      case OrderStatus.preparing:      return 'Preparing';
      case OrderStatus.outForDelivery: return 'Out for Delivery';
      case OrderStatus.delivered:      return 'Delivered';
      case OrderStatus.completed:      return 'Completed';
      case OrderStatus.cancelled:      return 'Cancelled';
      case OrderStatus.appealed:       return 'Appealed';
      case OrderStatus.pendingFundRelease: return 'Pending Release';
    }
  }

  bool get isOngoing => [
    OrderStatus.pending, OrderStatus.confirmed,
    OrderStatus.preparing, OrderStatus.outForDelivery,
    OrderStatus.delivered, OrderStatus.pendingFundRelease
  ].contains(this);

  bool get canConfirm  => this == OrderStatus.delivered;
  bool get canAppeal   => this == OrderStatus.delivered ||
      this == OrderStatus.outForDelivery ||
      this == OrderStatus.preparing ||
      this == OrderStatus.confirmed;

  static OrderStatus from(String v) =>
      OrderStatus.values.firstWhere((e) => e.name == v, orElse: () => OrderStatus.pending);
}

class OrderItemModel {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.menuItemId, required this.name,
    required this.price, required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    menuItemId: j['menuItemId'], name: j['name'],
    price: (j['price'] as num).toDouble(), quantity: j['quantity'],
  );

  Map<String, dynamic> toJson() => {
    'menuItemId': menuItemId, 'name': name, 'price': price, 'quantity': quantity,
  };
}

class DeliveryAddress {
  final String state;
  final String lga;
  final String area;
  final String street;

  const DeliveryAddress({
    required this.state,
    required this.lga,
    required this.area,
    required this.street,
  });

  String get full => '$street, $area, $lga, $state';

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        state: json['state'],
        lga: json['lga'],
        area: json['area'],
        street: json['street'],
      );

  Map<String, dynamic> toJson() => {
    'state': state,
    'lga': lga,
    'area': area,
    'street': street,
  };
}


class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String vendorId;
  final String vendorName;
  final String vendorLogo;
  final String branchId;
  final String branchName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double transactionFee;
  final double totalAmount;
  final OrderStatus status;
  final String escrowStatus;
  final DeliveryAddress deliveryAddress;
  final String paymentMethod;
  final bool podConfirmed;
  // final String deliveryState;
  // final String deliveryLga;
  // final String deliveryArea;
  // final String deliveryStreet;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.vendorId,
    required this.vendorName,
    required this.vendorLogo,
    required this.branchId,
    required this.branchName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.transactionFee,
    required this.totalAmount,
    required this.status,
    required this.escrowStatus,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.podConfirmed,
    required this.createdAt,
  });


  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: j['id'],
    userId: j['userId'],
    userName: j['userName'] ?? 'Customer',
    vendorId: j['vendorId'],
    vendorName: j['vendorName'] ?? '', vendorLogo: j['vendorLogo'] ?? '',
    branchId: j['branchId'], branchName: j['branchName'] ?? '',
    items: (j['items'] as List).map((i) => OrderItemModel.fromJson(i)).toList(),
    subtotal: (j['subtotal'] as num).toDouble(),
    deliveryFee: (j['deliveryFee'] as num).toDouble(),
    transactionFee: (j['transactionFee'] as num).toDouble(),
    totalAmount: (j['totalAmount'] as num).toDouble(),
    status: OrderStatusX.from(j['status']),
    escrowStatus: j['escrowStatus'],
    paymentMethod: j['paymentMethod'] ?? 'escrow',
    podConfirmed: j['podConfirmed'] ?? false,
    deliveryAddress: DeliveryAddress(state: j['deliveryState'] ?? '', lga: j['deliveryLga'] ?? '',
        area: j['deliveryArea'] ?? '', street: j['deliveryStreet'] ?? ''),
    // deliveryAddress: DeliveryAddress.fromJson(j['deliveryAddress']),
    
    createdAt: DateTime.parse(j['createdAt']),
  );
}

class CartItem {
  final MenuItemModel menuItem;
  int quantity;

  CartItem({required this.menuItem, this.quantity = 1});

  double get total => menuItem.price * quantity;

  Map<String, dynamic> toOrderPayload() => {
    'menuItemId': menuItem.id,
    'quantity': quantity,
  };
}

class ChatMessageModel {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String message;
  final bool isAdmin;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id, required this.orderId, required this.senderId,
    required this.senderName, required this.message,
    required this.isAdmin, this.createdAt,
  });

  factory ChatMessageModel.fromFirestore(Map<String, dynamic> json, String id, String orderId) =>
      ChatMessageModel(
        id: id, orderId: orderId,
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        message: json['message'] ?? '',
        isAdmin: json['isAdmin'] ?? false,
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : null,
      );
}

class VendorMetrics {
  final int totalCompletedOrders;
  final double completionRate;
  final double totalRevenue;
  final double pendingEscrow;
  final double releasedEarnings;
  final double rating;

  const VendorMetrics({
    required this.totalCompletedOrders, required this.completionRate,
    required this.totalRevenue, required this.pendingEscrow,
    required this.releasedEarnings, required this.rating,
  });

  factory VendorMetrics.fromJson(Map<String, dynamic> j) => VendorMetrics(
    totalCompletedOrders: j['totalCompletedOrders'],
    completionRate: (j['completionRate'] as num).toDouble(),
    totalRevenue: (j['totalRevenue'] as num).toDouble(),
    pendingEscrow: (j['pendingEscrow'] as num).toDouble(),
    releasedEarnings: (j['releasedEarnings'] as num).toDouble(),
    rating: (j['rating'] as num).toDouble(),
  );
}

class LocationState {
  final String id;
  final String name;
  const LocationState({required this.id, required this.name});
  factory LocationState.fromJson(Map<String, dynamic> j) => LocationState(id: j['id'], name: j['name']);
}

class LocationLga {
  final String id;
  final String name;
  const LocationLga({required this.id, required this.name});
  factory LocationLga.fromJson(Map<String, dynamic> j) => LocationLga(id: j['id'], name: j['name']);
}

class LocationArea {
  final String id;
  final String name;
  const LocationArea({required this.id, required this.name});
  factory LocationArea.fromJson(Map<String, dynamic> j) => LocationArea(id: j['id'], name: j['name']);
}

class LocationStreet {
  final String id;
  final String name;
  const LocationStreet({required this.id, required this.name});
  factory LocationStreet.fromJson(Map<String, dynamic> j) => LocationStreet(id: j['id'], name: j['name']);
}
