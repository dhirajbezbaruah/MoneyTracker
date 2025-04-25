import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_alert_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/budget_alert.dart';
import '../models/category.dart';

class BudgetAlertsScreen extends StatefulWidget {
  const BudgetAlertsScreen({super.key});

  @override
  State<BudgetAlertsScreen> createState() => _BudgetAlertsScreenState();
}

class _BudgetAlertsScreenState extends State<BudgetAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetAlertProvider>().loadAlerts();
      context.read<TransactionProvider>().loadCategories();
    });
  }

  void _showCreateAlertDialog(BuildContext context, List<Category> categories) {
    Category? selectedCategory;
    double threshold = 0;
    bool isPercentage = true;
    bool isOverallBudget = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Budget Alert'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Overall Budget Alert'),
                subtitle: const Text('Alert for total monthly spending'),
                value: isOverallBudget,
                onChanged: (value) {
                  setState(() {
                    isOverallBudget = value;
                    if (value) {
                      selectedCategory = null;
                    }
                  });
                },
              ),
              if (!isOverallBudget) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<Category>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .where((c) => c.type == 'expense')
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (category) {
                    setState(() => selectedCategory = category);
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText:
                      isPercentage ? 'Threshold (%)' : 'Threshold Amount',
                  suffixText: isPercentage ? '%' : '₹',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => threshold = double.tryParse(value) ?? 0,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Set as Percentage'),
                value: isPercentage,
                onChanged: (value) {
                  setState(() => isPercentage = value);
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
                if ((isOverallBudget || selectedCategory != null) &&
                    threshold > 0) {
                  context.read<BudgetAlertProvider>().addAlert(
                        BudgetAlert(
                          categoryId:
                              isOverallBudget ? null : selectedCategory!.id!,
                          threshold: threshold,
                          isPercentage: isPercentage,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Alerts'),
      ),
      body: Consumer2<BudgetAlertProvider, TransactionProvider>(
        builder: (context, alertProvider, transactionProvider, child) {
          final alerts = alertProvider.alerts;
          final categories = transactionProvider.categories;

          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2E5C88).withOpacity(0.15)
                          : const Color(0xFF2E5C88).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 64,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2E5C88)
                          : const Color(0xFF2E5C88),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No budget alerts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add alerts to monitor your spending',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () =>
                        _showCreateAlertDialog(context, categories),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Alert'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2E5C88)
                              : const Color(0xFF2E5C88),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: alerts.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final isOverallAlert = alert.categoryId == null;
              final categoryName = isOverallAlert
                  ? 'Overall Budget'
                  : categories
                      .firstWhere(
                        (c) => c.id == alert.categoryId,
                        orElse: () =>
                            Category(name: 'Unknown', type: 'expense'),
                      )
                      .name;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    isOverallAlert
                        ? Icons.account_balance_wallet
                        : Icons.category,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E5C88)
                        : const Color(0xFF2E5C88),
                  ),
                  title: Text(categoryName),
                  subtitle: Text(
                    alert.isPercentage
                        ? '${alert.threshold}% of budget'
                        : '₹${alert.threshold.toStringAsFixed(0)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: alert.enabled,
                        onChanged: (enabled) {
                          alertProvider.updateAlert(
                            alert.copyWith(enabled: enabled),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => alertProvider.deleteAlert(alert.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateAlertDialog(
          context,
          context.read<TransactionProvider>().categories,
        ),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2E5C88)
            : const Color(0xFF2E5C88),
      ),
    );
  }
}
