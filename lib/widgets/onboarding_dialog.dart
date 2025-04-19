import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/profile.dart';
import '../screens/currency_settings_screen.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key});

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  final _nameController = TextEditingController();
  String _selectedCurrency = 'INR';
  String _selectedCurrencySymbol = '₹';
  String _selectedIcon = 'person';

  // Keep the same icons as in profile settings
  final _icons = {
    'person': Icons.person,
    'face': Icons.face,
    'person_2': Icons.person_2,
    'person_3': Icons.person_3,
    'person_4': Icons.person_4,
    'face_2': Icons.face_2,
    'face_3': Icons.face_3,
    'face_4': Icons.face_4,
    'face_5': Icons.face_5,
    'face_6': Icons.face_6,
    'family_restroom': Icons.family_restroom,
    'diversity_1': Icons.diversity_1,
    'diversity_2': Icons.diversity_2,
    'diversity_3': Icons.diversity_3,
    'group': Icons.group,
    'groups': Icons.groups,
    'school': Icons.school,
    'work': Icons.work,
  };

  // Keep the same currency lists as settings screen
  static final List<Map<String, String>> _priorityCurrencies = [
    {'symbol': '₹', 'name': 'Indian Rupee (INR)'},
    {'symbol': '\$', 'name': 'US Dollar (USD)'},
  ];

  static final List<Map<String, String>> _otherCurrencies = [
    {'symbol': '€', 'name': 'Euro (EUR)'},
    {'symbol': '£', 'name': 'British Pound (GBP)'},
    {'symbol': '¥', 'name': 'Japanese Yen (JPY)'},
    {'symbol': '¥', 'name': 'Chinese Yuan (CNY)'},
    {'symbol': '₩', 'name': 'South Korean Won (KRW)'},
    {'symbol': '₽', 'name': 'Russian Ruble (RUB)'},
    {'symbol': '৳', 'name': 'Bangladeshi Taka (BDT)'},
    {'symbol': '₨', 'name': 'Pakistani Rupee (PKR)'},
    {'symbol': '₨', 'name': 'Sri Lankan Rupee (LKR)'},
    {'symbol': 'CHF', 'name': 'Swiss Franc (CHF)'},
    {'symbol': 'CA\$', 'name': 'Canadian Dollar (CAD)'},
    {'symbol': 'A\$', 'name': 'Australian Dollar (AUD)'},
    {'symbol': 'HK\$', 'name': 'Hong Kong Dollar (HKD)'},
    {'symbol': 'SGD', 'name': 'Singapore Dollar (SGD)'},
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
  ]..sort((a, b) => a['name']!.compareTo(b['name']!));

  List<Map<String, String>> get currencies =>
      [..._priorityCurrencies, ..._otherCurrencies];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to Money Track!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Let\'s set up your profile and currency preferences. You can change them later in the settings.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Profile Name',
                  hintText: 'Enter your name or nickname',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedIcon,
                decoration: const InputDecoration(
                  labelText: 'Profile Icon',
                  border: OutlineInputBorder(),
                ),
                items: _icons.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.value),
                        const SizedBox(width: 8),
                        Text(entry.key.replaceAll('_', ' ').toTitleCase()),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedIcon = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Map<String, String>>(
                value: currencies.firstWhere(
                  (c) => c['name']!.contains('($_selectedCurrency)'),
                  orElse: () => _priorityCurrencies.first,
                ),
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: currencies.map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2E5C88).withOpacity(0.15)
                                    : const Color(0xFF2E5C88).withOpacity(0.1),
                          ),
                          child: Text(
                            currency['symbol']!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            currency['name']!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    final code = RegExp(r'\(([^)]+)\)')
                            .firstMatch(value['name']!)
                            ?.group(1) ??
                        '';
                    setState(() {
                      _selectedCurrency = code;
                      _selectedCurrencySymbol = value['symbol']!;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CurrencySettingsScreen(),
                    ),
                  );
                  if (result != null && mounted) {
                    setState(() {
                      _selectedCurrency = result['code'];
                      _selectedCurrencySymbol = result['symbol'];
                    });
                  }
                },
                child: const Text('See all currencies'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a profile name'),
                      ),
                    );
                    return;
                  }

                  // Save currency preference
                  final currencyProvider = context.read<CurrencyProvider>();
                  await currencyProvider.setCurrency(
                      _selectedCurrency, _selectedCurrencySymbol);

                  // Create and save profile
                  final transactionProvider =
                      context.read<TransactionProvider>();
                  final profile = Profile(
                    name: name,
                    iconName: _selectedIcon,
                    createdAt: DateTime.now(),
                    isSelected: true,
                  );
                  await transactionProvider.createProfile(profile);

                  // Ensure profile is loaded and selected
                  if (mounted) {
                    await transactionProvider.loadProfiles();
                  }

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
