import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const MonthPickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late PageController _pageController;
  late DateTime _selectedDate;
  late int _displayedPage;
  late bool _isYearSelection = false;

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.initialDate.year, widget.initialDate.month);
    _displayedPage = _selectedDate.year;
    _pageController = PageController(
      initialPage: _displayedPage - widget.firstDate.year,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildMonthItem(int month, int year) {
    final isSelected =
        _selectedDate.month == month && _selectedDate.year == year;
    final isEnabled =
        DateTime(
          year,
          month,
        ).isAfter(widget.firstDate.subtract(const Duration(days: 1))) &&
        DateTime(
          year,
          month,
        ).isBefore(widget.lastDate.add(const Duration(days: 1)));

    final now = DateTime.now();
    final isCurrentMonth = month == now.month && year == now.year;

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
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
                  )
                  : null,
          borderRadius: BorderRadius.circular(16),
          border:
              !isSelected
                  ? Border.all(
                    color:
                        isCurrentMonth
                            ? Theme.of(context).brightness == Brightness.dark
                                ? Colors.purpleAccent.withOpacity(0.5)
                                : Colors.purpleAccent.shade200.withOpacity(0.5)
                            : Colors.transparent,
                    width: 1.5,
                  )
                  : null,
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.withOpacity(0.3)
                              : Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap:
                isEnabled
                    ? () {
                      setState(() {
                        _selectedDate = DateTime(year, month);
                      });
                    }
                    : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _monthNames[month - 1].substring(0, 3),
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : isEnabled
                              ? isCurrentMonth
                                  ? Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.purpleAccent.shade100
                                      : Colors.purpleAccent.shade200
                                  : Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black87
                              : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight:
                          isSelected || isCurrentMonth
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isCurrentMonth && !isSelected)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.purpleAccent.shade100
                                : Colors.purpleAccent.shade200,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearItem(int year) {
    final isSelected = _isYearSelection && _selectedDate.year == year;
    final isCurrentYear = DateTime.now().year == year;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
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
                  )
                  : null,
          borderRadius: BorderRadius.circular(12),
          border:
              !isSelected
                  ? Border.all(
                    color:
                        isCurrentYear
                            ? Theme.of(context).brightness == Brightness.dark
                                ? Colors.purpleAccent.withOpacity(0.5)
                                : Colors.purpleAccent.shade200.withOpacity(0.5)
                            : Colors.transparent,
                  )
                  : null,
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.withOpacity(0.3)
                              : Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isYearSelection = false;
                _displayedPage = year;
                _pageController.jumpToPage(year - widget.firstDate.year);
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Text(
                year.toString(),
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : isCurrentYear
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.shade100
                              : Colors.purpleAccent.shade200
                          : Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.black87,
                  fontSize: 18,
                  fontWeight:
                      isSelected || isCurrentYear
                          ? FontWeight.bold
                          : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isYearSelection ? 'Select Year' : 'Select Month',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_isYearSelection)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isYearSelection = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat(
                                'yyyy',
                              ).format(DateTime(_displayedPage)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isYearSelection)
              SizedBox(
                height: 300,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: widget.lastDate.year - widget.firstDate.year + 1,
                  itemBuilder: (context, index) {
                    final year = widget.firstDate.year + index;
                    return _buildYearItem(year);
                  },
                ),
              )
            else
              SizedBox(
                height: 320,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _displayedPage = widget.firstDate.year + index;
                    });
                  },
                  itemCount: widget.lastDate.year - widget.firstDate.year + 1,
                  itemBuilder: (context, index) {
                    final year = widget.firstDate.year + index;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.3,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        return _buildMonthItem(month, year);
                      },
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedDate);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.purpleAccent.shade700
                              : Colors.purpleAccent.shade200,
                    ),
                    child: const Text('Select'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> showMonthPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return await showDialog<DateTime>(
    context: context,
    builder:
        (context) => MonthPickerDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
  );
}
