import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

class ExpensesPieChart extends StatefulWidget {
  final Map<String, double> expenses;
  final double totalExpenses;

  const ExpensesPieChart({
    super.key,
    required this.expenses,
    required this.totalExpenses,
  });

  @override
  State<ExpensesPieChart> createState() => _ExpensesPieChartState();
}

class _ExpensesPieChartState extends State<ExpensesPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Color> colors = [
      Colors.blue.shade200,
      Colors.purple.shade200,
      Colors.teal.shade200,
      Colors.pink.shade200,
      Colors.cyan.shade200,
      Colors.indigo.shade200,
      Colors.amber.shade200,
      Colors.green.shade200,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: widget.expenses.isEmpty
                      ? [
                          PieChartSectionData(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                            value: 100,
                            title: '',
                            radius: 85,
                            titleStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.white,
                            ),
                          ),
                        ]
                      : List.generate(widget.expenses.length, (i) {
                          final category = widget.expenses.keys.elementAt(i);
                          final value = widget.expenses.values.elementAt(i);
                          final color = colors[i % colors.length];
                          final percentage =
                              (value / widget.totalExpenses * 100);
                          final isTouched = i == _touchedIndex;

                          return PieChartSectionData(
                            color: color,
                            value: value,
                            title: isTouched
                                ? category
                                : '${percentage.toStringAsFixed(0)}%',
                            radius: isTouched ? 90 : 85,
                            titleStyle: TextStyle(
                              fontSize: isTouched ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.grey.shade900 : Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black26, blurRadius: 2),
                              ],
                            ),
                          );
                        }),
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        setState(() {
                          _touchedIndex = -1;
                        });
                        return;
                      }
                      setState(() {
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Consumer<CurrencyProvider>(
                    builder: (context, currencyProvider, _) {
                      return Text(
                        widget.expenses.isEmpty
                            ? 'No Expenses'
                            : '${currencyProvider.currencySymbol}${widget.totalExpenses.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        widget.expenses.isEmpty
            ? Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    'Add transactions to see spending patterns',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                  ),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: widget.expenses.entries.map((entry) {
                    final index = widget.expenses.keys.toList().indexOf(
                          entry.key,
                        );
                    final color = colors[index % colors.length];

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? color.withOpacity(0.2)
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? color.withOpacity(0.3)
                              : color.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Consumer<CurrencyProvider>(
                            builder: (context, currencyProvider, _) {
                              return Text(
                                '${entry.key} (${currencyProvider.currencySymbol}${entry.value.toStringAsFixed(0)})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      isDark ? Colors.white70 : color.darken(),
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
      ],
    );
  }
}

extension on Color {
  Color darken([double amount = 0.3]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
