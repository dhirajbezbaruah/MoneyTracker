class Currency {
  final String code;
  final String symbol;

  Currency({
    required this.code,
    required this.symbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'symbol': symbol,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      code: map['code'] as String,
      symbol: map['symbol'] as String,
    );
  }
}
