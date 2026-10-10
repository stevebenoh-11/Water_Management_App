import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'common.dart';
import 'formatters.dart';

/// Today's challenge with a "Done" button and the current streak.
/// Used on Home and on the Challenges screen.
class TodayChallengeCard extends StatelessWidget {
  const TodayChallengeCard({super.key, this.onSeeAll});

  final VoidCallback? onSeeAll;

  Future<void> _done(BuildContext context) async {
    final app = context.app;
    final result = await app.completeTodaysChallenge();
    if (result == null || !context.mounted) return;
    showSnack(
        context,
        context.tr('challengeDoneMsg', {
          'litres': formatLitres(app.todaysChallenge.litres),
          'n': '${result.streak}',
        }));
    for (final badge in result.newBadges) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(badgeIcon(badge), size: 64, color: AppColors.warning),
          title: Text(ctx.tr('badgeEarned')),
          content: Text(ctx.tr('badge$badge'),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleMedium),
          actions: [
            FilledButton(
                onPressed: () => Navigator.pop(ctx), child: Text(ctx.tr('ok'))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final challenge = app.todaysChallenge;
    final done = app.challengeDoneToday;
    final streak = app.streak;

    return SectionCard(
      icon: Icons.emoji_events_outlined,
      color: AppColors.warning,
      title: context.tr('todaysChallenge'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr(challenge.textKey), style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            context.tr('savesAbout', {'litres': formatLitres(challenge.litres)}),
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.teal),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.warning, size: 30),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.tr('streakDays', {'n': '$streak'}),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: done ? null : () => _done(context),
            icon: Icon(done ? Icons.check_circle : Icons.check),
            label: Text(context.tr(done ? 'doneToday' : 'done')),
          ),
          if (onSeeAll != null)
            TextButton.icon(
              onPressed: onSeeAll,
              icon: const Icon(Icons.list_alt),
              label: Text(context.tr('seeAllChallenges')),
            ),
        ],
      ),
    );
  }
}

IconData badgeIcon(int days) => switch (days) {
      3 => Icons.water_drop,
      7 => Icons.workspace_premium,
      _ => Icons.military_tech,
    };
