import 'package:everywhere/features/marketPlace/models/vendor_model.dart';

// ─── OrderStatus ──────────────────────────────────────────────────────────────

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  pendingFundRelease,
  completed,
  cancelled,
  appealed,
}

extension OrderStatusX on OrderStatus {

  String get label {
    switch (this) {
      case OrderStatus.pending:            return 'Pending';
      case OrderStatus.confirmed:          return 'Confirmed';
      case OrderStatus.preparing:          return 'Preparing';
      case OrderStatus.outForDelivery:     return 'Out for Delivery';
      case OrderStatus.delivered:          return 'Delivered';
      case OrderStatus.pendingFundRelease: return 'Pending Release';
      case OrderStatus.completed:          return 'Completed';
      case OrderStatus.cancelled:          return 'Cancelled';
      case OrderStatus.appealed:           return 'Appealed';
    }
  }

  /// 0-based step for the progress stepper. -1 = cancelled, -2 = appealed.
  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:            return 0;
      case OrderStatus.confirmed:          return 1;
      case OrderStatus.preparing:          return 2;
      case OrderStatus.outForDelivery:     return 3;
      case OrderStatus.delivered:          return 4;
      case OrderStatus.pendingFundRelease: return 4;
      case OrderStatus.completed:          return 5;
      case OrderStatus.cancelled:          return -1;
      case OrderStatus.appealed:           return -2;
    }
  }

  bool get isOngoing => const [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.pendingFundRelease,
  ].contains(this);

  /// Buyer can release funds / confirm delivery.
  bool get canConfirm => this == OrderStatus.delivered;

  /// Either party can raise an appeal.
  bool get canAppeal => const [
    OrderStatus.delivered,
    OrderStatus.outForDelivery,
    OrderStatus.preparing,
    OrderStatus.confirmed,
  ].contains(this);

  bool get canAppealForVendor => const [
    OrderStatus.delivered,
  ].contains(this);

  bool get canCancelForVendor => const [
    OrderStatus.outForDelivery,
    OrderStatus.preparing,
    OrderStatus.confirmed,
    OrderStatus.pending,
  ].contains(this);

  bool get isFinal =>
      this == OrderStatus.completed ||
          this == OrderStatus.cancelled;

  static OrderStatus from(String v) =>
      OrderStatus.values.firstWhere((e) => e.name == v,
          orElse: () => OrderStatus.pending);
}

extension OrderDisplayX on OrderModel {
  /// Card/detail headline. Dine-in → "#4827 · Table 5"; else the short id.
  String get displayRef => isDineIn
      ? '#${orderNumber ?? ''}${tableNumber != null ? ' · Table $tableNumber' : ''}'
      : id.substring(0, 8).toUpperCase();

  /// Fulfillment-aware status text. Dine-in relabels two states; everything
  /// else (Preparing/Completed/Pending…) already reads right via status.label.
  String get statusLabel {
    if (isDineIn) {
      switch (status) {
        case OrderStatus.outForDelivery: return 'Ready';
        case OrderStatus.delivered:      return 'Served';
        default: break;
      }
    }
    return status.label;
  }
}

// ─── OrderItemModel ───────────────────────────────────────────────────────────

class OrderItemModel {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    menuItemId: j['menuItemId'],
    name: j['name'],
    price: (j['price'] as num).toDouble(),
    quantity: j['quantity'],
  );
}

// ─── DeliveryAddress ──────────────────────────────────────────────────────────

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

  String get full {
    final parts = [street, area, lga, state];

    return parts
        .where((e) => e.trim().isNotEmpty)
        .join(', ');
  }

  factory DeliveryAddress.fromJson(Map<String, dynamic> j) => DeliveryAddress(
    state: j['state'],
    lga: j['lga'],
    area: j['area'],
    street: j['street'],
  );
}

// ─── OrderModel ───────────────────────────────────────────────────────────────

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

  final int? orderNumber;
  final String? tableNumber;
  final String fulfillmentType;
  bool get isDineIn => fulfillmentType == 'dine_in';
