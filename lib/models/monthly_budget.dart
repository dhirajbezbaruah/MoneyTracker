class MonthlyBudget {
  final int? id;
  final String month;
  final double amount;
  final int profileId;

  MonthlyBudget({
    this.id,
    required this.month,
    required this.amount,
    required this.profileId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'profile_id': profileId,
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      id: map['id'],
      month: map['month'],
      amount: map['amount'],
      profileId: map['profile_id'],
    );
  }

  MonthlyBudget copyWith({
    int? id,
    String? month,
    double? amount,
    int? profileId,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      profileId: profileId ?? this.profileId,
    );
  }
}
