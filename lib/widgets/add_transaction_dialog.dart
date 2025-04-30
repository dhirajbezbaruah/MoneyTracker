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
  DateTime? _recurrenceEndDate;
  bool _isRecurringExpanded = false;

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
          surfaceTintColor: Colors.transparent,
          elevation: 8.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      ),
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(
          _type == 'expense' ? 'Add Expense' : 'Add Income',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: mainColor,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transaction Type Selector
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceVariant.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'expense',
                            label: const Text('Expense'),
                            icon: Icon(Icons.arrow_downward, color: mainColor),
                          ),
                          ButtonSegment(
                            value: 'income',
                            label: const Text('Income'),
                            icon: Icon(Icons.arrow_upward, color: mainColor),
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
                          backgroundColor:
                              MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return mainColor.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          }),
                          foregroundColor: MaterialStateProperty.all(mainColor),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Amount Field
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, _) {
                      return TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '${currencyProvider.currencySymbol} ',
                          prefixStyle: TextStyle(
                              color: mainColor, fontWeight: FontWeight.bold),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor:
                              colorScheme.surfaceVariant.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                        ),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                        autofocus: true,
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Please enter an amount';
                          if (double.tryParse(value) == null)
                            return 'Please enter a valid number';
                          if (double.parse(value) <= 0)
                            return 'Amount must be greater than 0';
                          return null;
                        },
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).nextFocus(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                    ),
                    items: categories.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('No categories available'),
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
                    validator: (value) =>
                        value == null ? 'Please select a category' : null,
                    isExpanded: true,
                    dropdownColor: colorScheme.surface,
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 16),

                  // Date Picker
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    leading: Icon(Icons.calendar_today, color: mainColor),
                    title: Text(
                      DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 180)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme:
                                  colorScheme.copyWith(primary: mainColor),
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
                  ),

                  // Recurring Transaction Section
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: Text(
                      'Recurring Transaction',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: mainColor,
                      ),
                    ),
                    subtitle: Text(
                      _isRecurring ? 'Repeats monthly' : 'One-time transaction',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    leading: Icon(Icons.repeat, color: mainColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    collapsedBackgroundColor:
                        colorScheme.surfaceVariant.withOpacity(0.05),
                    backgroundColor:
                        colorScheme.surfaceVariant.withOpacity(0.05),
                    children: [
                      SwitchListTile(
                        title: const Text('Enable Monthly Recurring'),
                        value: _isRecurring,
                        activeColor: mainColor,
                        onChanged: (value) {
                          setState(() {
                            _isRecurring = value;
                          });
                        },
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      if (_isRecurring) ...[
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          leading: Icon(Icons.event_repeat, color: mainColor),
                          title: Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          trailing: Text(
                            _recurrenceEndDate != null
                                ? DateFormat('MMM d, yyyy')
                                    .format(_recurrenceEndDate!)
                                : 'None (1 year)',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _recurrenceEndDate ??
                                  DateTime.now().add(const Duration(days: 365)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 5)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: colorScheme.copyWith(
                                        primary: mainColor),
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
                        ),
                      ],
                    ],
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isRecurringExpanded = expanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
                  recurrenceFrequency: _isRecurring ? 'monthly' : null,
                  recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
                );
                context.read<TransactionProvider>().addTransaction(transaction);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
