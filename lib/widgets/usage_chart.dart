import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'formatters.dart';

/// Grouped bar chart: litres used (left, solid blue) and wasted
/// (right, striped orange) for each label. Always shown with [UsageLegend]
/// so colour is never the only signal.
class UsageBarChart extends StatelessWidget {
  const UsageBarChart({
    super.key,
    required this.labels,
    required this.used,
    required this.wasted,
    this.highlightLast = true,
  });

  final List<String> labels;
  final List<double> used;
  final List<double> wasted;
  final bool highlightLast;

  static const usedColor = AppColors.blue;
  static const wastedColor = AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final maxValue = [...used, ...wasted].fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.2;
    final barWidth = labels.length > 7 ? 7.0 : 12.0;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.deepBlue,
              getTooltipItem: (group, _, rod, rodIndex) => BarTooltipItem(
                '${context.tr(rodIndex == 0 ? 'used' : 'wasted')}: '
                '${formatLitres(rod.toY)} ${context.tr('unitLitres')}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox();
                  final bold = highlightLast && i == labels.length - 1;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: labels.length > 7 ? 10 : 13,
                        fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < labels.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 2,
                barRods: [
                  BarChartRodData(
                    toY: used[i],
                    width: barWidth,
                    color: usedColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  BarChartRodData(
                    toY: wasted[i],
                    width: barWidth,
                    color: wastedColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                    rodStackItems: const [],
                    borderSide: const BorderSide(color: Colors.black54),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Legend: icon + text for each series.
class UsageLegend extends StatelessWidget {
  const UsageLegend({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, IconData icon, String key, {bool outlined = false}) =>
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: outlined ? Border.all(color: Colors.black54) : null,
              ),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 20, color: AppColors.deepBlue),
            const SizedBox(width: 4),
            Text(context.tr(key),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        );
    return Wrap(
      spacing: 20,
      runSpacing: 6,
      children: [
        item(UsageBarChart.usedColor, Icons.water_drop, 'usedLeftBar'),
        item(UsageBarChart.wastedColor, Icons.warning_amber_rounded,
            'wastedRightBar',
            outlined: true),
      ],
    );
  }
}
