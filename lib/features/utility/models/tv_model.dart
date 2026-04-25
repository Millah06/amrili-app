class TvPlan {
  final String description;
  final String duration;
  final String price;
  final String variationCode;

  TvPlan({
    required this.description,
    required this.duration,
    required this.price,
    required this.variationCode,
  });

  factory TvPlan.fromMap(Map<String, dynamic> map) {
    return TvPlan(
      description: map['name'] ?? '',
      duration: map['duration'] ?? '',
      price: map['variation_amount'] ?? '',
      variationCode: map['variation_code'] ?? '',
    );
  }
}

class TvCategoryData {
  final String category;
  final List<TvPlan> tvPlans;

  TvCategoryData({
    required this.category,
    required this.tvPlans,
  });

  factory TvCategoryData.fromMap(Map<String, dynamic> map) {
    final List<dynamic> plansRaw = map['tvPlans'] ?? [];

    return TvCategoryData(
      category: map['category'] ?? '',
      tvPlans: plansRaw.map((p) => TvPlan.fromMap(Map<String, dynamic>.from(p))).toList(),
    );
  }
}