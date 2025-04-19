import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencyCodeKey = 'currency_code';
  static const String _currencySymbolKey = 'currency_symbol';

  String _currencyCode = 'INR';
  String _currencySymbol = '₹';

  CurrencyProvider() {
    _loadCurrency();
  }

  String get currencyCode => _currencyCode;
  String get currencySymbol => _currencySymbol;

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_currencyCodeKey) ?? 'INR';
    _currencySymbol = prefs.getString(_currencySymbolKey) ?? '₹';
    notifyListeners();
  }

  Future<void> setCurrency(String code, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, code);
    await prefs.setString(_currencySymbolKey, symbol);
    _currencyCode = code;
    _currencySymbol = symbol;
    notifyListeners();
  }
}
