import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'formatters.dart';

/// Bar chart of litres saved on each of the last 7 days.
class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key, required this.days, required this.litres});

  /// 7 dates, oldest first.
  final List<DateTime> days;

  /// Litres saved on each date.
  final List<double> litres;

  @override
  Widget build(BuildContext context) {
    final maxValue = litres.fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.25;

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
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${formatLitres(rod.toY)} ${context.tr('unitLitres')}',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
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
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox();
                  final isToday = i == days.length - 1;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      context.tr('day${days[i].weekday}'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.w800 : FontWeight.w500,
                        color: AppColors.deepBlue,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < litres.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: litres[i],
                    width: 22,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.aqua],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppColors.aqua.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
