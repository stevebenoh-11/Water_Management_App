import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/leak.dart';
import '../models/meter_test.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';
import '../widgets/number_field.dart';

/// Leak Check: A – Drip Calculator, B – Night Meter Test.
class LeakCheckScreen extends StatelessWidget {
  const LeakCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('navLeak')),
          bottom: TabBar(
            labelStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            tabs: [
              Tab(
                  icon: const Icon(Icons.water_drop_outlined),
                  text: context.tr('dripTab')),
              Tab(
                  icon: const Icon(Icons.nightlight_outlined),
                  text: context.tr('meterTab')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [DripCalculatorTab(), NightMeterTab()],
        ),
      ),
    );
  }
}

// =====================================================================
// A – Drip Calculator
// =====================================================================

class DripCalculatorTab extends StatefulWidget {
  const DripCalculatorTab({super.key});

  static const countSeconds = 10;
  static const maxDrips = 200.0;

  @override
  State<DripCalculatorTab> createState() => _DripCalculatorTabState();
}

class _DripCalculatorTabState extends State<DripCalculatorTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _manual = TextEditingController();
  final _leakName = TextEditingController();
  Timer? _timer;
  int _secondsLeft = 0;
  int _taps = 0;
  int? _result; // drips in 10 s

  bool get _counting => _timer != null;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _timer?.cancel();
    _manual.dispose();
    _leakName.dispose();
    super.dispose();
  }

  void _startCount() {
    setState(() {
      _taps = 0;
      _result = null;
      _secondsLeft = DripCalculatorTab.countSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          _timer = null;
          _result = _taps;
        });
      }
    });
  }

  void _tapDrip() {
    HapticFeedback.selectionClick();
    setState(() => _taps++);
  }

  void _calculateManual() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _result = double.parse(_manual.text.trim()).round());
  }

  void _clearResult() => setState(() {
        _result = null;
        _manual.clear();
        _leakName.clear();
      });

  /// Fixed straight away: add a month of avoided waste to savings.
  Future<void> _fixedIt() async {
    final monthly = calc.dripLitresPerMonth(_result!);
    await context.app.addFixedDripSaving(_result!);
    if (!mounted) return;
    showSnack(context,
        context.tr('fixedItSaved', {'litres': formatLitres(monthly)}));
    _clearResult();
  }

  /// Not fixed yet: save it so its daily loss counts as waste.
  Future<void> _saveLeak() async {
    final name = _leakName.text.trim().isEmpty
        ? context.tr('leakDefaultName')
        : _leakName.text.trim();
    await context.app.addLeak(name, _result!);
    if (!mounted) return;
    showSnack(context, context.tr('leakSaved'));
    _clearResult();
  }

  Future<void> _fixSavedLeak(Leak leak) async {
    final monthly = await context.app.fixLeak(leak.id);
    if (mounted) {
      showSnack(context,
          context.tr('fixedItSaved', {'litres': formatLitres(monthly)}));
    }
  }

  Future<void> _deleteSavedLeak(Leak leak) async {
    final ok = await confirmDialog(
      context,
      title: context.tr('deleteLeakTitle'),
      message: context.tr('deleteLeakMsg', {'name': leak.name}),
      confirmLabel: context.tr('delete'),
      danger: true,
    );
    if (ok && mounted) await context.app.deleteLeak(leak.id);
  }

  String? _validateDrips(String? value) {
    final key = positiveNumberError(value, max: DripCalculatorTab.maxDrips);
    if (key != null) {
      return context.tr(
          key, {'max': formatNumber(DripCalculatorTab.maxDrips)});
    }
    final v = double.parse(value!.trim());
    if (v != v.roundToDouble()) return context.tr('errWholeNumber');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.tr('dripIntro'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          if (_counting) ...[
            Text(
              context.tr('secondsLeft', {'n': '$_secondsLeft'}),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 240,
                height: 240,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    elevation: 6,
                  ),
                  onPressed: _tapDrip,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop, size: 56),
                      Text('$_taps',
                          style: const TextStyle(
                              fontSize: 56, fontWeight: FontWeight.bold)),
                      Text(context.tr('tapPerDrip'),
                          style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: _startCount,
              icon: const Icon(Icons.play_arrow, size: 30),
              label: Text(context.tr('startDripCount')),
            ),
            const SizedBox(height: 16),
            Text(context.tr('orEnterDrips'),
                textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _manual,
                    style: theme.textTheme.titleMedium,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('dripsIn10s'),
                      prefixIcon: const Icon(Icons.water_drop_outlined),
                    ),
                    validator: _validateDrips,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _calculateManual,
                  child: Text(context.tr('calculate')),
                ),
              ],
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 20),
            _buildResult(_result!),
          ],
          const SizedBox(height: 20),
          _buildActiveLeaks(),
        ],
      ),
    );
  }

  Widget _buildResult(int drips) {
    final theme = Theme.of(context);
    if (drips == 0) {
      return MessageBox(
        icon: Icons.check_circle,
        color: AppColors.success,
        text: context.tr('noDrips'),
      );
    }
    final monthly = calc.dripLitresPerMonth(drips);
    final daily = calc.dripLitresPerDay(drips);
    final buckets = calc.litresToBuckets(monthly);
    return Card(
      color: AppColors.danger.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('dripsCounted', {'n': '$drips'}),
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              context.tr('dripWaste', {
                'litres': formatLitres(monthly),
                'buckets': buckets.toStringAsFixed(1),
              }),
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: 4),
            Text(context.tr('dripPerDay', {'litres': formatLitres(daily)}),
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.success),
              onPressed: _fixedIt,
              icon: const Icon(Icons.build_circle_outlined),
              label: Text(context.tr('fixedIt')),
            ),
            const SizedBox(height: 16),
            Text(context.tr('notFixedYet'), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _leakName,
              maxLength: 30,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: context.tr('leakName'),
                hintText: context.tr('leakDefaultName'),
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _saveLeak,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(context.tr('saveLeak')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _startCount,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr('countAgain')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLeaks() {
    final leaks = context.app.activeLeaks;
    return SectionCard(
      icon: Icons.plumbing,
      color: AppColors.danger,
      title: context.tr('activeLeaks'),
      child: leaks.isEmpty
          ? EmptyState(
              icon: Icons.check_circle_outline, text: context.tr('noActiveLeaks'))
          : Column(
              children: [
                for (final leak in leaks)
                  Card(
                    color: AppColors.danger.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop,
                                  color: AppColors.danger),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(leak.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ),
                              IconButton(
                                tooltip: context.tr('delete'),
                                onPressed: () => _deleteSavedLeak(leak),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          Text(context.tr('leakWastesPerDay', {
                            'litres': formatLitres(leak.litresPerDay),
                          })),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success),
                            onPressed: () => _fixSavedLeak(leak),
                            icon: const Icon(Icons.build_circle_outlined),
                            label: Text(context.tr('fixedIt')),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// =====================================================================
// B – Night Meter Test
// =====================================================================

class NightMeterTab extends StatefulWidget {
  const NightMeterTab({super.key});

  static const maxReading = 99999999.0;

  @override
  State<NightMeterTab> createState() => _NightMeterTabState();
}

class _NightMeterTabState extends State<NightMeterTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _reading = TextEditingController();
  MeterUnit _unit = MeterUnit.litres;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _reading.dispose();
    super.dispose();
  }

  String _unitLabel(MeterUnit u) =>
      context.tr(u == MeterUnit.litres ? 'unitLitres' : 'unitCubicMetres');

  Future<void> _saveNight() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.app
        .saveNightReading(double.parse(_reading.text.trim()), _unit);
    _reading.clear();
    if (mounted) showSnack(context, context.tr('nightSaved'));
  }

  Future<void> _saveMorning() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await context.app.saveMorningReading(double.parse(_reading.text.trim()));
    _reading.clear();
  }

  Future<void> _newTest() async {
    _reading.clear();
    await context.app.clearMeterTest();
  }

  String? _validateMorning(String? value, MeterTest test) {
    final key = positiveNumberError(value, max: NightMeterTab.maxReading);
    if (key != null) {
      return context.tr(key, {'max': formatNumber(NightMeterTab.maxReading)});
    }
    if (double.parse(value!.trim()) < test.nightReading) {
      return context.tr('errMorningLower');
    }
    return null;
  }

  Widget _readingField({String? Function(String?)? validator}) {
    return TextFormField(
      controller: _reading,
      style: Theme.of(context).textTheme.titleMedium,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        LengthLimitingTextInputFormatter(12),
      ],
      decoration: InputDecoration(
        labelText: context.tr('meterReading'),
        prefixIcon: const Icon(Icons.speed, size: 28),
      ),
      validator: validator ??
          (v) {
            final key = positiveNumberError(v, max: NightMeterTab.maxReading);
            return key == null
                ? null
                : context.tr(
                    key, {'max': formatNumber(NightMeterTab.maxReading)});
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final test = context.app.meterTest;
    final Widget content;
    if (test == null) {
      content = _buildStep1();
    } else if (!test.isComplete) {
      content = _buildStep2(test);
    } else {
      content = _buildResult(test);
    }
    return Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(16), children: [content]),
    );
  }

  Widget _buildStep1() {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.nightlight_round,
      title: context.tr('step1Title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('step1Body'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text(context.tr('meterUnit'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<MeterUnit>(
            showSelectedIcon: false,
            segments: [
              for (final u in MeterUnit.values)
                ButtonSegment(value: u, label: Text(_unitLabel(u))),
            ],
            selected: {_unit},
            onSelectionChanged: (s) => setState(() => _unit = s.first),
          ),
          const SizedBox(height: 16),
          _readingField(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saveNight,
            icon: const Icon(Icons.bedtime_outlined),
            label: Text(context.tr('saveNight')),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(MeterTest test) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.nightlight_round,
                color: AppColors.deepBlue, size: 30),
            title: Text(context.tr('nightReadingWas', {
              'reading': formatNumber(test.nightReading),
              'unit': _unitLabel(test.unit),
            })),
            subtitle: Text(formatClock(context, test.nightTime)),
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          icon: Icons.wb_sunny_outlined,
          color: AppColors.warning,
          title: context.tr('step2Title'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.tr('step2Body'), style: theme.textTheme.bodyLarge),
              const SizedBox(height: 16),
              _readingField(validator: (v) => _validateMorning(v, test)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saveMorning,
                icon: const Icon(Icons.search),
                label: Text(context.tr('checkLeak')),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _newTest,
                child: Text(context.tr('startOver')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResult(MeterTest test) {
    final theme = Theme.of(context);
    final loss = calc.overnightLossLitres(
      test.nightReading,
      test.morningReading!,
      cubicMetres: test.unit == MeterUnit.cubicMetres,
    );
    final leak = calc.isLeakLikely(loss);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MessageBox(
          icon: leak ? Icons.warning_amber_rounded : Icons.check_circle,
          color: leak ? AppColors.danger : AppColors.success,
          text: leak
              ? context.tr('leakLikely', {'litres': formatLitres(loss)})
              : context.tr('noLeak'),
        ),
        if (leak) ...[
          const SizedBox(height: 12),
          SectionCard(
            icon: Icons.tips_and_updates_outlined,
            color: AppColors.teal,
            title: context.tr('leakTipsTitle'),
            child: Column(
              children: [
                for (final key in [
                  'leakTip1',
                  'leakTip2',
                  'leakTip3',
                  'leakTip4',
                  'leakTip5'
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check, color: AppColors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(context.tr(key),
                                style: theme.textTheme.bodyLarge)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _newTest,
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('newTest')),
        ),
      ],
    );
  }
}
