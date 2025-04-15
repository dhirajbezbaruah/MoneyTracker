import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _exportType = 'monthly';
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        dialogTheme: DialogTheme(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: AlertDialog(
        title: Text('Export Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
                ButtonSegment(value: 'yearly', label: Text('Yearly')),
              ],
              selected: {_exportType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _exportType = newSelection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: colorScheme.surfaceVariant,
                selectedBackgroundColor: colorScheme.primaryContainer,
                selectedForegroundColor: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            if (_exportType == 'monthly')
              Material(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(
                    DateFormat('MMMM yyyy').format(_selectedDate),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: colorScheme.primary,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1095),
                      ), // 36 months back
                      lastDate: DateTime.now().add(
                        const Duration(days: 365),
                      ), // 12 months ahead
                      initialDatePickerMode: DatePickerMode.year,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(colorScheme: colorScheme),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Material(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  title: Text(
                    _selectedDate.year.toString(),
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: colorScheme.primary,
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1095),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDatePickerMode: DatePickerMode.year,
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(colorScheme: colorScheme),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final startDate =
                  _exportType == 'monthly'
                      ? DateTime(_selectedDate.year, _selectedDate.month)
                      : DateTime(_selectedDate.year, 1);
              final endDate =
                  _exportType == 'monthly'
                      ? DateTime(
                        _selectedDate.year,
                        _selectedDate.month + 1,
                      ).subtract(const Duration(days: 1))
                      : DateTime(_selectedDate.year, 12, 31);
              Navigator.pop(context, {
                'startDate': startDate,
                'endDate': endDate,
              });
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
