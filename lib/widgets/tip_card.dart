import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_scope.dart';
import 'common.dart';

/// Tip of the Day: same tip all day, a new one tomorrow.
class TipCard extends StatelessWidget {
  const TipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return SectionCard(
      icon: Icons.lightbulb_outline,
      color: AppColors.teal,
      title: context.tr('tipOfTheDay'),
      child: Text(
        app.todaysTip.text(app.settings.languageCode),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
