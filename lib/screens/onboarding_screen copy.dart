import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money_tracker/models/monthly_budget.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/theme_provider.dart';
import '../models/profile.dart';
import '../screens/currency_settings_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;
  bool _showContent = false;

  final _nameController = TextEditingController();
  final _budgetController = TextEditingController(text: '5000');
  String _selectedCurrency = 'INR';
  String _selectedCurrencySymbol = '₹';
  String _selectedIcon = 'person';
  ThemeMode _selectedThemeMode = ThemeMode.system;
  String? _nameError;
  String? _budgetError;

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
  void initState() {
    super.initState();

    // Set up animations
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Delay showing content for initial animation
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showContent = true;
        _fadeController.forward();
        _slideController.forward();
      });
    });

    // Set default values from system
    final brightness = MediaQuery.platformBrightnessOf(context);
    if (brightness == Brightness.dark) {
      _selectedThemeMode = ThemeMode.dark;
    } else if (brightness == Brightness.light) {
      _selectedThemeMode = ThemeMode.light;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _budgetController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Reset animations and replay them for the new page
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _submitOnboarding() async {
    final name = _nameController.text.trim();
    final budgetText = _budgetController.text.trim();

    // Set default name if empty
    final profileName = name.isEmpty ? 'Profile 1' : name;

    // Validate inputs
    if (budgetText.isEmpty) {
      setState(() {
        _budgetError = 'Please enter your monthly budget';
      });
      return;
    }

    final budget = double.tryParse(budgetText);
    if (budget == null) {
      setState(() {
        _budgetError = 'Please enter a valid budget amount';
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
      name: profileName,
      iconName: _selectedIcon,
      createdAt: DateTime.now(),
      isSelected: true,
    );
    await transactionProvider.createProfile(profile);

    // Ensure profile is loaded and selected
    if (mounted) {
      await transactionProvider.loadProfiles();

      // Set monthly budget - using the current month
      final currentMonth = DateTime.now();
      final monthStr =
          "${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}";

      // Import the MonthlyBudget model
      await transactionProvider.setBudget(MonthlyBudget(
        month: monthStr,
        amount: budget,
        profileId: transactionProvider.selectedProfile!.id!,
      ));

      // Load the budget so it appears on the home screen
      await transactionProvider.loadCurrentBudget(monthStr);
    }

    // Navigate to main screen
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            const Divider(height: 1),
            _buildThemeOption(
              icon: Icons.brightness_auto,
              title: 'System Theme',
              subtitle: 'Follow system settings',
              themeMode: ThemeMode.system,
            ),
            const Divider(height: 1),
            _buildThemeOption(
              icon: Icons.light_mode,
              title: 'Light Theme',
              subtitle: 'Light colors and white background',
              themeMode: ThemeMode.light,
            ),
            const Divider(height: 1),
            _buildThemeOption(
              icon: Icons.dark_mode,
              title: 'Dark Theme',
              subtitle: 'Dark colors and black background',
              themeMode: ThemeMode.dark,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode themeMode,
  }) {
    final isSelected = _selectedThemeMode == themeMode;
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E5C88).withOpacity(0.1)
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFF2E5C88) : null,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF2E5C88) : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF2E5C88))
          : null,
      onTap: () {
        setState(() => _selectedThemeMode = themeMode);
        Navigator.pop(context);
      },
    );
  }

  void _showIconSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Select Profile Icon',
                style: TextStyle(
                  fontSize: 20,
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
              padding: const EdgeInsets.all(20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _icons.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final entry = _icons.entries.elementAt(index);
                  final isSelected = _selectedIcon == entry.key;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedIcon = entry.key);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2E5C88).withOpacity(0.15)
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2E5C88)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          entry.value,
                          size: 32,
                          color: isSelected ? const Color(0xFF2E5C88) : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  TextButton.icon(
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
                    icon: const Icon(Icons.list_alt_rounded),
                    label: const Text('See All'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2E5C88),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: currencies.length,
                physics: const BouncingScrollPhysics(),
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2E5C88).withOpacity(0.15)
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              currency['symbol']!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? const Color(0xFF2E5C88) : null,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          currency['name']!,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? const Color(0xFF2E5C88) : null,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF2E5C88))
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedCurrency = code;
                            _selectedCurrencySymbol = currency['symbol']!;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      Divider(
                          height: 1,
                          indent: 76,
                          color: Colors.grey.withOpacity(0.2)),
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

  @override
  Widget build(BuildContext context) {
    // Set status bar color to match the app theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E5C88), Color(0xFF1E3D59)],
              ),
            ),
          ),

          // Wave pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/images/wave_pattern.png',
                fit: BoxFit.cover,
              ),
              // If you don't have this asset, replace with a Container:
              // child: CustomPaint(
              //   painter: WavePatternPainter(),
              // ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Color(0xFF2E5C88),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Budget Tracker',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Page dots
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildWelcomePage(),
                      _buildProfilePage(),
                      _buildSettingsPage(),
                    ],
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _currentPage > 0
                          ? TextButton.icon(
                              onPressed: _previousPage,
                              icon: const Icon(Icons.arrow_back_ios_new),
                              label: const Text('Back'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            )
                          : const SizedBox(width: 100),

                      // Next button
                      ElevatedButton.icon(
                        onPressed: _nextPage,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(_currentPage < 2 ? 'Next' : 'Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2E5C88),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    if (!_showContent) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Color(0xFF2E5C88),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Welcome to Budget Tracker',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Track your expenses, manage your finances, and achieve your financial goals with our simple and intuitive app.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your privacy is important to us. No profile data or transaction data is collected by the developer or shared with third parties.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    if (!_showContent) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // Added consistent top spacing
              const Text(
                'Create Your Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tell us a bit about yourself to personalize your experience',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),

              // Profile name input
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() => _nameError = null),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: 'Profile Name',
                  labelStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  hintText: 'Enter your name or nickname',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  errorText: _nameError,
                  errorStyle: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.white70,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8A80),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8A80),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ), // Added consistent padding
                ),
              ),

              const SizedBox(height: 24),

              // Profile icon selection
              InkWell(
                onTap: _showIconSelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  height: 80, // Fixed height for consistency
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _icons[_selectedIcon],
                          color: const Color(0xFF2E5C88),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Added for vertical centering
                          children: [
                            Text(
                              'Profile Icon',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose an icon for your profile',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Theme selection
              InkWell(
                onTap: _showThemeSelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  height: 80, // Fixed height for consistency
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _selectedThemeMode == ThemeMode.system
                              ? Icons.brightness_auto
                              : _selectedThemeMode == ThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                          color: const Color(0xFF2E5C88),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Added for vertical centering
                          children: [
                            const Text(
                              'App Theme',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedThemeMode == ThemeMode.system
                                  ? 'System Theme'
                                  : _selectedThemeMode == ThemeMode.light
                                      ? 'Light Theme'
                                      : 'Dark Theme',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPage() {
    if (!_showContent) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Your Budget',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Define your monthly budget and preferred currency',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 32),

              // Budget setup with dynamic currency symbol
              TextField(
                controller: _budgetController,
                onChanged: (_) => setState(() => _budgetError = null),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Monthly Budget',
                  labelStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  hintText: 'Enter your monthly budget',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  errorText: _budgetError,
                  errorStyle: const TextStyle(
                    color: Color(0xFFFF8A80),
                    fontSize: 14,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _selectedCurrencySymbol,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8A80),
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8A80),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Currency selection - now after budget
              InkWell(
                onTap: _showCurrencySelector,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _selectedCurrencySymbol,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E5C88),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Currency',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencies.firstWhere(
                                (c) =>
                                    c['name']!.contains('($_selectedCurrency)'),
                                orElse: () => _priorityCurrencies.first,
                              )['name']!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Almost done section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Color(0xFF2E5C88),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Almost Done!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Click Complete to start using Budget Tracker',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Optional: If you don't have a wave pattern image asset, you can use a CustomPainter
class WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();

    for (var i = 0; i < size.height; i += 20) {
      path.moveTo(0, i.toDouble());

      for (var x = 0; x < size.width; x += 40) {
        path.quadraticBezierTo(
          x + 10.0,
          i + 10.0,
          x + 20.0,
          i.toDouble(),
        );
        path.quadraticBezierTo(
          x + 30.0,
          i - 10.0,
          x + 40.0,
          i.toDouble(),
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
