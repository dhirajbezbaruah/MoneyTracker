import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart' as app_models;
import '../providers/transaction_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final allCategories = context.watch<TransactionProvider>().categories;
    final categories = allCategories.where((c) => c.type == _type).toList();
    final selectedProfile = context.read<TransactionProvider>().selectedProfile;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _type == 'expense' ? Icons.arrow_downward : Icons.arrow_upward,
            color: _type == 'expense' ? Colors.red : Colors.green,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(_type == 'expense' ? 'Add Expense' : 'Add Income'),
        ],
      ),
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
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.selected)) {
                      return _type == 'expense'
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900.withOpacity(0.3)
                              : Colors.red.shade100.withOpacity(0.3)
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade900.withOpacity(0.3)
                          : Colors.green.shade100.withOpacity(0.3);
                    }
                    return null;
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          _type == 'expense'
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300.withOpacity(0.5)
                                  : Colors.red.shade200
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.green.shade300.withOpacity(0.5)
                              : Colors.green.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color:
                          _type == 'expense'
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300.withOpacity(0.5)
                                  : Colors.red.shade200
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.green.shade300.withOpacity(0.5)
                              : Colors.green.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      width: 2,
                      color:
                          _type == 'expense'
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300
                                  : Colors.red.shade500
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.green.shade300
                              : Colors.green.shade500,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      _type == 'expense'
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900.withOpacity(0.1)
                              : Colors.red.shade50
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.shade900.withOpacity(0.1)
                          : Colors.green.shade50,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _amountController.clear(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
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
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.1),
                  prefixIcon: const Icon(Icons.category),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                items:
                    categories.isEmpty
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
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.1),
                  prefixIcon: const Icon(Icons.notes),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _descriptionController.clear(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                ),
                maxLines: 1,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary:
                                _type == 'expense'
                                    ? Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.redAccent.shade700
                                        : Colors.redAccent.shade200
                                    : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.greenAccent.shade700
                                    : Colors.greenAccent.shade200,
                          ),
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
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          _type == 'expense'
                              ? Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300.withOpacity(0.5)
                                  : Colors.red.shade200
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.green.shade300.withOpacity(0.5)
                              : Colors.green.shade200,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color:
                        _type == 'expense'
                            ? Theme.of(context).brightness == Brightness.dark
                                ? Colors.red.shade900.withOpacity(0.1)
                                : Colors.red.shade50
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.green.shade900.withOpacity(0.1)
                            : Colors.green.shade50,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 22,
                        color:
                            _type == 'expense'
                                ? Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.red.shade300
                                    : Colors.red.shade700
                                : Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.green.shade300
                                : Colors.green.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color:
                              _type == 'expense'
                                  ? Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.red.shade100
                                      : Colors.red.shade900
                                  : Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.green.shade100
                                  : Colors.green.shade900,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color:
                            _type == 'expense'
                                ? Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.red.shade300
                                    : Colors.red.shade500
                                : Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.green.shade300
                                : Colors.green.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final amount = double.parse(_amountController.text);
              final transaction = app_models.Transaction(
                amount: amount,
                type: _type,
                categoryId: _selectedCategoryId!,
                description:
                    _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                date: _selectedDate,
                profileId: selectedProfile!.id!,
              );
              context.read<TransactionProvider>().addTransaction(transaction);
              Navigator.pop(context);
            }
          },
          icon: Icon(_type == 'expense' ? Icons.remove : Icons.add),
          style: FilledButton.styleFrom(
            backgroundColor: _type == 'expense' ? Colors.red : Colors.green,
          ),
          label: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
