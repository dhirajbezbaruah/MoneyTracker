import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
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
  ThemeMode _selectedThemeMode = ThemeMode.system;
  String? _nameError; // Add error state

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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 360,
            maxHeight:
                MediaQuery.of(context).size.height * 0.7, // Reduced from 0.8
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12), // Reduced vertical padding
                  shrinkWrap: true,
                  children: [
                    _buildThemeSection(),
                    const SizedBox(height: 16), // Reduced from 20
                    _buildProfileSection(),
                    const SizedBox(height: 16), // Reduced from 20
                    _buildCurrencySection(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12), // Reduced from 16
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E5C88), Color(0xFF1E3D59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome to Money Track!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Set up your profile and preferences. you can update them later in settings.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Card(
          margin: EdgeInsets.zero,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: InkWell(
            onTap: _showThemeSelector,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10), // Reduced from 12
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5C88).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedThemeMode == ThemeMode.system
                          ? Icons.brightness_auto
                          : _selectedThemeMode == ThemeMode.light
                              ? Icons.light_mode
                              : Icons.dark_mode,
                      color: const Color(0xFF2E5C88),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Theme',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _selectedThemeMode == ThemeMode.system
                              ? 'System Theme'
                              : _selectedThemeMode == ThemeMode.light
                                  ? 'Light Theme'
                                  : 'Dark Theme',
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: _selectedThemeMode == ThemeMode.system
                    ? const Color(0xFF2E5C88)
                    : null,
              ),
              title: const Text('System Theme'),
              subtitle: const Text('Follow system settings'),
              trailing: _selectedThemeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                  : null,
              onTap: () {
                setState(() => _selectedThemeMode = ThemeMode.system);
                context.read<ThemeProvider>().setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.light_mode,
                color: _selectedThemeMode == ThemeMode.light
                    ? const Color(0xFF2E5C88)
                    : null,
              ),
              title: const Text('Light Theme'),
              subtitle: const Text('Light colors and white background'),
              trailing: _selectedThemeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                  : null,
              onTap: () {
                setState(() => _selectedThemeMode = ThemeMode.light);
                context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: _selectedThemeMode == ThemeMode.dark
                    ? const Color(0xFF2E5C88)
                    : null,
              ),
              title: const Text('Dark Theme'),
              subtitle: const Text('Dark colors and black background'),
              trailing: _selectedThemeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                  : null,
              onTap: () {
                setState(() => _selectedThemeMode = ThemeMode.dark);
                context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        Card(
          margin: EdgeInsets.zero,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8, // Reduced from 12
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(
                          () => _nameError = null), // Clear error on change
                      decoration: InputDecoration(
                        labelText: 'Profile Name',
                        hintText: 'Enter your name or nickname',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8, // Reduced from 12
                        ),
                        isDense: true,
                        counterText: '', // Hide character counter
                        errorText: _nameError,
                      ),
                      style: const TextStyle(fontSize: 14), // Reduced font size
                      maxLength: 10,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              InkWell(
                onTap: _showIconSelector,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8, // Reduced from 12
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E5C88).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _icons[_selectedIcon],
                          color: const Color(0xFF2E5C88),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Profile Icon',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Tap to change',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showIconSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Profile Icon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            Container(
              height: 300,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _icons.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final entry = _icons.entries.elementAt(index);
                  final isSelected = _selectedIcon == entry.key;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedIcon = entry.key);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E5C88).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2E5C88)
                              : Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          entry.value,
                          size: 30,
                          color: isSelected ? const Color(0xFF2E5C88) : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Currency',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
              width: 0.5,
            ),
          ),
          child: InkWell(
            onTap: _showCurrencySelector,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5C88).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _selectedCurrencySymbol,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E5C88),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Currency',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          currencies.firstWhere(
                            (c) => c['name']!.contains('($_selectedCurrency)'),
                            orElse: () => _priorityCurrencies.first,
                          )['name']!,
                          style: TextStyle(
                            fontSize: 15,
                            overflow: TextOverflow.ellipsis,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
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
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E5C88),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'See All',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final code = RegExp(r'\(([^)]+)\)')
                          .firstMatch(currency['name']!)
                          ?.group(1) ??
                      '';
                  final isSelected = code == _selectedCurrency;

                  return Column(
                    children: [
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2E5C88).withOpacity(0.1)
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            currency['symbol']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isSelected ? const Color(0xFF2E5C88) : null,
                            ),
                          ),
                        ),
                        title: Text(currency['name']!),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCurrency = code;
                            _selectedCurrencySymbol = currency['symbol']!;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 1, indent: 70),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.05)
            : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44, // Setting a specific height for the button
        child: FilledButton(
          onPressed: _onGetStarted,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E5C88),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0.5,
            padding: EdgeInsets.zero, // Remove padding as we use a fixed height
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          child: const Text('Get Started'),
        ),
      ),
    );
  }

  void _onGetStarted() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Please enter a profile name';
      });
      return;
    }

    // Save theme preference
    final themeProvider = context.read<ThemeProvider>();
    themeProvider.setThemeMode(_selectedThemeMode);

    // Save currency preference
    final currencyProvider = context.read<CurrencyProvider>();
    await currencyProvider.setCurrency(
        _selectedCurrency, _selectedCurrencySymbol);

    // Create and save profile
    final transactionProvider = context.read<TransactionProvider>();
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
  }
}
