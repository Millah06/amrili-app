// class Plan {
//   final int price;
//   final String duration;
//   final String quantity;
//
//   Plan({required this.price, required this.duration, required this.quantity});
//
//   factory Plan.fromMap(Map<String, dynamic> map) {
//     return Plan(
//       price: map['price'],
//       duration: map['duration'],
//       quantity: map['quantity'],
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'price': price,
//       'duration': duration,
//       'quantity': quantity,
//     };
//   }
// }
//
// class CategoryData {
//   final String category;
//   final List<Plan> plans;
//
//   CategoryData({required this.category, required this.plans});
//
//   factory CategoryData.fromMap(Map<String, dynamic> map) {
//     return CategoryData(
//       category: map['category'],
//       plans: (map['plans'] as List)
//           .map((planMap) => Plan.fromMap(planMap))
//           .toList(),
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//     'category': category,
//     'plans': plans.map((plan) => plan.toMap()).toList(),
//     };
//   }
// }

class Plan {
  final String quantity;
  final String duration;
  final String price;
  final String variationCode;
  final String social;

  Plan({
    required this.variationCode,
    required this.quantity,
    required this.duration,
    required this.price,
    required this.social
  });

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      variationCode: map['variation_code'] ?? '',
      quantity: map['name'] ?? '',
      duration: map['duration'] ?? '',
      price: map['variation_amount'] ?? '',
      social: map['social'] ?? '',
    );
  }
}

class CategoryData {
  final String category;
  final List<Plan> plans;

  CategoryData({
    required this.category,
    required this.plans,
  });

  factory CategoryData.fromMap(Map<String, dynamic> map) {
    final List<dynamic> plansRaw = map['plans'] ?? [];

    return CategoryData(
        category: map['category'] ?? '',
        plans: plansRaw.map((p) => Plan.fromMap(Map<String, dynamic>.from(p))).toList(),
    );
  }
}