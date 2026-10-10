import 'package:flutter/material.dart';

import '../models/user_settings.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/language_toggle.dart';
import '../widgets/number_field.dart';
import '../widgets/pickers.dart';
import 'fixtures_screen.dart';
import 'tanks_screen.dart';

/// Home details, language, defaults, tanks, taps, demo mode, tips,
/// permissions and reset.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _people = TextEditingController();
  final _lpp = TextEditingController();
  final _rate = TextEditingController();
  final _hp = TextEditingController();
  final _overflow = TextEditingController();
  AreaType _area = AreaType.city;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final s = context.app.settings;
      _people.text = '${s.peopleCount}';
      _lpp.text = s.litresPerPersonOverride == null
          ? ''
          : formatNumber(s.litresPerPersonOverride!);
      _rate.text = formatNumber(s.electricityRate);
      _hp.text = formatNumber(s.defaultMotorHp);
      _overflow.text = formatNumber(s.defaultOverflowMinutes);
      _area = s.areaType;
      _loaded = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_people, _lpp, _rate, _hp, _overflow]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = context.app;
    final lpp = _lpp.text.trim();
    await app.updateSettings(app.settings.copyWith(
      peopleCount: int.parse(_people.text.trim()),
      areaType: _area,
      litresPerPersonOverride: lpp.isEmpty ? null : double.parse(lpp),
      clearLitresOverride: lpp.isEmpty,
      electricityRate: double.parse(_rate.text.trim()),
      defaultMotorHp: double.parse(_hp.text.trim()),
      defaultOverflowMinutes: double.parse(_overflow.text.trim()),
    ));
    if (mounted) showSnack(context, context.tr('settingsSaved'));
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
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('navSettings')),
        actions: const [DemoBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            icon: Icons.translate,
            title: context.tr('language'),
            child: const Align(
                alignment: Alignment.centerLeft, child: LanguageToggle()),
          ),

          // ---- Home & defaults
          SectionCard(
            icon: Icons.home_outlined,
            title: context.tr('yourHome'),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NumberField(
                    controller: _people,
                    label: context.tr('peopleAtHome'),
                    icon: Icons.groups_outlined,
                    max: 50,
                    wholeNumber: true,
                  ),
                  gap,
                  AreaPicker(
                      value: _area,
                      onChanged: (a) => setState(() => _area = a)),
                  gap,
                  NumberField(
                    controller: _lpp,
                    label: context.tr('litresPerPerson'),
                    helper: context.tr('litresPerPersonHelp', {
                      'n': formatNumber(calc.defaultLitresPerPerson(_area)),
                    }),
                    suffix: context.tr('unitLitres'),
                    icon: Icons.person_outline,
                    max: 1000,
                    optional: true,
                  ),
                  gap,
                  NumberField(
                    controller: _rate,
                    label: context.tr('electricityRate'),
                    suffix: context.tr('unitRupeesPerUnit'),
                    icon: Icons.currency_rupee,
                    max: 100,
                  ),
                  gap,
                  NumberField(
                    controller: _hp,
                    label: context.tr('defaultMotorHp'),
                    suffix: context.tr('unitHp'),
                    icon: Icons.electric_bolt_outlined,
                    max: 20,
                  ),
                  gap,
                  NumberField(
                    controller: _overflow,
                    label: context.tr('defaultOverflow'),
                    suffix: context.tr('unitMinutes'),
                    icon: Icons.timer_outlined,
                    max: 240,
                    textInputAction: TextInputAction.done,
                  ),
                  gap,
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(context.tr('save')),
                  ),
                ],
              ),
            ),
          ),

          // ---- Tanks, taps, modes
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.propane_tank_outlined,
                      color: AppColors.blue, size: 30),
                  title: Text(context.tr('myTanks')),
                  subtitle: Text(
                      context.tr('tankCount', {'n': '${app.tanks.length}'})),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const TanksScreen()),
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
                SwitchListTile(
                  secondary: const Icon(Icons.fast_forward,
                      color: AppColors.warning, size: 30),
                  title: Text(context.tr('demoMode')),
                  subtitle: Text(context.tr('demoModeHelp')),
                  value: app.demoMode,
                  onChanged: app.setDemoMode,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.lightbulb_outline,
                      color: AppColors.teal, size: 30),
                  title: Text(context.tr('tipNotifications')),
                  subtitle: Text(context.tr('tipNotificationsHelp')),
                  value: app.settings.tipNotifications,
                  onChanged: app.setTipNotifications,
                ),
              ],
            ),
          ),

          // ---- Alarms
          SectionCard(
            icon: Icons.notifications_active_outlined,
            title: context.tr('alarmPermissions'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('alarmPermissionsHelp'),
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => app.notifications.requestPermissions(),
                  icon: const Icon(Icons.alarm_on),
                  label: Text(context.tr('allowAlarms')),
                ),
                const SizedBox(height: 12),
                MessageBox(
                  icon: Icons.battery_alert_outlined,
                  color: AppColors.warning,
                  text: context.tr('batteryNote'),
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
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
