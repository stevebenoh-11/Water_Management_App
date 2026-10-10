import 'package:flutter/material.dart';

import '../models/tank_profile.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/number_field.dart';
import '../widgets/pickers.dart';
import '../widgets/tank_labels.dart';

/// Add or edit a tank. Capacity can be typed or calculated from its size.
class TankEditorScreen extends StatefulWidget {
  const TankEditorScreen({super.key, required this.tank, required this.isNew});

  final TankProfile tank;
  final bool isNew;

  @override
  State<TankEditorScreen> createState() => _TankEditorScreenState();
}

enum _CapacityMode { typed, fromSize }

/// "Last cleaned" choices.
enum _CleanedChoice { keep, unknown, today, oneMonth, threeMonths, sixMonths }

class _TankEditorScreenState extends State<TankEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _capacity;
  late final TextEditingController _diameter;
  late final TextEditingController _length;
  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _hp;
  late final TextEditingController _overflow;
  late TankType _type;
  late TankMaterial _material;
  late TankShape _shape;
  late int _intervalDays;
  late bool _isDefault;
  late _CapacityMode _mode;
  late _CleanedChoice _cleaned;

  static const _intervalOptions = [30, 60, 90, 120, 180, 365];
  static const maxDimension = 20.0; // metres

  @override
  void initState() {
    super.initState();
    final t = widget.tank;
    String n(double? v) => v == null ? '' : formatNumber(v);
    _name = TextEditingController(text: t.name);
    _capacity = TextEditingController(text: formatNumber(t.capacityLitres));
    _diameter = TextEditingController(text: n(t.diameterM));
    _length = TextEditingController(text: n(t.lengthM));
    _width = TextEditingController(text: n(t.widthM));
    _height = TextEditingController(text: n(t.heightM));
    _hp = TextEditingController(text: formatNumber(t.motorHp));
    _overflow = TextEditingController(text: formatNumber(t.overflowMinutes));
    _type = t.type;
    _material = t.material;
    _shape = t.shape;
    _intervalDays = _intervalOptions.contains(t.cleaningIntervalDays)
        ? t.cleaningIntervalDays
        : 180;
    _isDefault = t.isDefault;
    _mode = (t.heightM != null || t.lengthM != null)
        ? _CapacityMode.fromSize
        : _CapacityMode.typed;
    _cleaned =
        t.lastCleaned != null ? _CleanedChoice.keep : _CleanedChoice.unknown;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _capacity, _diameter, _length, _width, _height, _hp, _overflow
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final v = double.tryParse(c.text.trim());
    return (v == null || v <= 0 || v > maxDimension) ? null : v;
  }

  /// Capacity from the dimensions, or null if a dimension is missing.
  double? get _calculatedCapacity {
    final h = _num(_height);
    switch (_shape) {
      case TankShape.verticalCylinder:
        final d = _num(_diameter);
        return (d == null || h == null) ? null : calc.cylinderLitres(d, h);
      case TankShape.horizontalCylinder:
        final d = _num(_diameter);
        final l = _num(_length);
        return (d == null || l == null) ? null : calc.cylinderLitres(d, l);
      case TankShape.rectangular:
        final l = _num(_length);
        final w = _num(_width);
        return (l == null || w == null || h == null)
            ? null
            : calc.cuboidLitres(l, w, h);
    }
  }

  DateTime? _lastCleanedValue() {
    final now = context.app.now();
    return switch (_cleaned) {
      _CleanedChoice.keep => widget.tank.lastCleaned,
      _CleanedChoice.unknown => null,
      _CleanedChoice.today => now,
      _CleanedChoice.oneMonth => DateTime(now.year, now.month - 1, now.day),
      _CleanedChoice.threeMonths => DateTime(now.year, now.month - 3, now.day),
      _CleanedChoice.sixMonths => DateTime(now.year, now.month - 6, now.day),
    };
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fromSize = _mode == _CapacityMode.fromSize;
    final capacity =
        fromSize ? _calculatedCapacity : double.parse(_capacity.text.trim());
    if (capacity == null || capacity <= 0) {
      showSnack(context, context.tr('enterAllSizes'));
      return;
    }
    final lastCleaned = _lastCleanedValue();
    var tank = widget.tank.copyWith(
      name: _name.text.trim(),
      type: _type,
      material: _material,
      shape: _shape,
      capacityLitres: capacity,
      clearDimensions: true,
      motorHp: double.parse(_hp.text.trim()),
      overflowMinutes: double.parse(_overflow.text.trim()),
      cleaningIntervalDays: _intervalDays,
      isDefault: _isDefault,
      clearLastCleaned: lastCleaned == null,
      lastCleaned: lastCleaned,
    );
    if (fromSize) {
      tank = tank.copyWith(
        diameterM: _shape == TankShape.rectangular ? null : _num(_diameter),
        lengthM: _shape == TankShape.verticalCylinder ? null : _num(_length),
        widthM: _shape == TankShape.rectangular ? _num(_width) : null,
        heightM: _shape == TankShape.horizontalCylinder ? null : _num(_height),
      );
    }
    await context.app.saveTank(tank);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final app = context.app;
    if (app.tanks.length <= 1) {
      showSnack(context, context.tr('keepOneTank'));
      return;
    }
    final ok = await confirmDialog(
      context,
      title: context.tr('deleteTankTitle'),
      message: context.tr(
          'deleteTankMsg', {'name': app.tankDisplayName(widget.tank)}),
      confirmLabel: context.tr('delete'),
      danger: true,
    );
    if (!ok || !mounted) return;
    await app.deleteTank(widget.tank.id);
    if (mounted) Navigator.pop(context);
  }

  Widget _dimField(TextEditingController c, String labelKey) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: NumberField(
          controller: c,
          label: context.tr(labelKey),
          suffix: context.tr('unitMetres'),
          icon: Icons.straighten,
          max: maxDimension,
          onChanged: (_) => setState(() {}),
        ),
      );

  String _cleanedLabel(_CleanedChoice c) => switch (c) {
        _CleanedChoice.keep => context.tr('cleanedDaysAgo', {
            'n':
                '${calc.calendarDaysBetween(widget.tank.lastCleaned!, context.app.now())}'
          }),
        _CleanedChoice.unknown => context.tr('dontKnow'),
        _CleanedChoice.today => context.tr('today'),
        _CleanedChoice.oneMonth => context.tr('monthsAgo', {'n': '1'}),
        _CleanedChoice.threeMonths => context.tr('monthsAgo', {'n': '3'}),
        _CleanedChoice.sixMonths => context.tr('monthsAgo', {'n': '6'}),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calculated = _calculatedCapacity;
    const gap = SizedBox(height: 16);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.isNew ? 'addTank' : 'editTank')),
        actions: [
          if (!widget.isNew)
            IconButton(
              tooltip: context.tr('delete'),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              style: theme.textTheme.titleMedium,
              maxLength: 30,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.tr('tankName'),
                hintText: context.tr('tankNameHint'),
                prefixIcon: const Icon(Icons.label_outline, size: 28),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.tr('errName') : null,
            ),
            const SizedBox(height: 8),
            LabeledDropdown<TankType>(
              label: context.tr('tankTypeLabel'),
              icon: Icons.home_work_outlined,
              value: _type,
              items: TankType.values,
              itemLabel: (t) => context.tr(tankTypeKey(t)),
              onChanged: (t) => setState(() => _type = t),
            ),
            gap,
            MaterialDropdown(
              value: _material,
              onChanged: (m) => setState(() {
                _material = m;
                _intervalDays = calc.defaultCleaningIntervalDays(m);
              }),
            ),
            gap,
            LabeledDropdown<TankShape>(
              label: context.tr('tankShape'),
              icon: Icons.category_outlined,
              value: _shape,
              items: TankShape.values,
              itemLabel: (s) => context.tr(tankShapeKey(s)),
              onChanged: (s) => setState(() => _shape = s),
            ),
            gap,
            SectionCard(
              icon: Icons.water,
              title: context.tr('tankCapacity'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<_CapacityMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: _CapacityMode.typed,
                          icon: const Icon(Icons.edit),
                          label: Text(context.tr('capacityTyped'))),
                      ButtonSegment(
                          value: _CapacityMode.fromSize,
                          icon: const Icon(Icons.straighten),
                          label: Text(context.tr('capacityFromSize'))),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (_mode == _CapacityMode.typed)
                    NumberField(
                      controller: _capacity,
                      label: context.tr('tankCapacity'),
                      suffix: context.tr('unitLitres'),
                      icon: Icons.propane_tank_outlined,
                      max: 100000,
                    )
                  else ...[
                    Text(context.tr('sizeHelp'),
                        style: theme.textTheme.bodyMedium),
                    if (_shape != TankShape.rectangular)
                      _dimField(_diameter, 'dimDiameter'),
                    if (_shape != TankShape.verticalCylinder)
                      _dimField(_length, 'dimLength'),
                    if (_shape == TankShape.rectangular)
                      _dimField(_width, 'dimWidth'),
                    if (_shape != TankShape.horizontalCylinder)
                      _dimField(_height, 'dimHeight'),
                    const SizedBox(height: 12),
                    MessageBox(
                      icon: Icons.calculate_outlined,
                      color: calculated == null
                          ? AppColors.warning
                          : AppColors.teal,
                      text: calculated == null
                          ? context.tr('enterAllSizes')
                          : context.tr('calculatedCapacity',
                              {'litres': calculated.round().toString()}),
                    ),
                  ],
                ],
              ),
            ),
            SectionCard(
              icon: Icons.electric_bolt_outlined,
              title: context.tr('motorForTank'),
              child: Column(
                children: [
                  NumberField(
                    controller: _hp,
                    label: context.tr('motorHp'),
                    suffix: context.tr('unitHp'),
                    icon: Icons.electric_bolt_outlined,
                    max: 20,
                  ),
                  gap,
                  NumberField(
                    controller: _overflow,
                    label: context.tr('overflowMinutes'),
                    suffix: context.tr('unitMinutes'),
                    icon: Icons.timer_outlined,
                    max: 240,
                  ),
                ],
              ),
            ),
            SectionCard(
              icon: Icons.cleaning_services_outlined,
              title: context.tr('cleaning'),
              child: Column(
                children: [
                  LabeledDropdown<int>(
                    label: context.tr('cleanEvery'),
                    icon: Icons.event_repeat,
                    value: _intervalDays,
                    items: _intervalOptions,
                    itemLabel: (d) =>
                        context.tr('everyMonths', {'n': '${(d / 30).round()}'}),
                    onChanged: (d) => setState(() => _intervalDays = d),
                  ),
                  gap,
                  LabeledDropdown<_CleanedChoice>(
                    label: context.tr('lastCleaned'),
                    icon: Icons.history,
                    value: _cleaned,
                    items: [
                      if (widget.tank.lastCleaned != null) _CleanedChoice.keep,
                      _CleanedChoice.unknown,
                      _CleanedChoice.today,
                      _CleanedChoice.oneMonth,
                      _CleanedChoice.threeMonths,
                      _CleanedChoice.sixMonths,
                    ],
                    itemLabel: _cleanedLabel,
                    onChanged: (c) => setState(() => _cleaned = c),
                  ),
                ],
              ),
            ),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.star_outline,
                    color: AppColors.warning, size: 30),
                title: Text(context.tr('useByDefault')),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
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
    );
  }
}
