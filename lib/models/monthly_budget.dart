class MonthlyBudget {
  final int? id;
  final String month;
  final double amount;
  final int profileId;
  final bool isRecurring;

  MonthlyBudget({
    this.id,
    required this.month,
    required this.amount,
    required this.profileId,
    this.isRecurring = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'profile_id': profileId,
      'is_recurring': isRecurring ? 1 : 0,
    };
  }

  static MonthlyBudget fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      id: map['id'],
      month: map['month'],
      amount: map['amount'],
      profileId: map['profile_id'],
      isRecurring: map['is_recurring'] == 1,
    );
  }

  MonthlyBudget copyWith({
    int? id,
    String? month,
    double? amount,
    int? profileId,
    bool? isRecurring,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      profileId: profileId ?? this.profileId,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }
}
