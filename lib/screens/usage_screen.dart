import 'package:flutter/material.dart';

import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';
import '../widgets/usage_chart.dart';
import '../widgets/usage_widgets.dart';

/// Water used & wasted: today, this week and this year.
class UsageScreen extends StatelessWidget {
  const UsageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final unit = context.tr('unitLitres');
    final today = app.today;
    final pct = calc.wastedPercent(today.wasted, today.used);

    final days = calc.lastSevenDays(app.now());
    final week = days.map(app.recordOn).toList();
    final weekHasData = week.any((r) => r.used > 0 || r.wasted > 0);

    final year = app.yearStats();
    final yearHasData = year.daysCounted > 0;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('usageTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- Today
          SectionCard(
            icon: Icons.today,
            title: context.tr('today'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    StatTile(
                      icon: Icons.water_drop,
                      label: context.tr('used'),
                      value: '${formatLitres(today.used)} $unit',
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 8),
                    StatTile(
                      icon: Icons.warning_amber_rounded,
                      label: context.tr('wasted'),
                      value: '${formatLitres(today.wasted)} $unit',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    StatTile(
                      icon: Icons.savings_outlined,
                      label: context.tr('saved'),
                      value: '${formatLitres(today.saved)} $unit',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (today.wasted > 0)
                  MessageBox(
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    text: pct == null
                        ? context.tr('wastedBuckets', {
                            'buckets': calc
                                .litresToBuckets(today.wasted)
                                .toStringAsFixed(1),
                          })
                        : context.tr('wastedPercentBuckets', {
                            'pct': pct.round().toString(),
                            'buckets': calc
                                .litresToBuckets(today.wasted)
                                .toStringAsFixed(1),
                          }),
                  )
                else if (today.used > 0)
                  MessageBox(
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    text: context.tr('noWasteToday'),
                  ),
                const SizedBox(height: 12),
                const RequirementSummary(),
                const SizedBox(height: 8),
                Text(
                  context.tr('averages', {
                    'week': formatLitres(app.averageUsed(7)),
                    'month': formatLitres(app.averageUsed(30)),
                  }),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),

          // ---------------- This week
          SectionCard(
            icon: Icons.date_range,
            color: AppColors.teal,
            title: context.tr('thisWeek'),
            child: weekHasData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UsageBarChart(
                        labels: [for (final d in days) context.tr('day${d.weekday}')],
                        used: [for (final r in week) r.used],
                        wasted: [for (final r in week) r.wasted],
                      ),
                      const SizedBox(height: 8),
                      const UsageLegend(),
                    ],
                  )
                : EmptyState(
                    icon: Icons.bar_chart, text: context.tr('noUsageYet')),
          ),

          // ---------------- This year
          SectionCard(
            icon: Icons.calendar_month,
            color: AppColors.deepBlue,
            title: context.tr('thisYear', {'year': '${app.now().year}'}),
            child: yearHasData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          StatTile(
                            icon: Icons.water_drop,
                            label: context.tr('used'),
                            value: '${formatLitres(year.total.used)} $unit',
                            color: AppColors.blue,
                          ),
                          const SizedBox(width: 8),
                          StatTile(
                            icon: Icons.warning_amber_rounded,
                            label: context.tr('wasted'),
                            value: '${formatLitres(year.total.wasted)} $unit',
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          StatTile(
                            icon: Icons.savings_outlined,
                            label: context.tr('saved'),
                            value: '${formatLitres(year.total.saved)} $unit',
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      UsageBarChart(
                        labels: [
                          for (var m = 1; m <= 12; m++) context.tr('month$m')
                        ],
                        used: [for (final r in year.monthly) r.used],
                        wasted: [for (final r in year.monthly) r.wasted],
                        highlightLast: false,
                      ),
                      const SizedBox(height: 8),
                      const UsageLegend(),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.aqua.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.blue.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.trending_up,
                                    color: AppColors.deepBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(context.tr('projectedTitle'),
                                      style: theme.textTheme.titleMedium),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                                '${context.tr('used')}: ${formatLitres(year.projectedUsed)} $unit',
                                style: theme.textTheme.bodyLarge),
                            Text(
                                '${context.tr('wasted')}: ${formatLitres(year.projectedWasted)} $unit',
                                style: theme.textTheme.bodyLarge),
                            Text(
                                '${context.tr('saved')}: ${formatLitres(year.projectedSaved)} $unit',
                                style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('projectedNote',
                                  {'days': '${year.daysCounted}'}),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : EmptyState(
                    icon: Icons.calendar_month, text: context.tr('noUsageYet')),
          ),
        ],
      ),
    );
  }
}
