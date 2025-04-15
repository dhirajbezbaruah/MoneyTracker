class Transaction {
  final int? id;
  final double amount;
  final String type; // 'income' or 'expense'
  final int categoryId;
  final String? description;
  final DateTime date;
  final int profileId;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    required this.date,
    required this.profileId,
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
    );
  }
}
