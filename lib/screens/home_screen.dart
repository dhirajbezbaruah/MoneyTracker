import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_tracker/main.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/transaction_provider.dart';
import '../providers/currency_provider.dart';
import '../models/monthly_budget.dart';
import '../widgets/expenses_pie_chart.dart';
import '../widgets/add_transaction_dialog.dart';
import 'package:money_tracker/widgets/banner_ad_widget.dart';
import 'package:money_tracker/services/analytics_service.dart';
import '../services/app_rating_service.dart';
import '../services/deep_link_service.dart';

// Import the global instance from main.dart
import '../main.dart' show appRatingService;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime selectedDate;
  final _budgetController = TextEditingController();

  final _availableIcons = {
    'person': Icons.person,
    'person_2': Icons.person_2,
    'person_3': Icons.person_3,
    'person_4': Icons.person_4,
    'face': Icons.face,
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

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('home_screen_viewed'); // Track screen view
    selectedDate = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<TransactionProvider>();
      final currentMonth = DateFormat('yyyy-MM').format(selectedDate);
      provider.loadCurrentBudget(currentMonth);
      provider.loadTransactions(currentMonth);
      provider.loadCategories();

      // Show rating prompt after a delay
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        await appRatingService.showRatingDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _changeMonth(int months) {
    final now = DateTime.now();
    final futureLimit = DateTime(now.year, now.month + 6, 1);
    final pastLimit = DateTime(now.year, now.month - 36, 1);

    final newDate = DateTime(selectedDate.year, selectedDate.month + months);

    // Check if the new date would be within limits
    if (newDate.isAfter(futureLimit) || newDate.isBefore(pastLimit)) {
      return;
    }

    setState(() {
      selectedDate = newDate;
      final currentMonth = DateFormat('yyyy-MM').format(selectedDate);
      final provider = context.read<TransactionProvider>();
      provider.loadCurrentBudget(currentMonth);
      provider.loadTransactions(currentMonth);
    });
  }

  void _showBudgetDialog() {
    final provider = context.read<TransactionProvider>();
    final currencyProvider = context.read<CurrencyProvider>();
    _budgetController.text = provider.currentBudget?.amount.toString() ?? '';
    bool isRecurring = provider.currentBudget?.isRecurring ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Set Monthly Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, _) {
                  return TextField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Budget Amount',
                      prefixText: currencyProvider.currencySymbol,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Recurring Budget'),
                subtitle: const Text('Automatically set for future months'),
                value: isRecurring,
                onChanged: (value) {
                  setState(() => isRecurring = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(_budgetController.text);
                if (amount != null) {
                  final selectedProfile = provider.selectedProfile;
                  if (selectedProfile != null) {
                    provider.setBudget(
                      MonthlyBudget(
                        month: DateFormat('yyyy-MM').format(selectedDate),
                        amount: amount,
                        profileId: selectedProfile.id!,
                        isRecurring: isRecurring,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );
  }

  void _shareApp() {
    // Share the app using our DeepLinkService
    final deepLinkService = DeepLinkService();
    deepLinkService.shareApp();

    // Track this event for analytics
    AnalyticsService.logAppShare();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      if (selectedDate.isAfter(
                        DateTime.now().subtract(const Duration(days: 36 * 30)),
                      )) {
                        _changeMonth(-1);
                      }
                    },
                  ),
                  Text(
                    DateFormat('MMM yyyy').format(selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final now = DateTime.now();
                      final futureLimit = DateTime(now.year, now.month + 6, 1);
                      if (selectedDate.isBefore(futureLimit)) {
                        _changeMonth(1);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Add Share App button
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Track share event for analytics
                AnalyticsService.logAppShare();
                // Share the app
                _shareApp();
              },
              tooltip: 'Share App',
            ),
            Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final profile = provider.selectedProfile;
                return Row(
                  children: [
                    Text(
                      profile?.name ?? 'Profile 1',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2E5C88).withOpacity(0.15)
                              : const Color(0xFF2E5C88).withOpacity(0.1),
                      child: Icon(
                        _availableIcons[profile?.iconName] ?? Icons.person,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2E5C88)
                            : const Color(0xFF2E5C88),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                final currentMonth = DateFormat('yyyy-MM').format(selectedDate);
                final budget = provider.currentBudget?.amount ?? 0;
                final expenses = provider.getTotalExpenses(currentMonth);
                final income = provider.getTotalIncome(currentMonth);
                final remaining = budget - expenses;
                final expensesByCategory = provider.getExpensesByCategory(
                  currentMonth,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    provider.loadCurrentBudget(currentMonth);
                    provider.loadTransactions(currentMonth);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF1E3D59)
                                      : const Color(0xFF2E5C88),
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF15294D)
                                      : const Color(0xFF1E3D59),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF1E3D59).withOpacity(0.3)
                                      : const Color(0xFF2E5C88)
                                          .withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.account_balance_wallet,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'Monthly Budget',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Consumer<CurrencyProvider>(
                                          builder:
                                              (context, currencyProvider, _) {
                                            return Text(
                                              '${currencyProvider.currencySymbol}${budget.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black
                                                        .withOpacity(0.2),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: InkWell(
                                              onTap: _showBudgetDialog,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.edit,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Edit',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (income > 0) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Consumer<CurrencyProvider>(
                                                  builder: (context,
                                                      currencyProvider, _) {
                                                    return Text(
                                                      '${currencyProvider.currencySymbol}${income.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                if (budget > 0) ...[
                                  Container(
                                    height: 10,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: expenses / budget <= 1
                                          ? expenses / budget
                                          : 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: expenses <= budget
                                                ? [
                                                    Colors.white
                                                        .withOpacity(0.95),
                                                    Colors.white
                                                        .withOpacity(0.7),
                                                  ]
                                                : [
                                                    Colors.red.shade300,
                                                    Colors.redAccent.shade100,
                                                  ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          boxShadow: expenses <= budget
                                              ? []
                                              : [
                                                  BoxShadow(
                                                    color:
                                                        Colors.red.withOpacity(
                                                      0.4,
                                                    ),
                                                    blurRadius: 5,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Used: ${(expenses / budget * 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.85),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Left: ${(100 - (expenses / budget * 100)).clamp(0, 100).toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: remaining >= 0
                                              ? Colors.white.withOpacity(0.85)
                                              : Colors.red.shade200,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              const Color(0xFF1E3D59),
                                              const Color(0xFF15294D)
                                            ]
                                          : [
                                              const Color(0xFF2E5C88),
                                              const Color(0xFF1E3D59)
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF1E3D59)
                                                .withOpacity(0.3)
                                            : const Color(0xFF2E5C88)
                                                .withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.arrow_downward,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.shade300
                                                  : Colors.red.shade200,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Expenses',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.shade300
                                                  : Colors.red.shade200,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Consumer<CurrencyProvider>(
                                        builder:
                                            (context, currencyProvider, _) {
                                          return Text(
                                            '${currencyProvider.currencySymbol}${expenses.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.shade300
                                                  : Colors.red.shade200,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.25),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? [
                                              const Color(0xFF1E3D59),
                                              const Color(0xFF15294D)
                                            ]
                                          : [
                                              const Color(0xFF2E5C88),
                                              const Color(0xFF1E3D59)
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF1E3D59)
                                                .withOpacity(0.3)
                                            : const Color(0xFF2E5C88)
                                                .withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              remaining >= 0
                                                  ? Icons.account_balance_wallet
                                                  : Icons.warning,
                                              color: remaining >= 0
                                                  ? Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green.shade300
                                                      : Colors.green.shade200
                                                  : Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.red.shade300
                                                      : Colors.red.shade200,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Remaining',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: remaining >= 0
                                                  ? Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green.shade300
                                                      : Colors.green.shade200
                                                  : Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.red.shade300
                                                      : Colors.red.shade200,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Consumer<CurrencyProvider>(
                                        builder:
                                            (context, currencyProvider, _) {
                                          return Text(
                                            '${currencyProvider.currencySymbol}${remaining.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: remaining >= 0
                                                  ? Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.green.shade300
                                                      : Colors.green.shade200
                                                  : Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.red.shade300
                                                      : Colors.red.shade200,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black
                                                      .withOpacity(0.25),
                                                  blurRadius: 2,
                                                  offset: const Offset(0, 1),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2E5C88).withOpacity(0.2)
                                    : const Color(0xFF2E5C88).withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(
                                                0xFF2E5C88,
                                              ).withOpacity(0.15)
                                            : const Color(
                                                0xFF2E5C88,
                                              ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.pie_chart,
                                        size: 22,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF81C784)
                                            : const Color(0xFF2E5C88),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Expenses by Category',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(
                                                0xFF2E5C88,
                                              ).withOpacity(0.15)
                                            : const Color(
                                                0xFF2E5C88,
                                              ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        expensesByCategory.isEmpty
                                            ? '0'
                                            : '${expensesByCategory.length}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF81C784)
                                              : const Color(0xFF2E5C88),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ExpensesPieChart(
                                  expenses: expensesByCategory,
                                  totalExpenses: expenses,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2E5C88)
            : const Color(0xFF2E5C88),
        elevation: 4,
      ),
    );
  }
}

class EmptyPieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - paint.strokeWidth / 2;

    // Draw the full circle
    canvas.drawCircle(center, radius, paint);

    // Draw dashed lines to create segments
    final dashPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const segments = 6; // Number of segments
    for (var i = 0; i < segments; i++) {
      final angle = (i * 2 * 3.14159) / segments;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), dashPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
