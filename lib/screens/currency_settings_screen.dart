import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({super.key});

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Keep INR and USD at the top and sort the rest alphabetically
  static final List<Map<String, String>> priorityCurrencies = [
    {'symbol': '₹', 'name': 'Indian Rupee (INR)'},
    {'symbol': '\$', 'name': 'US Dollar (USD)'},
  ];

  static final List<Map<String, String>> otherCurrencies = [
    {'symbol': '€', 'name': 'Euro (EUR)'},
    {'symbol': '£', 'name': 'British Pound (GBP)'},
    {'symbol': '¥', 'name': 'Japanese Yen (JPY)'},
    {'symbol': '¥', 'name': 'Chinese Yuan (CNY)'},
    {'symbol': '₩', 'name': 'South Korean Won (KRW)'},
    {'symbol': '₽', 'name': 'Russian Ruble (RUB)'},
    {'symbol': 'CHF', 'name': 'Swiss Franc (CHF)'},
    {'symbol': 'CA\$', 'name': 'Canadian Dollar (CAD)'},
    {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)'},
    {'symbol': 'HK\$', 'name': 'Hong Kong Dollar (HKD)'},
    {'symbol': 'SGD', 'name': 'Singapore Dollar (SGD)'},
    {'symbol': 'NZ\$', 'name': 'New Zealand Dollar (NZD)'},
    {'symbol': 'kr', 'name': 'Swedish Krona (SEK)'},
    {'symbol': 'kr', 'name': 'Norwegian Krone (NOK)'},
    {'symbol': 'kr', 'name': 'Danish Krone (DKK)'},
    {'symbol': 'zł', 'name': 'Polish Złoty (PLN)'},
    {'symbol': 'R', 'name': 'South African Rand (ZAR)'},
    {'symbol': '₺', 'name': 'Turkish Lira (TRY)'},
    {'symbol': '฿', 'name': 'Thai Baht (THB)'},
    {'symbol': 'RM', 'name': 'Malaysian Ringgit (MYR)'},
    {'symbol': '₱', 'name': 'Philippine Peso (PHP)'},
    {'symbol': 'Rp', 'name': 'Indonesian Rupiah (IDR)'},
    {'symbol': '₫', 'name': 'Vietnamese Dong (VND)'},
    {'symbol': '₿', 'name': 'Bitcoin (BTC)'},
    {'symbol': 'AED', 'name': 'UAE Dirham (AED)'},
    {'symbol': 'SAR', 'name': 'Saudi Riyal (SAR)'},
    {'symbol': 'QAR', 'name': 'Qatari Riyal (QAR)'},
    {'symbol': 'KWD', 'name': 'Kuwaiti Dinar (KWD)'},
    {'symbol': 'BHD', 'name': 'Bahraini Dinar (BHD)'},
    {'symbol': 'OMR', 'name': 'Omani Rial (OMR)'},
    {'symbol': 'EGP', 'name': 'Egyptian Pound (EGP)'},
    {'symbol': '₦', 'name': 'Nigerian Naira (NGN)'},
    {'symbol': 'KES', 'name': 'Kenyan Shilling (KES)'},
    {'symbol': 'GH₵', 'name': 'Ghanaian Cedi (GHS)'},
    {'symbol': 'UGX', 'name': 'Ugandan Shilling (UGX)'},
    {'symbol': 'TZS', 'name': 'Tanzanian Shilling (TZS)'},
    {'symbol': 'MAD', 'name': 'Moroccan Dirham (MAD)'},
    {'symbol': 'DZD', 'name': 'Algerian Dinar (DZD)'},
    {'symbol': 'TND', 'name': 'Tunisian Dinar (TND)'},
    {'symbol': '₲', 'name': 'Paraguayan Guaraní (PYG)'},
    {'symbol': 'ARS', 'name': 'Argentine Peso (ARS)'},
    {'symbol': 'CLP', 'name': 'Chilean Peso (CLP)'},
    {'symbol': 'COP', 'name': 'Colombian Peso (COP)'},
    {'symbol': 'MXN', 'name': 'Mexican Peso (MXN)'},
    {'symbol': 'R\$', 'name': 'Brazilian Real (BRL)'},
    {'symbol': 'PEN', 'name': 'Peruvian Sol (PEN)'},
    {'symbol': 'UYU', 'name': 'Uruguayan Peso (UYU)'},
    {'symbol': 'BOB', 'name': 'Bolivian Boliviano (BOB)'},
    {'symbol': 'VES', 'name': 'Venezuelan Bolívar Soberano (VES)'},
    {'symbol': '₴', 'name': 'Ukrainian Hryvnia (UAH)'},
    {'symbol': 'RON', 'name': 'Romanian Leu (RON)'},
    {'symbol': 'BGN', 'name': 'Bulgarian Lev (BGN)'},
    {'symbol': 'RSD', 'name': 'Serbian Dinar (RSD)'},
    {'symbol': 'HRK', 'name': 'Croatian Kuna (HRK)'},
    {'symbol': 'CZK', 'name': 'Czech Koruna (CZK)'},
    {'symbol': 'HUF', 'name': 'Hungarian Forint (HUF)'},
    {'symbol': 'ISK', 'name': 'Icelandic Króna (ISK)'},
    {'symbol': '₾', 'name': 'Georgian Lari (GEL)'},
    {'symbol': '֏', 'name': 'Armenian Dram (AMD)'},
    {'symbol': '₼', 'name': 'Azerbaijani Manat (AZN)'},
    {'symbol': '₸', 'name': 'Kazakhstani Tenge (KZT)'},
    {'symbol': 'лв', 'name': 'Bulgarian Lev (BGN)'},
    {'symbol': '₭', 'name': 'Lao Kip (LAK)'},
    {'symbol': '៛', 'name': 'Cambodian Riel (KHR)'},
    {'symbol': '₮', 'name': 'Mongolian Tugrik (MNT)'},
    {'symbol': 'रु', 'name': 'Nepalese Rupee (NPR)'},
    {'symbol': '₨', 'name': 'Pakistani Rupee (PKR)'},
    {'symbol': '₨', 'name': 'Sri Lankan Rupee (LKR)'},
    {'symbol': '৳', 'name': 'Bangladeshi Taka (BDT)'},
    {'symbol': 'MVR', 'name': 'Maldivian Rufiyaa (MVR)'},
    {'symbol': 'FJ\$', 'name': 'Fiji Dollar (FJD)'},
    {'symbol': 'TOP', 'name': 'Tongan Paʻanga (TOP)'},
    {'symbol': 'WST', 'name': 'Samoan Tala (WST)'},
    {'symbol': 'XPF', 'name': 'CFP Franc (XPF)'},
    {'symbol': 'JMD', 'name': 'Jamaican Dollar (JMD)'},
    {'symbol': 'TTD', 'name': 'Trinidad and Tobago Dollar (TTD)'},
    {'symbol': 'BBD', 'name': 'Barbadian Dollar (BBD)'},
    {'symbol': 'BSD', 'name': 'Bahamian Dollar (BSD)'},
    {'symbol': 'XCD', 'name': 'East Caribbean Dollar (XCD)'},
    {'symbol': 'AWG', 'name': 'Aruban Florin (AWG)'},
    {'symbol': 'HTG', 'name': 'Haitian Gourde (HTG)'},
    {'symbol': 'PYG', 'name': 'Paraguayan Guaraní (PYG)'},
    {'symbol': 'ETB', 'name': 'Ethiopian Birr (ETB)'},
    {'symbol': 'GMD', 'name': 'Gambian Dalasi (GMD)'},
    {'symbol': 'RWF', 'name': 'Rwandan Franc (RWF)'},
    {'symbol': 'BIF', 'name': 'Burundian Franc (BIF)'},
    {'symbol': 'SZL', 'name': 'Swazi Lilangeni (SZL)'},
    {'symbol': 'LSL', 'name': 'Lesotho Loti (LSL)'},
    {'symbol': 'ZMW', 'name': 'Zambian Kwacha (ZMW)'},
    {'symbol': 'MWK', 'name': 'Malawian Kwacha (MWK)'},
    {'symbol': 'NAD', 'name': 'Namibian Dollar (NAD)'},
    {'symbol': 'BWP', 'name': 'Botswanan Pula (BWP)'},
    {'symbol': 'MUR', 'name': 'Mauritian Rupee (MUR)'},
    {'symbol': 'SCR', 'name': 'Seychellois Rupee (SCR)'},
    {'symbol': 'FKP', 'name': 'Falkland Islands Pound (FKP)'},
    {'symbol': 'SHP', 'name': 'Saint Helena Pound (SHP)'},
    {'symbol': 'IMP', 'name': 'Isle of Man Pound (IMP)'},
    {'symbol': 'GIP', 'name': 'Gibraltar Pound (GIP)'},
    {'symbol': 'JEP', 'name': 'Jersey Pound (JEP)'},
    {'symbol': 'GGP', 'name': 'Guernsey Pound (GGP)'},
  ]..sort((a, b) => a['name']!.compareTo(
      b['name']!)); // Sort all currencies alphabetically except priority ones

  // Combined list with priority currencies at the top
  List<Map<String, String>> get currencies =>
      [...priorityCurrencies, ...otherCurrencies];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<Map<String, String>> _getFilteredCurrencies() {
    if (_searchQuery.isEmpty) {
      return currencies;
    }
    final query = _searchQuery.toLowerCase();
    return currencies
        .where((currency) =>
            currency['name']!.toLowerCase().contains(query) ||
            currency['symbol']!.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _getFilteredCurrencies();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search currencies...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Currency Settings'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              _isSearching ? _stopSearch() : _startSearch();
            },
          )
        ],
      ),
      body: Consumer<CurrencyProvider>(
        builder: (context, provider, _) {
          return ListView.builder(
            itemCount: filteredCurrencies.length,
            itemBuilder: (context, index) {
              final currency = filteredCurrencies[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4), // Reduced vertical padding
                visualDensity: VisualDensity(vertical: -4), // Reduced height
                leading: Container(
                  width: 40, // Slightly smaller
                  height: 40, // Slightly smaller
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E5C88).withOpacity(0.15)
                        : const Color(0xFF2E5C88).withOpacity(0.1),
                  ),
                  child: Text(
                    currency['symbol']!,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold), // Reduced font size
                  ),
                ),
                title: Text(currency['name']!),
                trailing: provider.currencySymbol == currency['symbol']
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  provider.setCurrencySymbol(currency['symbol']!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Currency set to ${currency['name']}'),
                        duration: const Duration(seconds: 1)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
