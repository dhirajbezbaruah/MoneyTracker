class Transaction {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final int categoryId;
  final String? description;
  final DateTime date;
  final int profileId;
  final bool isRecurring;
  final String? recurrenceFrequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime? recurrenceEndDate;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    required this.date,
    required this.profileId,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurrenceEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'profile_id': profileId,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_frequency': recurrenceFrequency,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: map['amount'],
      type: map['type'],
      categoryId: map['category_id'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      profileId: map['profile_id'],
      isRecurring: map['is_recurring'] == 1,
      recurrenceFrequency: map['recurrence_frequency'],
      recurrenceEndDate: map['recurrence_end_date'] != null
          ? DateTime.parse(map['recurrence_end_date'])
          : null,
    );
  }
}
