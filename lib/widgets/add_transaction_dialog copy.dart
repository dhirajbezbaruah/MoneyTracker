import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as app_models;
import '../providers/transaction_provider.dart';
import '../providers/currency_provider.dart';

class AddTransactionDialog extends StatefulWidget {
  const AddTransactionDialog({super.key});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'expense';
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  String _recurrenceFrequency = 'monthly';
  DateTime? _recurrenceEndDate;

  @override
  Widget build(BuildContext context) {
    final allCategories = context.watch<TransactionProvider>().categories;
    final categories = allCategories.where((c) => c.type == _type).toList();
    final selectedProfile = context.read<TransactionProvider>().selectedProfile;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mainColor = const Color(0xFF2E5C88);

    return Theme(
      data: theme.copyWith(
        dialogTheme: DialogTheme(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
      child: AlertDialog(
        title: Text(_type == 'expense' ? 'Add Expense' : 'Add Income'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'expense',
                      label: const Text('Expense'),
                      icon: const Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: const Text('Income'),
                      icon: const Icon(Icons.arrow_upward),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _type = newSelection.first;
                      _selectedCategoryId = null;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((
                      states,
                    ) {
                      if (states.contains(MaterialState.selected)) {
                        return mainColor.withOpacity(0.1);
                      }
                      return null;
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<CurrencyProvider>(
                  builder: (context, currencyProvider, _) {
                    return TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: currencyProvider.currencySymbol,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                      ),
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                  ),
                  items: categories.isEmpty
                      ? [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No categories'),
                          ),
                        ]
                      : categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  isExpanded: true,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(
                        const Duration(days: 180),
                      ), // 6 months ahead
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(
                              context,
                            ).colorScheme.copyWith(primary: mainColor),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surfaceVariant.withOpacity(0.1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: mainColor, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withOpacity(0.9)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recurring transaction section
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Recurring Transaction'),
                  subtitle: Text(_isRecurring
                      ? 'This transaction will repeat $_recurrenceFrequency'
                      : 'One-time transaction'),
                  value: _isRecurring,
                  activeColor: mainColor,
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value;
                    });
                  },
                ),

                // Show frequency options only if recurring is enabled
                if (_isRecurring) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _recurrenceFrequency,
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text('Daily'),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Weekly'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                      DropdownMenuItem(
                        value: 'yearly',
                        child: Text('Yearly'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _recurrenceFrequency = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _recurrenceEndDate ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                            const Duration(days: 365 * 5)), // 5 years ahead
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context)
                                  .colorScheme
                                  .copyWith(primary: mainColor),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() {
                          _recurrenceEndDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.surfaceVariant.withOpacity(0.1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_repeat,
                                  color: mainColor, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _recurrenceEndDate != null
                                ? DateFormat('MMM d, yyyy')
                                    .format(_recurrenceEndDate!)
                                : 'None (1 year)',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final amount = double.parse(_amountController.text);
                final transaction = app_models.Transaction(
                  amount: amount,
                  type: _type,
                  categoryId: _selectedCategoryId!,
                  description: _descriptionController.text.isEmpty
                      ? null
                      : _descriptionController.text,
                  date: _selectedDate,
                  profileId: selectedProfile!.id!,
                  isRecurring: _isRecurring,
                  recurrenceFrequency:
                      _isRecurring ? _recurrenceFrequency : null,
                  recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
                );
                context.read<TransactionProvider>().addTransaction(transaction);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
