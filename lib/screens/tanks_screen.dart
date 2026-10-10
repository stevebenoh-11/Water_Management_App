import 'package:flutter/material.dart';

import '../models/tank_profile.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';
import '../widgets/number_field.dart';
import '../widgets/tank_labels.dart';
import 'tank_editor_screen.dart';

/// "My Tanks": every tank with capacity, fill time and cleaning status.
class TanksScreen extends StatelessWidget {
  const TanksScreen({super.key});

  static Future<void> openEditor(BuildContext context, TankProfile tank,
          {required bool isNew}) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => TankEditorScreen(tank: tank, isNew: isNew)),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('myTanks'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            openEditor(context, app.newTankTemplate(), isNew: true),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addTank')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [for (final t in app.tanks) _TankCard(tank: t)],
      ),
    );
  }
}

class _TankCard extends StatelessWidget {
  const _TankCard({required this.tank});

  final TankProfile tank;

  Future<void> _recalibrate(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: context.tr('recalibrateTitle'),
      message: context.tr('recalibrateMsg'),
      confirmLabel: context.tr('recalibrate'),
    );
    if (ok && context.mounted) {
      await context.app.recalibrate(tank.id);
      if (context.mounted) showSnack(context, context.tr('recalibrateDone'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final days = calc.daysUntilCleaning(
        tank.lastCleaned, tank.cleaningIntervalDays, app.now());
    final fill = tank.fillTimeSeconds;

    final (IconData cleanIcon, Color cleanColor, String cleanText) =
        switch (days) {
      null => (
          Icons.help_outline,
          Colors.grey.shade700,
          context.tr('cleaningUnknown')
        ),
      <= 0 => (
          Icons.warning_amber_rounded,
          AppColors.danger,
          context.tr('cleaningDue')
        ),
      _ => (
          Icons.check_circle_outline,
          AppColors.success,
          context.tr('cleaningInDays', {'n': '$days'})
        ),
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => TanksScreen.openEditor(context, tank, isNew: false),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.aqua.withValues(alpha: 0.3),
                    child: Icon(materialIcon(tank.material),
                        color: AppColors.deepBlue, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.tankDisplayName(tank),
                            style: theme.textTheme.titleMedium),
                        Text(
                          '${context.tr(tankTypeKey(tank.type))} · ${context.tr(tankMaterialKey(tank.material))}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (tank.isDefault)
                    Chip(
                      avatar: const Icon(Icons.star, size: 18),
                      label: Text(context.tr('defaultBadge')),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Info(
                    icon: Icons.water,
                    text:
                        '${formatLitres(tank.capacityLitres)} ${context.tr('unitLitres')}',
                  ),
                  _Info(
                    icon: Icons.electric_bolt_outlined,
                    text: '${formatNumber(tank.motorHp)} ${context.tr('unitHp')}',
                  ),
                  if (fill != null)
                    _Info(
                      icon: Icons.timer_outlined,
                      text: context.tr('fillsIn',
                          {'time': formatDuration(context, fill)}),
                    )
                  else
                    _Info(
                      icon: Icons.error_outline,
                      text: context.tr('notCalibrated'),
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _Info(icon: cleanIcon, text: cleanText, color: cleanColor),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (!tank.isDefault)
                    TextButton.icon(
                      onPressed: () => app.setDefaultTank(tank.id),
                      icon: const Icon(Icons.star_outline),
                      label: Text(context.tr('setDefault')),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      await app.markTankCleaned(tank.id);
                      if (context.mounted) {
                        showSnack(context, context.tr('markedCleaned'));
                      }
                    },
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(context.tr('cleanedToday')),
                  ),
                  if (fill != null)
                    TextButton.icon(
                      onPressed: () => _recalibrate(context),
                      icon: const Icon(Icons.tune),
                      label: Text(context.tr('recalibrate')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: color ?? AppColors.blue),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
