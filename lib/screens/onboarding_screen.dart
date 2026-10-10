import 'package:flutter/material.dart';

import '../models/tank_profile.dart';
import '../models/user_settings.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/language_toggle.dart';
import '../widgets/number_field.dart';
import '../widgets/pickers.dart';

/// First-launch flow: 3 swipe pages explaining the app, then the setup form.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  static const _infoPages = [
    (icon: Icons.water_damage_outlined, title: 'onb1Title', body: 'onb1Body'),
    (icon: Icons.shower_outlined, title: 'onb2Title', body: 'onb2Body'),
    (icon: Icons.water_drop_outlined, title: 'onb3Title', body: 'onb3Body'),
  ];

  /// Info pages + the setup form page.
  int get _pageCount => _infoPages.length + 1;
  bool get _onSetupPage => _page == _infoPages.length;

  void _goTo(int page) => _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LanguageToggle(),
                    ),
                  ),
                  if (!_onSetupPage)
                    TextButton(
                      onPressed: () => _goTo(_infoPages.length),
                      child: Text(context.tr('skip')),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final p in _infoPages)
                    _InfoPage(
                      icon: p.icon,
                      title: context.tr(p.title),
                      body: context.tr(p.body),
                    ),
                  const _SetupForm(),
                ],
              ),
            ),
            if (!_onSetupPage) _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Semantics(
            label: context.tr('pageOf', {
              'current': '${_page + 1}',
              'total': '$_pageCount',
            }),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: i == _page ? 28 : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? AppColors.blue
                          : AppColors.blue.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _goTo(_page + 1),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                _page == _infoPages.length - 1
                    ? context.tr('onbSetUp')
                    : context.tr('next'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.aqua, AppColors.blue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, size: 96, color: Colors.white),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Setup form saved to shared_preferences.
class _SetupForm extends StatefulWidget {
  const _SetupForm();

  @override
  State<_SetupForm> createState() => _SetupFormState();
}

class _SetupFormState extends State<_SetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _people =
      TextEditingController(text: '${UserSettings.defaultPeople}');
  final _tankName = TextEditingController();
  final _capacity = TextEditingController(
      text: formatNumber(UserSettings.defaultTankCapacity));
  final _hp = TextEditingController(text: formatNumber(UserSettings.defaultHp));
  final _rate = TextEditingController(
      text: formatNumber(UserSettings.defaultElectricityRate));
  final _overflow =
      TextEditingController(text: formatNumber(UserSettings.defaultOverflow));
  AreaType _area = AreaType.city;
  TankMaterial _material = TankMaterial.plastic;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_people, _tankName, _capacity, _hp, _rate, _overflow]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final app = context.app;
    final hp = double.parse(_hp.text.trim());
    final overflow = double.parse(_overflow.text.trim());
    final tank = app.newTankTemplate().copyWith(
          name: _tankName.text.trim(),
          material: _material,
          capacityLitres: double.parse(_capacity.text.trim()),
          motorHp: hp,
          overflowMinutes: overflow,
          cleaningIntervalDays: calc.defaultCleaningIntervalDays(_material),
          isDefault: true,
        );
    await app.completeOnboarding(
      app.settings.copyWith(
        peopleCount: int.parse(_people.text.trim()),
        areaType: _area,
        electricityRate: double.parse(_rate.text.trim()),
        defaultMotorHp: hp,
        defaultOverflowMinutes: overflow,
      ),
      tank,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 20);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(context.tr('setupTitle'), style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(context.tr('setupSubtitle'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),

          // ---- Home
          Text(context.tr('yourHome'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          NumberField(
            controller: _people,
            label: context.tr('peopleAtHome'),
            icon: Icons.groups_outlined,
            max: 50,
            wholeNumber: true,
          ),
          gap,
          AreaPicker(value: _area, onChanged: (a) => setState(() => _area = a)),
          const SizedBox(height: 28),

          // ---- First tank
          Text(context.tr('firstTank'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            controller: _tankName,
            style: theme.textTheme.titleMedium,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: context.tr('tankName'),
              hintText: context.tr('defaultTankName'),
              prefixIcon: const Icon(Icons.label_outline, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          MaterialDropdown(
            value: _material,
            onChanged: (m) => setState(() => _material = m),
          ),
          gap,
          NumberField(
            controller: _capacity,
            label: context.tr('tankCapacity'),
            helper: context.tr('tankCapacityHelp'),
            suffix: context.tr('unitLitres'),
            icon: Icons.propane_tank_outlined,
            max: 100000,
          ),
          gap,
          NumberField(
            controller: _hp,
            label: context.tr('motorHp'),
            helper: context.tr('motorHpHelp'),
            suffix: context.tr('unitHp'),
            icon: Icons.electric_bolt_outlined,
            max: 20,
          ),
          gap,
          NumberField(
            controller: _overflow,
            label: context.tr('overflowMinutes'),
            helper: context.tr('overflowMinutesHelp'),
            suffix: context.tr('unitMinutes'),
            icon: Icons.timer_outlined,
            max: 240,
          ),
          gap,
          NumberField(
            controller: _rate,
            label: context.tr('electricityRate'),
            helper: context.tr('electricityRateHelp'),
            suffix: context.tr('unitRupeesPerUnit'),
            icon: Icons.currency_rupee,
            max: 100,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(context.tr('saveAndStart')),
          ),
        ],
      ),
    );
  }
}
