import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/challenge_card.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';

/// All 30 challenges, badges and streak.
class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final earned = app.badges.toSet();
    final todayId = app.todaysChallenge.id;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('challengesTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TodayChallengeCard(),
          SectionCard(
            icon: Icons.workspace_premium_outlined,
            color: AppColors.warning,
            title: context.tr('badgesTitle'),
            child: Row(
              children: [
                for (final m in calc.badgeMilestones)
                  Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: earned.contains(m)
                              ? AppColors.warning
                              : Colors.grey.shade300,
                          child: Icon(
                            earned.contains(m) ? badgeIcon(m) : Icons.lock,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('badge$m'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: earned.contains(m)
                                  ? AppColors.deepBlue
                                  : Colors.grey),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(context.tr('allChallenges'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          for (final c in allChallenges)
            Card(
              color: c.id == todayId
                  ? AppColors.aqua.withValues(alpha: 0.25)
                  : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      c.id == todayId ? AppColors.warning : AppColors.blue,
                  child: Text('${c.id}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                title: Text(context.tr(c.textKey)),
                subtitle: Text(
                  c.id == todayId
                      ? '${context.tr('today')} · ${context.tr('savesAbout', {'litres': formatLitres(c.litres)})}'
                      : context.tr('savesAbout',
                          {'litres': formatLitres(c.litres)}),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
