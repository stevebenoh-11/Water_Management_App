import 'package:flutter/material.dart';

import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'formatters.dart';

/// Under / near / over the daily requirement, shown with icon + text + colour.
class UsageLevelBadge extends StatelessWidget {
  const UsageLevelBadge({super.key, required this.level});

  final calc.UsageLevel level;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String key) = switch (level) {
      calc.UsageLevel.under => (
          Icons.thumb_up_alt_outlined,
          AppColors.success,
          'levelUnder'
        ),
      calc.UsageLevel.near => (
          Icons.check_circle_outline,
          AppColors.teal,
          'levelNear'
        ),
      calc.UsageLevel.over => (
          Icons.warning_amber_rounded,
          AppColors.danger,
          'levelOver'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(context.tr(key),
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// "Your home needs about X L/day · You used Y L today" + indicator.
class RequirementSummary extends StatelessWidget {
  const RequirementSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('homeNeeds', {
            'litres': formatLitres(app.requiredPerDay),
            'people': '${app.settings.peopleCount}',
            'lpp': formatLitres(app.litresPerPerson),
          }),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('youUsedToday', {'litres': formatLitres(app.today.used)}),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        UsageLevelBadge(level: app.todayUsageLevel),
      ],
    );
  }
}

/// One number with icon and label (used / wasted / saved).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
            Text(label,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
