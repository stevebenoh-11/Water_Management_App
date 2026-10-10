import 'package:flutter/material.dart';

import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/challenge_card.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/tip_card.dart';
import '../widgets/usage_widgets.dart';
import 'challenges_screen.dart';
import 'tanks_screen.dart';
import 'usage_screen.dart';
import 'main_shell.dart';

/// Home / Dashboard: weekly savings, big Motor ON button, today's
/// challenge and the weekly chart.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Switches the bottom-nav tab.
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final week = app.weekTotals;
    final days = calc.lastSevenDays(app.now());
    final litres = [for (final d in days) app.recordOn(d).saved];
    final hasSavings = litres.any((l) => l > 0);
    final dueTanks = app.tanksDueForCleaning;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('appName')),
        actions: const [DemoBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SavingsHeader(
            litres: week.saved,
            kwh: week.kwh,
            rupees: week.rupees,
          ),
          if (dueTanks.isNotEmpty) ...[
            const SizedBox(height: 12),
            MessageBox(
              icon: Icons.cleaning_services_outlined,
              color: AppColors.warning,
              text: context.tr('cleaningDueBanner', {
                'tanks': dueTanks.map(app.tankDisplayName).join(', '),
              }),
              action: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const TanksScreen()),
                  ),
                  child: Text(context.tr('myTanks')),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Center(
            child: _MotorButton(
              running: app.motorSession != null,
              onTap: () => onOpenTab(MainShell.motorTab),
            ),
          ),
          const SizedBox(height: 20),
          const _UsageSummaryCard(),
          const TipCard(),
          TodayChallengeCard(
            onSeeAll: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ChallengesScreen()),
            ),
          ),
          SectionCard(
            icon: Icons.bar_chart,
            color: AppColors.teal,
            title: context.tr('weeklyChartTitle'),
            child: hasSavings
                ? WeeklyChart(days: days, litres: litres)
                : EmptyState(
                    icon: Icons.insights, text: context.tr('noSavingsYet')),
          ),
        ],
      ),
    );
  }
}

class _SavingsHeader extends StatelessWidget {
  const _SavingsHeader({
    required this.litres,
    required this.kwh,
    required this.rupees,
  });

  final double litres;
  final double kwh;
  final double rupees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget stat(IconData icon, String value, String unit) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              Text(unit,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: Colors.white)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.blue, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            context.tr('weekSaved'),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat(Icons.water_drop, formatLitres(litres),
                  context.tr('unitLitres')),
              stat(Icons.bolt, formatFixed(kwh, 2), context.tr('unitKwh')),
              stat(Icons.currency_rupee, formatFixed(rupees, 2),
                  context.tr('unitRupees')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Big round "Motor ON" button that opens Motor Guard.
class _MotorButton extends StatelessWidget {
  const _MotorButton({required this.running, required this.onTap});

  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(running ? 'motorRunning' : 'motorOn'),
      child: SizedBox(
        width: 190,
        height: 190,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            elevation: 8,
            backgroundColor: running ? AppColors.success : AppColors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(running ? Icons.water_drop : Icons.power_settings_new,
                  size: 64),
              const SizedBox(height: 4),
              Text(
                context.tr(running ? 'motorRunning' : 'motorOn'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Today used / wasted vs the daily requirement. Opens the Usage screen.
class _UsageSummaryCard extends StatelessWidget {
  const _UsageSummaryCard();

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final today = app.today;
    final unit = context.tr('unitLitres');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const UsageScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.water, color: AppColors.blue, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(context.tr('usageToday'),
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
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
                ],
              ),
              const SizedBox(height: 12),
              const RequirementSummary(),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(context.tr('seeUsage'),
                    style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
