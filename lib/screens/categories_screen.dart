import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart' as app_models;
import '../providers/transaction_provider.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _categoryController = TextEditingController();
  String _selectedType = 'expense';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog() {
    _categoryController.clear();
    String dialogType = _selectedType;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mainColor = const Color(0xFF2E5C88);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Theme(
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
            title: Text('Add Category'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(
                      0.1,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'expense',
                      label: const Text('Expense'),
                      icon: const Icon(Icons.category),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: const Text('Income'),
                      icon: const Icon(Icons.wallet),
                    ),
                  ],
                  selected: {dialogType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setDialogState(() {
                      dialogType = newSelection.first;
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (_categoryController.text.isNotEmpty) {
                    context.read<TransactionProvider>().addCategory(
                          app_models.Category(
                            name: _categoryController.text,
                            type: dialogType,
                          ),
                        );
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
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String type,
    List<app_models.Category> categories,
  ) {
    final title = type == 'income' ? 'Income Categories' : 'Expense Categories';
    final mainColor = const Color(0xFF2E5C88);
    final deleteColor = const Color(0xFFE57373);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [mainColor, mainColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    type == 'income' ? Icons.wallet : Icons.category,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${categories.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]!.withOpacity(0.3)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      type == 'income'
                          ? Icons.wallet_outlined
                          : Icons.category_outlined,
                      color: mainColor.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'No ${type} categories yet',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onLongPress: () async {
                      final provider = context.read<TransactionProvider>();
                      final canDelete = await provider.canDeleteCategory(
                        category.id!,
                      );

                      if (!mounted) return;

                      if (!canDelete) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cannot Delete Category'),
                            content: Text(
                              'The category "${category.name}" cannot be deleted because '
                              'it is being used by one or more transactions.',
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () => Navigator.pop(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: mainColor,
                                ),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Category'),
                          content: Text(
                            'Are you sure you want to delete "${category.name}"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                provider.deleteCategory(category.id!);
                                Navigator.pop(context);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: mainColor,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.8)
                                : Colors.white,
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.6)
                                : Colors.grey[50]!,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: mainColor.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2, // Reduced from 4 to 2
                        ),
                        leading: Container(
                          padding:
                              const EdgeInsets.all(5), // Reduced from 6 to 5
                          decoration: BoxDecoration(
                            color: mainColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            type == 'income' ? Icons.wallet : Icons.category,
                            color: mainColor,
                            size: 18, // Reduced from 20 to 18
                          ),
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.black87,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? deleteColor.withOpacity(0.15)
                                    : deleteColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: InkWell(
                            onTap: () async {
                              final provider =
                                  context.read<TransactionProvider>();
                              final canDelete = await provider
                                  .canDeleteCategory(category.id!);

                              if (!mounted) return;

                              if (!canDelete) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                      'Cannot Delete Category',
                                    ),
                                    content: Text(
                                      'The category "${category.name}" cannot be deleted because '
                                      'it is being used by one or more transactions.',
                                    ),
                                    actions: [
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: mainColor,
                                        ),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              if (!mounted) return;
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text(
                                    'Are you sure you want to delete "${category.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        provider.deleteCategory(
                                          category.id!,
                                        );
                                        Navigator.pop(context);
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: mainColor,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            customBorder: const CircleBorder(),
                            child: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? deleteColor
                                  : deleteColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        if (categories.isNotEmpty) const SizedBox(height: 12),
        if (type == 'income')
          Divider(
            height: 40,
            indent: 32,
            endIndent: 32,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final categories = provider.categories;
          final incomeCategories =
              categories.where((c) => c.type == 'income').toList();
          final expenseCategories =
              categories.where((c) => c.type == 'expense').toList();

          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No categories yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add categories to organize your transactions',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategorySection('expense', expenseCategories),
                _buildCategorySection('income', incomeCategories),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Add Category',
        label: const Row(
          children: [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text('Category', style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2E5C88)
            : const Color(0xFF2E5C88),
        elevation: 4,
      ),
    );
  }
}
