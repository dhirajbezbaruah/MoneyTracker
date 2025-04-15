import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaction.dart' as app_models;
import '../providers/transaction_provider.dart';
import '../widgets/export_dialog.dart';
import '../widgets/add_transaction_dialog.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  List<String> availableMonths = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _generateAvailableMonths();
  }

  void _loadData() {
    final provider = context.read<TransactionProvider>();
    provider.loadTransactions(selectedMonth);
    provider.loadCategories();
  }

  void _generateAvailableMonths() {
    final now = DateTime.now();
    final months = <String>[];

    // Add future months (up to 6 months)
    for (var i = 6; i >= 0; i--) {
      final month = DateTime(now.year, now.month + i);
      months.add(DateFormat('yyyy-MM').format(month));
    }

    // Add past months (up to 36 months)
    for (var i = 1; i <= 36; i++) {
      final month = DateTime(now.year, now.month - i);
      months.add(DateFormat('yyyy-MM').format(month));
    }

    setState(() {
      availableMonths = months;
    });
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final status = await Permission.manageExternalStorage.status;

    if (status.isGranted) {
      return true;
    }

    // Show an explanation dialog before requesting permission
    if (!mounted) return false;
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permission Needed'),
            content: const Text(
              'Money Tracker needs permission to save exported files in your Documents folder. '
              'Please grant "Files and media" permission in the next screen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (shouldRequest != true) {
      return false;
    }

    final result = await Permission.manageExternalStorage.request();

    if (result.isPermanentlyDenied) {
      if (!mounted) return false;
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Permission Required'),
              content: const Text(
                'Storage permission is required to save exported files in Documents/MoneyTracker. '
                'Please enable "Files and media" permission in settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings'),
                ),
              ],
            ),
      );

      if (shouldOpenSettings == true) {
        await openAppSettings();
        // Check if permission was granted
        final newStatus = await Permission.manageExternalStorage.status;
        return newStatus.isGranted;
      }
      return false;
    }

    return result.isGranted;
  }

  Future<void> _showExportDialog() async {
    if (Platform.isAndroid) {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission is required to export files'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) => const ExportDialog(),
    );

    if (result != null) {
      final startDate = result['startDate']!;
      final endDate = result['endDate']!;
      final provider = context.read<TransactionProvider>();

      try {
        final filePath = await provider.exportTransactions(startDate, endDate);
        if (!mounted) return;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final choice = await showDialog<String>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                title: Text(
                  'Export Successful',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                content: Text('File saved to:\n$filePath'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, 'open');
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                    child: const Text('Open File'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context, 'share');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: const Text('Share'),
                  ),
                ],
              ),
        );

        if (choice == 'share') {
          final file = XFile(filePath);
          await Share.shareXFiles([file], text: 'Exported transactions');
        } else if (choice == 'open') {
          if (Platform.isIOS || Platform.isMacOS) {
            await Process.run('open', [filePath]);
          } else if (Platform.isAndroid) {
            try {
              // For Android, use the Share.shareXFiles with proper context
              final file = XFile(filePath);
              await Share.shareXFiles(
                [file],
                subject: 'Open with',
                text: 'Open with available apps',
                sharePositionOrigin: Rect.fromLTWH(0, 0, 10, 10),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Could not open file: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(app_models.Transaction transaction) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Transaction'),
            content: const Text(
              'Are you sure you want to delete this transaction?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  context.read<TransactionProvider>().deleteTransaction(
                    transaction.id!,
                  );
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );
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
                      final index = availableMonths.indexOf(selectedMonth);
                      if (index < availableMonths.length - 1) {
                        setState(() {
                          selectedMonth = availableMonths[index + 1];
                          context.read<TransactionProvider>().loadTransactions(
                            selectedMonth,
                          );
                        });
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final monthIndex = availableMonths.indexOf(selectedMonth);
                      if (monthIndex >= 0) {
                        final result = await showDialog<String>(
                          context: context,
                          builder:
                              (context) => SimpleDialog(
                                title: const Text('Select Month'),
                                children: [
                                  SizedBox(
                                    width: double.maxFinite,
                                    height: 300,
                                    child: ListView.builder(
                                      itemCount: availableMonths.length,
                                      itemBuilder: (context, index) {
                                        final month = availableMonths[index];
                                        final date = DateFormat(
                                          'yyyy-MM',
                                        ).parse(month);
                                        final isSelected =
                                            month == selectedMonth;

                                        return ListTile(
                                          leading:
                                              isSelected
                                                  ? Icon(
                                                    Icons.check_circle,
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).primaryColor,
                                                  )
                                                  : const Icon(
                                                    Icons.calendar_month,
                                                    color: Colors.grey,
                                                  ),
                                          title: Text(
                                            DateFormat(
                                              'MMMM yyyy',
                                            ).format(date),
                                            style: TextStyle(
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context, month);
                                          },
                                          tileColor:
                                              isSelected
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                      .withOpacity(0.1)
                                                  : null,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                        );

                        if (result != null) {
                          setState(() {
                            selectedMonth = result;
                            context
                                .read<TransactionProvider>()
                                .loadTransactions(selectedMonth);
                          });
                        }
                      }
                    },
                    child: Text(
                      DateFormat(
                        'MMMM yyyy',
                      ).format(DateFormat('yyyy-MM').parse(selectedMonth)),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final index = availableMonths.indexOf(selectedMonth);
                      if (index > 0) {
                        setState(() {
                          selectedMonth = availableMonths[index - 1];
                          context.read<TransactionProvider>().loadTransactions(
                            selectedMonth,
                          );
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.purpleAccent.withOpacity(0.2)
                        : Colors.purpleAccent.shade100.withOpacity(0.15),
                child: InkWell(
                  onTap: _showExportDialog,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.ios_share,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.shade100
                              : Colors.purpleAccent.shade200,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final transactions = provider.transactions;
          final categories = provider.categories;

          if (transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.withOpacity(0.15)
                              : Colors.purpleAccent.shade100.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      size: 64,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.shade100
                              : Colors.purpleAccent.shade200,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No transactions for this month',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add your first transaction to start tracking',
                    style: TextStyle(
                      fontSize: 15,
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showAddTransactionDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Transaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.shade700
                              : Colors.purpleAccent.shade200,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        Theme.of(context).brightness == Brightness.dark
                            ? [
                              Colors.purpleAccent.shade700,
                              Colors.purple.shade900,
                            ]
                            : [
                              Colors.purpleAccent.shade200,
                              Colors.purple.shade100,
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.withOpacity(0.3)
                              : Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final category = categories.firstWhere(
                      (c) => c.id == transaction.categoryId,
                      orElse: () => throw Exception('Category not found'),
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onLongPress: () => _showDeleteDialog(transaction),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? [
                                          Theme.of(context).colorScheme.surface,
                                          Theme.of(context).colorScheme.surface
                                              .withOpacity(0.7),
                                        ]
                                        : [Colors.white, Colors.grey.shade50],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color:
                                    transaction.type == 'expense'
                                        ? Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.red.shade100.withOpacity(
                                              0.5,
                                            )
                                        : Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.green.shade100.withOpacity(
                                          0.5,
                                        ),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        DateFormat(
                                          'MMM d',
                                        ).format(transaction.date),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white.withOpacity(
                                                    0.9,
                                                  )
                                                  : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'E',
                                        ).format(transaction.date),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction.description ??
                                            category.name,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.white.withOpacity(
                                                    0.9,
                                                  )
                                                  : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              transaction.type == 'expense'
                                                  ? Theme.of(
                                                            context,
                                                          ).brightness ==
                                                          Brightness.dark
                                                      ? Colors.purpleAccent
                                                          .withOpacity(0.15)
                                                      : Colors
                                                          .purpleAccent
                                                          .shade100
                                                          .withOpacity(0.1)
                                                  : Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.dark
                                                  ? Colors.green.shade900
                                                      .withOpacity(0.3)
                                                  : Colors.green.withOpacity(
                                                    0.1,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                transaction.type == 'expense'
                                                    ? Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors
                                                            .purpleAccent
                                                            .shade100
                                                        : Colors
                                                            .purpleAccent
                                                            .shade200
                                                    : Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? Colors.green.shade300
                                                    : Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${transaction.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          transaction.type == 'expense'
                                              ? Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Colors.red.shade300
                                                  : Colors.red.shade700
                                              : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.green.shade300
                                              : Colors.green.shade700,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.purpleAccent.shade700
                : Colors.purpleAccent.shade200,
        elevation: 4,
      ),
    );
  }
}
