import 'package:flutter/material.dart';

import '../models/fixture.dart';
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import 'fixture_editor_screen.dart';

/// Settings → Manage taps & showers.
class FixturesScreen extends StatelessWidget {
  const FixturesScreen({super.key});

  static Future<void> openEditor(BuildContext context, [Fixture? fixture]) =>
      Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => FixtureEditorScreen(fixture: fixture)),
      );

  @override
  Widget build(BuildContext context) {
    final fixtures = context.app.fixtures;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('manageFixtures'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openEditor(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addFixture')),
      ),
      body: fixtures.isEmpty
          ? Center(
              child: EmptyState(
                  icon: Icons.shower_outlined, text: context.tr('noFixtures')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                for (final f in fixtures)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_drop,
                          color: AppColors.blue, size: 30),
                      title: Text(f.name),
                      subtitle: Text(context.tr('flowPerMinute',
                          {'lpm': (f.flowRateLps * 60).toStringAsFixed(1)})),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: () => openEditor(context, f),
                    ),
                  ),
              ],
            ),
    );
  }
}
