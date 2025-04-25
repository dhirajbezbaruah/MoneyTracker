import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../widgets/banner_ad_widget.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class CurrencyConversionScreen extends StatefulWidget {
  const CurrencyConversionScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyConversionScreen> createState() =>
      _CurrencyConversionScreenState();
}

class _CurrencyConversionScreenState extends State<CurrencyConversionScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  double _result = 0;
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  DateTime? _lastUpdated;

  // Constants for caching
  static const String _cacheKeyPrefix = 'exchange_rates_';
  static const String _cacheLastUpdatedKey = 'exchange_rates_last_updated';
  static const Duration _cacheMaxAge =
      Duration(hours: 6); // Consider rates valid for 6 hours

  // Limited list of popular currencies to avoid exceeding API limits
  final Map<String, String> _popularCurrencies = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'INR': 'Indian Rupee',
    'CNY': 'Chinese Yuan',
  };

  // Full currency display names for dropdown menus
  final Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'HKD': 'Hong Kong Dollar',
    'INR': 'Indian Rupee',
    'SGD': 'Singapore Dollar',
    'AED': 'UAE Dirham',
    'NZD': 'New Zealand Dollar',
    'ZAR': 'South African Rand',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    // Additional currencies
    'RUB': 'Russian Ruble',
    'TRY': 'Turkish Lira',
    'KRW': 'South Korean Won',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht',
    'PHP': 'Philippine Peso',
    'PLN': 'Polish Zloty',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'CZK': 'Czech Koruna',
    'HUF': 'Hungarian Forint',
    'ILS': 'Israeli Shekel',
    'SAR': 'Saudi Riyal',
    'QAR': 'Qatari Riyal',
    'EGP': 'Egyptian Pound',
    'NGN': 'Nigerian Naira',
    'KES': 'Kenyan Shilling',
    'VND': 'Vietnamese Dong',
    'PKR': 'Pakistani Rupee',
    'BDT': 'Bangladeshi Taka',
    'TWD': 'Taiwan Dollar',
  };

  // Exchange rates - will be populated from API or cache
  Map<String, double> _exchangeRates = {};

  @override
  void initState() {
    super.initState();
    _amountController.text = '1';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Initialize from currency with the app's current currency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currencyProvider =
          Provider.of<CurrencyProvider>(context, listen: false);
      setState(() {
        _toCurrency = currencyProvider.currencyCode;
      });
      _loadExchangeRates();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Loads rates from cache first, then tries to update from network
  Future<void> _loadExchangeRates() async {
    // First try to load cached data to show something immediately
    final bool hasCachedData = await _loadCachedRates();

    // Then attempt to fetch fresh data
    if (mounted) {
      _fetchExchangeRates();
    }
  }

  // Loads rates from cache and returns whether valid data was found
  Future<bool> _loadCachedRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$_fromCurrency';
      final cachedData = prefs.getString(cacheKey);
      final lastUpdatedString = prefs.getString(_cacheLastUpdatedKey);

      if (cachedData != null && lastUpdatedString != null) {
        final lastUpdated = DateTime.parse(lastUpdatedString);
        final cachedRates = Map<String, double>.from(json
            .decode(cachedData)
            .map((key, value) => MapEntry(key, value.toDouble())));

        // Check if cache is still valid (not too old)
        if (DateTime.now().difference(lastUpdated) <= _cacheMaxAge) {
          setState(() {
            _exchangeRates = cachedRates;
            _lastUpdated = lastUpdated;
            _isLoading = false;
            _convertCurrency();
            _animationController.forward(from: 0.0);
          });
          return true;
        } else {
          // Cache is too old but we can still show it while loading fresh data
          setState(() {
            _exchangeRates = cachedRates;
            _lastUpdated = lastUpdated;
            _isOfflineMode = true;
            _convertCurrency();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading cached rates: $e');
    }

    return false;
  }

  // Saves rates to cache for offline use
  Future<void> _saveRatesToCache() async {
    if (_exchangeRates.isEmpty || _lastUpdated == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$_fromCurrency';
      await prefs.setString(cacheKey, json.encode(_exchangeRates));
      await prefs.setString(
          _cacheLastUpdatedKey, _lastUpdated!.toIso8601String());
    } catch (e) {
      debugPrint('Error saving rates to cache: $e');
    }
  }

  Future<void> _fetchExchangeRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _isOfflineMode = false;
    });

    try {
      // Use a more reliable primary API endpoint with fallbacks
      final List<Future<http.Response>> apiRequests = [
        // ExchangeRate API - more reliable and comprehensive
        http
            .get(Uri.parse(
                'https://api.exchangerate-api.com/v4/latest/$_fromCurrency'))
            .timeout(const Duration(seconds: 8)),

        // Fixer.io with fallback - reliable but rate-limited
        http
            .get(Uri.parse(
                'https://data.fixer.io/api/latest?access_key=YOUR_API_KEY&base=$_fromCurrency'))
            .timeout(const Duration(seconds: 8)),

        // Currency API as another fallback
        http
            .get(Uri.parse(
                'https://cdn.jsdelivr.net/gh/fawazahmed0/currency-api@latest/latest/currencies/${_fromCurrency.toLowerCase()}.json'))
            .timeout(const Duration(seconds: 8)),

        // Additional fallback - Open Exchange Rates
        http
            .get(Uri.parse('https://open.er-api.com/v6/latest/$_fromCurrency'))
            .timeout(const Duration(seconds: 8)),
      ];

      // Try each API request until one succeeds
      for (final apiRequest in apiRequests) {
        try {
          final response = await apiRequest;

          if (response.statusCode == 200) {
            final Map<String, dynamic> data = json.decode(response.body);
            final Map<String, double> rates = {};
            bool isValidResponse = false;

            // Parse different API formats correctly with robust error handling
            try {
              if (data.containsKey('rates') && data['rates'] is Map) {
                // ExchangeRate API or Fixer.io format
                final ratesData = data['rates'] as Map<String, dynamic>;
                ratesData.forEach((key, value) {
                  if (value is num) {
                    rates[key] = value.toDouble();
                  }
                });
                isValidResponse = rates.isNotEmpty;
              } else if (data.containsKey(_fromCurrency.toLowerCase())) {
                // GitHub CDN API format
                final ratesData =
                    data[_fromCurrency.toLowerCase()] as Map<String, dynamic>;
                ratesData.forEach((key, value) {
                  if (value is num) {
                    rates[key.toUpperCase()] = value.toDouble();
                  }
                });
                isValidResponse = rates.isNotEmpty;
              } else if (data.containsKey('conversion_rates')) {
                // ExchangeRate-API format
                final ratesData =
                    data['conversion_rates'] as Map<String, dynamic>;
                ratesData.forEach((key, value) {
                  if (value is num) {
                    rates[key] = value.toDouble();
                  }
                });
                isValidResponse = rates.isNotEmpty;
              }
            } catch (formatError) {
              debugPrint('Error parsing rate data: $formatError');
              continue; // Try next API if parsing fails
            }

            if (isValidResponse) {
              // Ensure base currency converts to 1.0
              rates[_fromCurrency] = 1.0;

              // Verify we have data for the target currency
              if (!rates.containsKey(_toCurrency) &&
                  _fromCurrency != _toCurrency) {
                continue; // Try next API if missing target currency
              }

              setState(() {
                _exchangeRates = rates;
                _isLoading = false;
                _lastUpdated = DateTime.now();
                _convertCurrency();
                _animationController.forward(from: 0.0);
              });

              // Save successful rates to cache
              _saveRatesToCache();
              return; // Success, exit the function
            }
          }
        } catch (e) {
          debugPrint('API attempt failed: $e');
          continue; // Continue to next API
        }
      }

      // If we get here, all API attempts failed
      if (_exchangeRates.isNotEmpty) {
        // We have cached rates, switch to offline mode
        setState(() {
          _isLoading = false;
          _isOfflineMode = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Unable to fetch exchange rates. Check your connection and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (_exchangeRates.isNotEmpty) {
          _isOfflineMode = true;
        } else {
          _errorMessage =
              'Network error. Please check your connection and try again.';
        }
      });
    }
  }

  void _convertCurrency() {
    if (_amountController.text.isEmpty) {
      setState(() {
        _result = 0;
        _errorMessage = '';
      });
      return;
    }

    try {
      final double amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

      if (_exchangeRates.containsKey(_toCurrency)) {
        setState(() {
          _result = amount * _exchangeRates[_toCurrency]!;
          _errorMessage = '';
        });
      } else if (_fromCurrency == _toCurrency) {
        // Same currency conversion
        setState(() {
          _result = amount;
          _errorMessage = '';
        });
      } else {
        setState(() {
          _result = 0;
          _errorMessage = 'Exchange rate data not available for $_toCurrency';
        });
      }
    } catch (e) {
      setState(() {
        _result = 0;
        _errorMessage = 'Invalid amount format';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mainColor =
        const Color(0xFF2E5C88); // Updated to match app's standard color

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Currency Converter',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDarkMode ? colorScheme.surface : mainColor,
        foregroundColor: isDarkMode ? Colors.white : Colors.white,
        elevation: 0,
        actions: [
          if (_isOfflineMode)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Tooltip(
                message:
                    'Using cached rates from ${DateFormat('MMM d, y HH:mm').format(_lastUpdated!)}',
                child: Icon(Icons.offline_bolt, color: Colors.amber),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchExchangeRates,
              color: mainColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Network status banner for offline mode
                    if (_isOfflineMode)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 16),
                        padding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.amber.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off,
                                size: 18, color: Colors.amber.shade800),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Using offline rates from ${DateFormat('MMM d').format(_lastUpdated!)}. Pull down to refresh.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.amber.shade200
                                      : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Currency conversion card with improved design
                    Card(
                      elevation: 8,
                      shadowColor: Colors.black.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDarkMode
                                ? [
                                    mainColor.withOpacity(0.9),
                                    mainColor.withOpacity(0.7),
                                  ]
                                : [
                                    mainColor,
                                    Color(0xFF64B5F6),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: mainColor.withOpacity(0.2),
                              blurRadius: 15,
                              offset: Offset(0, 8),
                              spreadRadius: -5,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // From currency section with improved UI
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'From',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(left: 8),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _fromCurrency,
                                              dropdownColor:
                                                  mainColor.withOpacity(0.95),
                                              icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.white),
                                              isDense: true,
                                              isExpanded: true,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              onChanged: _isLoading
                                                  ? null
                                                  : (newValue) {
                                                      if (newValue != null &&
                                                          newValue !=
                                                              _fromCurrency) {
                                                        setState(() {
                                                          _fromCurrency =
                                                              newValue;
                                                        });
                                                        _loadExchangeRates();
                                                      }
                                                    },
                                              items: _currencyNames.keys.map<
                                                      DropdownMenuItem<String>>(
                                                  (String code) {
                                                return DropdownMenuItem<String>(
                                                  value: code,
                                                  child: Text(
                                                    "$code - ${_currencyNames[code] ?? code}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    onChanged: (_) => _convertCurrency(),
                                    decoration: InputDecoration(
                                      hintText: 'Enter amount',
                                      hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.6)),
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.1),
                                      prefixIcon: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          _fromCurrency,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      prefixIconConstraints:
                                          const BoxConstraints(
                                              minWidth: 0, minHeight: 0),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(
                                            color: Colors.white, width: 1.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Swap button with improved design
                            Transform.translate(
                              offset: const Offset(0, -1),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
                                          )
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _isLoading
                                              ? null
                                              : () {
                                                  final temp = _fromCurrency;
                                                  setState(() {
                                                    _fromCurrency = _toCurrency;
                                                    _toCurrency = temp;
                                                  });
                                                  _loadExchangeRates();
                                                },
                                          customBorder: CircleBorder(),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: Icon(
                                              Icons.swap_vert,
                                              color: mainColor,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // To currency section with improved UI
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'To',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          margin: EdgeInsets.only(left: 8),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _toCurrency,
                                              dropdownColor:
                                                  mainColor.withOpacity(0.95),
                                              icon: const Icon(
                                                  Icons.arrow_drop_down,
                                                  color: Colors.white),
                                              isDense: true,
                                              isExpanded: true,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              onChanged: (newValue) {
                                                if (newValue != null &&
                                                    newValue != _toCurrency) {
                                                  setState(() {
                                                    _toCurrency = newValue;
                                                    _convertCurrency();
                                                  });
                                                }
                                              },
                                              items: _currencyNames.keys.map<
                                                      DropdownMenuItem<String>>(
                                                  (String code) {
                                                return DropdownMenuItem<String>(
                                                  value: code,
                                                  child: Text(
                                                    "$code - ${_currencyNames[code] ?? code}",
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // Result display with improved visual design
                                  _isLoading
                                      ? Center(
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 40,
                                                width: 40,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 3,
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'Fetching latest rates...',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : AnimatedBuilder(
                                          animation: _animationController,
                                          builder: (context, child) {
                                            return Opacity(
                                              opacity:
                                                  _animationController.value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                    0,
                                                    20 *
                                                        (1 -
                                                            _animationController
                                                                .value)),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    if (_errorMessage
                                                        .isNotEmpty)
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red
                                                              .withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                              _errorMessage,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .red
                                                                    .shade100,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                            SizedBox(height: 8),
                                                            ElevatedButton(
                                                              onPressed:
                                                                  _fetchExchangeRates,
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .white,
                                                                foregroundColor:
                                                                    mainColor,
                                                                elevation: 0,
                                                                textStyle: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold),
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            16),
                                                                minimumSize:
                                                                    Size(100,
                                                                        36),
                                                              ),
                                                              child: Text(
                                                                  'Try Again'),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    else
                                                      Center(
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          20,
                                                                      vertical:
                                                                          16),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Colors
                                                                    .white
                                                                    .withOpacity(
                                                                        0.15),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            16),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .white
                                                                      .withOpacity(
                                                                          0.2),
                                                                  width: 1,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.05),
                                                                    blurRadius:
                                                                        10,
                                                                    offset:
                                                                        Offset(
                                                                            0,
                                                                            4),
                                                                  )
                                                                ],
                                                              ),
                                                              child: Column(
                                                                children: [
                                                                  Text(
                                                                    'Converted Amount',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.7),
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          12),
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Text(
                                                                        '${NumberFormat("#,##0.00", "en_US").format(_result)}',
                                                                        style: const TextStyle(
                                                                            color: Colors
                                                                                .white,
                                                                            fontSize:
                                                                                32,
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              8),
                                                                      Text(
                                                                        _toCurrency,
                                                                        style:
                                                                            TextStyle(
                                                                          color: Colors
                                                                              .white
                                                                              .withOpacity(0.8),
                                                                          fontSize:
                                                                              18,
                                                                          fontWeight:
                                                                              FontWeight.w600,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 12),
                                                            Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                  padding: EdgeInsets
                                                                      .symmetric(
                                                                          horizontal:
                                                                              10,
                                                                          vertical:
                                                                              5),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white
                                                                        .withOpacity(
                                                                            0.1),
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            20),
                                                                  ),
                                                                  child: Text(
                                                                    '1 $_fromCurrency = ${_exchangeRates[_toCurrency]?.toStringAsFixed(4) ?? '-'} $_toCurrency',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white
                                                                          .withOpacity(
                                                                              0.8),
                                                                      fontSize:
                                                                          13,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                ],
                              ),
                            ),

                            if (_lastUpdated != null && !_isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isOfflineMode
                                          ? Icons.history
                                          : Icons.update,
                                      size: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Last updated: ${DateFormat('MMM d, HH:mm').format(_lastUpdated!)}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick conversion options with improved UI
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.flash_on,
                            size: 16,
                            color:
                                isDarkMode ? Colors.amber.shade300 : mainColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Quick Convert',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Quick amount buttons with improved design
                    SizedBox(
                      height: 45,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children:
                            [10, 100, 500, 1000, 5000, 10000].map((amount) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _amountController.text = amount.toString();
                                  _convertCurrency();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode
                                    ? mainColor.withOpacity(0.15)
                                    : mainColor.withOpacity(0.08),
                                foregroundColor:
                                    isDarkMode ? Colors.white : mainColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: mainColor.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Text(
                                NumberFormat("#,##0", "en_US").format(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Popular currencies section with improved UI
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color:
                                isDarkMode ? Colors.amber.shade300 : mainColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Popular Currencies',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPopularCurrenciesGrid(),

                    // Add some bottom padding for better scrolling experience
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Banner ad at the bottom
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _fetchExchangeRates,
        tooltip: 'Refresh rates',
        backgroundColor: mainColor,
        elevation: 4,
        child: _isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ))
            : const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildPopularCurrenciesGrid() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mainColor =
        const Color(0xFF2E5C88); // Updated to match app's standard color

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _popularCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _popularCurrencies.keys.elementAt(index);
        final isSelected = _toCurrency == currency;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _toCurrency = currency;
                _convertCurrency();
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? isDarkMode
                          ? [
                              mainColor.withOpacity(0.25),
                              mainColor.withOpacity(0.1),
                            ]
                          : [
                              mainColor.withOpacity(0.15),
                              mainColor.withOpacity(0.05),
                            ]
                      : isDarkMode
                          ? [
                              Colors.grey.shade800.withOpacity(0.7),
                              Colors.grey.shade800.withOpacity(0.4),
                            ]
                          : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? mainColor.withOpacity(isDarkMode ? 0.7 : 0.5)
                      : isDarkMode
                          ? Colors.grey.shade700.withOpacity(0.5)
                          : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        currency,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? mainColor
                              : isDarkMode
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black87,
                        ),
                      ),
                      if (isSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: mainColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: mainColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _popularCurrencies[currency] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_exchangeRates.isNotEmpty &&
                      _exchangeRates.containsKey(currency))
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? mainColor.withOpacity(0.1)
                              : isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '1 $_fromCurrency = ${_exchangeRates[currency]?.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? mainColor
                                : isDarkMode
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
