import 'package:flutter/material.dart';
//import 'package:shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  static const String _currencyKey = 'currency_symbol';
  String _currencySymbol = '₹';

  CurrencyProvider() {
    _loadCurrencySymbol();
  }

  String get currencySymbol => _currencySymbol;

  Future<void> _loadCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    _currencySymbol = prefs.getString(_currencyKey) ?? '₹';
    notifyListeners();
  }

  Future<void> setCurrencySymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, symbol);
    _currencySymbol = symbol;
    notifyListeners();
  }
}