// in fromJson:


  final DeliveryAddress deliveryAddress;
  final String paymentMethod;
  final bool podConfirmed;
  final String? appealedBy; // userId of whoever filed the appeal
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
    this.orderNumber,
    required this.fulfillmentType,
    this.tableNumber,
    required this.paymentMethod,
    required this.podConfirmed,
    required this.createdAt,
    this.appealedBy,
  });

  /// Pay-on-delivery — no escrow involved.
  bool get isPod => paymentMethod == 'pay_on_delivery';

  /// Deadline before auto-cancel (30 min from creation while pending).
  DateTime get autoCancelAt => createdAt.add(const Duration(minutes: 30));

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: j['id'],
    userId: j['userId'],
    userName: j['userName'] ?? 'Customer',
    vendorId: j['vendorId'],
    vendorName: j['vendorName'] ?? '',
    vendorLogo: j['vendorLogo'] ?? '',
    branchId: j['branchId'],
    branchName: j['branchName'] ?? '',
    items: (j['items'] as List)
        .map((i) => OrderItemModel.fromJson(i))
        .toList(),
    subtotal: (j['subtotal'] as num).toDouble(),
    deliveryFee: (j['deliveryFee'] as num).toDouble(),
    transactionFee: (j['transactionFee'] as num).toDouble(),
    totalAmount: (j['totalAmount'] as num).toDouble(),
    status: OrderStatusX.from(j['status']),
    escrowStatus: j['escrowStatus'] ?? 'held',

    orderNumber: (j['orderNumber'] as num?)?.toInt(),
    tableNumber: j['tableNumber'],
    fulfillmentType: j['fulfillmentType'] ?? 'delivery',

    paymentMethod: j['paymentMethod'] ?? 'escrow',
    podConfirmed: j['podConfirmed'] ?? false,
    appealedBy: j['appealedBy'],
    deliveryAddress: DeliveryAddress(
      state: j['deliveryState'] ?? '',
      lga: j['deliveryLga'] ?? '',
      area: j['deliveryArea'] ?? '',
      street: j['deliveryStreet'] ?? '',
    ),
    createdAt: DateTime.parse(j['createdAt']),
  );
}

// ─── ChatMessageModel ─────────────────────────────────────────────────────────

class ChatMessageModel {
  final String id;
  final String orderId;
  final String senderId;
  final String senderName;
  final String message;
  final String? imageUrl; // optional — proof images, appeal evidence, etc.
  final bool isAdmin;
  final DateTime? createdAt;

  const ChatMessageModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isAdmin,
    this.imageUrl,
    this.createdAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessageModel.fromFirestore(
      Map<String, dynamic> json,
      String id,
      String orderId,
      ) =>
      ChatMessageModel(
        id: id,
        orderId: orderId,
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        message: json['message'] ?? '',
        imageUrl: json['imageUrl'],
        isAdmin: json['isAdmin'] ?? false,
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : null,
      );
}

// ─── CartItem ─────────────────────────────────────────────────────────────────

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

// ─── VendorMetrics ────────────────────────────────────────────────────────────

class VendorMetrics {
  final int totalCompletedOrders;
  final double completionRate;
  final double totalRevenue;
  final double pendingEscrow;
  final double releasedEarnings;
  final double rating;

  const VendorMetrics({
    required this.totalCompletedOrders,
    required this.completionRate,
    required this.totalRevenue,
    required this.pendingEscrow,
    required this.releasedEarnings,
    required this.rating,
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

// ─── Location Models ──────────────────────────────────────────────────────────

class LocationState {
  final String id;
  final String name;
  const LocationState({required this.id, required this.name});
  factory LocationState.fromJson(Map<String, dynamic> j) =>
      LocationState(id: j['id'], name: j['name']);
}

class LocationLga {
  final String id;
  final String name;
  const LocationLga({required this.id, required this.name});
  factory LocationLga.fromJson(Map<String, dynamic> j) =>
      LocationLga(id: j['id'], name: j['name']);
}

class LocationArea {
  final String id;
  final String name;
  const LocationArea({required this.id, required this.name});
  factory LocationArea.fromJson(Map<String, dynamic> j) =>
      LocationArea(id: j['id'], name: j['name']);
}

class LocationStreet {
  final String id;
  final String name;
  const LocationStreet({required this.id, required this.name});
  factory LocationStreet.fromJson(Map<String, dynamic> j) =>
      LocationStreet(id: j['id'], name: j['name']);
}