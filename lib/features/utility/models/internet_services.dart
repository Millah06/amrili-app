class InternetPlan {
  final String description;
  final String duration;
  final String price;
  final String variationCode;

  InternetPlan({
    required this.description,
    required this.duration,
    required this.price,
    required this.variationCode,
  });

  factory InternetPlan.fromMap(Map<String, dynamic> map) {
    return InternetPlan(
      description: map['name'] ?? '',
      duration: map['duration'] ?? '',
      price: map['variation_amount'] ?? '',
      variationCode: map['variation_code'] ?? '',
    );
  }
}

class InternetCategoryData {
  final String category;
  final List<InternetPlan> plans;

  InternetCategoryData({
    required this.category,
    required this.plans,
  });

  factory InternetCategoryData.fromMap(Map<String, dynamic> map) {
    final List<dynamic> plansRaw = map['plans'] ?? [];

    return InternetCategoryData(
      category: map['category'] ?? '',
      plans: plansRaw.map((p) => InternetPlan.fromMap(Map<String, dynamic>.from(p))).toList(),
    );
  }
}