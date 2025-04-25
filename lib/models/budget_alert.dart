class BudgetAlert {
  final int? id;
  final int? categoryId; // Made nullable
  final double threshold;
  final bool isPercentage;
  final bool enabled;

  BudgetAlert({
    this.id,
    this.categoryId, // Made optional
    required this.threshold,
    this.isPercentage = true,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId, // Will be null for overall budget alerts
      'threshold': threshold,
      'is_percentage': isPercentage ? 1 : 0,
      'enabled': enabled ? 1 : 0,
    };
  }

  static BudgetAlert fromMap(Map<String, dynamic> map) {
    return BudgetAlert(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?, // Handle null value
      threshold: map['threshold'] as double,
      isPercentage: (map['is_percentage'] as int) == 1,
      enabled: (map['enabled'] as int) == 1,
    );
  }

  BudgetAlert copyWith({
    int? id,
    int? categoryId,
    double? threshold,
    bool? isPercentage,
    bool? enabled,
  }) {
    return BudgetAlert(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      threshold: threshold ?? this.threshold,
      isPercentage: isPercentage ?? this.isPercentage,
      enabled: enabled ?? this.enabled,
    );
  }
}
