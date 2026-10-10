import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';
import '../widgets/language_toggle.dart';
import '../widgets/number_field.dart';
import 'fixtures_screen.dart';

/// Edit home setup, language, demo mode, calibration, fixtures, reset.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tank = TextEditingController();
  final _hp = TextEditingController();
  final _rate = TextEditingController();
  final _overflow = TextEditingController();
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _fillFromSettings();
      _loaded = true;
    }
  }

  void _fillFromSettings() {
    final s = context.app.settings;
    _tank.text = formatNumber(s.tankCapacityLitres);
    _hp.text = formatNumber(s.motorHp);
    _rate.text = formatNumber(s.electricityRate);
    _overflow.text = formatNumber(s.overflowMinutes);
  }

  @override
  void dispose() {
    _tank.dispose();
    _hp.dispose();
    _rate.dispose();
    _overflow.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = context.app;
    await app.updateSettings(app.settings.copyWith(
      tankCapacityLitres: double.parse(_tank.text.trim()),
      motorHp: double.parse(_hp.text.trim()),
      electricityRate: double.parse(_rate.text.trim()),
      overflowMinutes: double.parse(_overflow.text.trim()),
    ));
    if (mounted) showSnack(context, context.tr('settingsSaved'));
  }

  Future<void> _recalibrate() async {
    final ok = await confirmDialog(
      context,
      title: context.tr('recalibrateTitle'),
      message: context.tr('recalibrateMsg'),
      confirmLabel: context.tr('recalibrate'),
    );
    if (!ok || !mounted) return;
    await context.app.recalibrate();
    if (mounted) showSnack(context, context.tr('recalibrateDone'));
  }

  Future<void> _reset() async {
    final ok = await confirmDialog(
      context,
      title: context.tr('resetTitle'),
      message: context.tr('resetMsg'),
      confirmLabel: context.tr('resetConfirm'),
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.app.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final theme = Theme.of(context);
    final fill = app.fillTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('navSettings')),
        actions: const [DemoBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Home setup
          SectionCard(
            icon: Icons.home_outlined,
            title: context.tr('setupTitle'),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NumberField(
                    controller: _tank,
                    label: context.tr('tankCapacity'),
                    suffix: context.tr('unitLitres'),
                    icon: Icons.propane_tank_outlined,
                    max: 100000,
                  ),
                  const SizedBox(height: 16),
                  NumberField(
                    controller: _hp,
                    label: context.tr('motorHp'),
                    suffix: context.tr('unitHp'),
                    icon: Icons.electric_bolt_outlined,
                    max: 20,
                  ),
                  const SizedBox(height: 16),
                  NumberField(
                    controller: _rate,
                    label: context.tr('electricityRate'),
                    suffix: context.tr('unitRupeesPerUnit'),
                    icon: Icons.currency_rupee,
                    max: 100,
                  ),
                  const SizedBox(height: 16),
                  NumberField(
                    controller: _overflow,
                    label: context.tr('overflowMinutes'),
                    suffix: context.tr('unitMinutes'),
                    icon: Icons.timer_outlined,
                    max: 240,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(context.tr('save')),
                  ),
                ],
              ),
            ),
          ),

          // ---- Language
          SectionCard(
            icon: Icons.translate,
            title: context.tr('language'),
            child: const Align(
                alignment: Alignment.centerLeft, child: LanguageToggle()),
          ),

          // ---- Demo mode
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.fast_forward,
                  color: AppColors.warning, size: 30),
              title: Text(context.tr('demoMode')),
              subtitle: Text(context.tr('demoModeHelp')),
              value: app.demoMode,
              onChanged: app.setDemoMode,
            ),
          ),

          // ---- Motor & fixtures
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.power_settings_new,
                      color: AppColors.blue, size: 30),
                  title: Text(context.tr('motorCalibration')),
                  subtitle: Text(fill == null
                      ? context.tr('notCalibrated')
                      : '${context.tr('fillTimeLearned', {'time': formatDuration(context, fill)})}\n${context.tr('fillRuns', {'n': '${app.fillCount}'})}'),
                  isThreeLine: fill != null,
                ),
                if (fill != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52)),
                      onPressed: _recalibrate,
                      icon: const Icon(Icons.tune),
                      label: Text(context.tr('recalibrate')),
                    ),
                  ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shower_outlined,
                      color: AppColors.blue, size: 30),
                  title: Text(context.tr('manageFixtures')),
                  subtitle: Text(context.tr(
                      'fixtureCount', {'n': '${app.fixtures.length}'})),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => const FixturesScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.blue, size: 30),
                  title: Text(context.tr('alarmPermissions')),
                  subtitle: Text(context.tr('alarmPermissionsHelp')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => app.notifications.requestPermissions(),
                ),
              ],
            ),
          ),

          // ---- Danger zone
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
            onPressed: _reset,
            icon: const Icon(Icons.delete_forever_outlined),
            label: Text(context.tr('resetAll')),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('about'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
