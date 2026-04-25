// ─── VENDOR MODELS ────────────────────────────────────────────────────────────

// ─── vendor_model.dart ────────────────────────────────────────────────────────

import 'dart:convert';

enum VendorType { restaurant, grocery, drinks, retail }

extension VendorTypeX on VendorType {
  String get label {
    switch (this) {
      case VendorType.restaurant: return 'Restaurant';
      case VendorType.grocery:    return 'Grocery';
      case VendorType.drinks:     return 'Drinks';
      case VendorType.retail:     return 'Retail';
    }
  }
  String get value => name;
  static VendorType from(String v) =>
      VendorType.values.firstWhere((e) => e.name == v, orElse: () => VendorType.restaurant);
}

class VendorModel {
  final String id;
  final String ownerId;
  final String ownerFirebaseUid;
  final VendorType vendorType;
  final String name;
  final String description;
  final String email;
  final String phone;
  final String logo;
  final String coverPhoto;

  final String cac;

  final double rating;

  final int totalCompletedOrders;

  final double completionRate;
  final bool verified;
  final String verificationStatus;
  final String status;
  final String?  rejectionMessage;
  final bool isVisible;
  final bool vendorAllowsPod;
  final List<BranchModel> branches;
  final List<ReviewModel> reviews;
  final DateTime createdAt;

  const VendorModel({
    required this.id,
    required this.ownerId,
    required this.ownerFirebaseUid,
    required this.vendorType,
    required this.name,
    required this.description,
    required this.phone,
    required this.email,
    required this.logo,
    required this.coverPhoto,
    required this.cac,
    required this.rating,
    required this.totalCompletedOrders,
    required this.completionRate,
    required this.verified,
    required this.verificationStatus,
    required this.status,
    this.rejectionMessage,
    required this.vendorAllowsPod,
    required this.isVisible,
    required this.branches,
    required this.reviews,
    required this.createdAt,
  });

  factory VendorModel.fromJson(Map<String, dynamic> j) => VendorModel(
    id: j['id'],
    ownerId: j['ownerId'],
    ownerFirebaseUid: j['ownerFirebaseUid'],
    vendorType: VendorTypeX.from(j['vendorType']),
    name: j['name'],
    description: j['description'],
    logo: j['logo'] ?? '',
    coverPhoto: j['coverPhoto'],
    cac: j['cac'] ?? '',
    rating: (j['rating'] as num).toDouble(),
    totalCompletedOrders: j['totalCompletedOrders'],
    completionRate: (j['completionRate'] as num).toDouble(),
    verified: j['verified'],
    verificationStatus: j['verificationStatus'] ?? 'unverified',
    status: j['status'],
    rejectionMessage: j['rejectionMessage'] ?? 'Application Does Not meet our criteria',
    vendorAllowsPod: j['allowsPayOnDelivery'] ?? false,
    isVisible: j['isVisible'] ?? false,
    branches: (j['branches'] as List? ?? []).map((b) => BranchModel.fromJson(b)).toList(),
    reviews: (j['reviews'] as List? ?? []).map((r) => ReviewModel.fromJson(r)).toList(),
    createdAt: DateTime.parse(j['createdAt']),
    phone: j['phone'],
    email: j['email'],
  );

  VendorModel copyWith({bool ? isVisible, String ? logo, bool? allowsPod}) {
    return VendorModel(
        id: id,
        ownerId: ownerId,
        ownerFirebaseUid: ownerFirebaseUid,
        vendorType: vendorType,
        name: name,
        description: description,
        logo: logo ?? this.logo,
        coverPhoto: coverPhoto,
        cac: cac,
        rating: rating,
        totalCompletedOrders: totalCompletedOrders,
        completionRate: completionRate,
        verified: verified,
        verificationStatus: verificationStatus,
        status: status,
        vendorAllowsPod: allowsPod ?? vendorAllowsPod,
        isVisible: isVisible ?? this.isVisible,
        branches: branches,
        reviews: reviews, createdAt: createdAt,
        phone: phone,
        email: email,
    );
  }

  bool isOwner(String managerId) => ownerId == managerId;


}

class BranchModel {
  final String id;
  final String vendorId;
  final String state;
  final String lga;
  final String area;
  final String street;
  final int estimatedDeliveryTime;
  // In BranchModel:
  final bool isMainBranch;
  final String? managerUid;
  final String? managerId;


  final List<DeliveryZoneModel> deliveryZones;

  const BranchModel({
    required this.id,
    required this.vendorId,
    required this.state,
    required this.lga,
    required this.area,
    required this.street,
    required this.estimatedDeliveryTime,
    required this.isMainBranch,
    required this.managerUid,
    required this.managerId,
    required this.deliveryZones,
  });

  String get fullAddress => '$street, $area, $lga, $state';

  double? get lowestDeliveryFee => deliveryZones.isEmpty
      ? null
      : deliveryZones.map((z) => z.deliveryFee).reduce((a, b) => a < b ? a : b);

  factory BranchModel.fromJson(Map<String, dynamic> j) => BranchModel(
    id: j['id'],
    vendorId: j['vendorId'],
    state: j['state'],
    lga: j['lga'],
    area: j['area'],
    street: j['street'],
    estimatedDeliveryTime: j['estimatedDeliveryTime'],
    // In fromJson:
    isMainBranch: j['isMainBranch'] ?? false,
    managerUid:   j['managerUid'],
    managerId: j['managerId'],
    deliveryZones: (j['deliveryZones'] as List? ?? []).map((z) => DeliveryZoneModel.fromJson(z)).toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'vendorId': vendorId, 'state': state, 'lga': lga,
    'area': area, 'street': street, 'estimatedDeliveryTime': estimatedDeliveryTime,
  };
}

class DeliveryZoneModel {
  final String id;
  final String branchId;
  final String state;
  final String lga;
  final String area;
  final double deliveryFee;

  const DeliveryZoneModel({
    required this.id, required this.branchId, required this.state,
    required this.lga, required this.area, required this.deliveryFee,
  });

  factory DeliveryZoneModel.fromJson(Map<String, dynamic> j) => DeliveryZoneModel(
    id: j['id'], branchId: j['branchId'], state: j['state'],
    lga: j['lga'], area: j['area'], deliveryFee: (j['deliveryFee'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'state': state, 'lga': lga, 'area': area, 'deliveryFee': deliveryFee,
  };
}

class MenuItemModel {
  final String id;
  final String branchId;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final bool isAvailable;
  final DateTime createdAt;

  const MenuItemModel({
    required this.id, required this.branchId, required this.name,
    required this.description, required this.price, required this.images,
    required this.isAvailable, required this.createdAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> j) => MenuItemModel(
    id: j['id'], branchId: j['branchId'], name: j['name'],
    description: j['description'], price: (j['price'] as num).toDouble(),
    images:      (j['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [],
    isAvailable: j['isAvailable'],
    createdAt: DateTime.parse(j['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'price': price,
    'isAvailable': isAvailable,
  };

  String get firstImage => images.isNotEmpty ? images.first : '';

}

class ReviewModel {
  final String id;
  final String vendorId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id, required this.vendorId, required this.userName,
    required this.rating, required this.comment, required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
    id: j['id'], vendorId: j['vendorId'], userName: j['userName'],
    rating: (j['rating'] as num).toDouble(), comment: j['comment'],
    createdAt: DateTime.parse(j['createdAt']),
  );
}