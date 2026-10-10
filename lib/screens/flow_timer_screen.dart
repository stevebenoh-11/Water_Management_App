import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fixture.dart';
import '../models/flow_record.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/formatters.dart';
import '../widgets/number_field.dart';
import 'fixtures_screen.dart';

/// Measures live litres used at a calibrated tap / shower and warns when
/// the chosen limit is crossed.
class FlowTimerScreen extends StatefulWidget {
  const FlowTimerScreen({super.key});

  static const defaultLimit = 40.0;
  static const maxLimit = 1000.0;

  @override
  State<FlowTimerScreen> createState() => _FlowTimerScreenState();
}

class _FlowTimerScreenState extends State<FlowTimerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _limit = TextEditingController(
      text: formatNumber(FlowTimerScreen.defaultLimit));
  String? _selectedId;

  // Running state.
  Fixture? _active;
  double _activeLimit = FlowTimerScreen.defaultLimit;
  DateTime? _startedAt;
  Timer? _ticker;
  bool _warned = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _limit.dispose();
    super.dispose();
  }

  double get _elapsed => _startedAt == null
      ? 0
      : context.app.now().difference(_startedAt!).inMilliseconds / 1000;

  double get _litres =>
      _active == null ? 0 : calc.litresUsed(_active!.flowRateLps, _elapsed);

  void _start(Fixture fixture) {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _active = fixture;
      _activeLimit = double.parse(_limit.text.trim());
      _startedAt = context.app.now();
      _warned = false;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    if (!_warned && _litres > _activeLimit) {
      _warned = true;
      _vibrateWarning();
    }
  }

  Future<void> _vibrateWarning() async {
    for (var i = 0; i < 3; i++) {
      await HapticFeedback.vibrate();
      await SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    final fixture = _active!;
    final litres = _litres;
    final record = FlowRecord(
      fixtureName: fixture.name,
      litres: litres,
      seconds: _elapsed.round(),
      limitLitres: _activeLimit,
      timestamp: context.app.now(),
    );
    setState(() {
      _active = null;
      _startedAt = null;
    });
    await context.app.addFlowRecord(record);
    if (mounted) {
      showSnack(context,
          context.tr('usageSaved', {'litres': formatLitres(litres)}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('navFlow'))),
      body: _active != null ? _buildRunning() : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    final app = context.app;
    final fixtures = app.fixtures;
    final theme = Theme.of(context);
    if (fixtures.isNotEmpty && !fixtures.any((f) => f.id == _selectedId)) {
      _selectedId = fixtures.first.id;
    }
    final selected = fixtures.where((f) => f.id == _selectedId).firstOrNull;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            icon: Icons.shower_outlined,
            title: context.tr('chooseFixture'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (fixtures.isEmpty)
                  EmptyState(
                      icon: Icons.local_drink_outlined,
                      text: context.tr('noFixtures')),
                RadioGroup<String>(
                  groupValue: _selectedId,
                  onChanged: (v) => setState(() => _selectedId = v),
                  child: Column(
                    children: [
                      for (final f in fixtures)
                        Card(
                          color: f.id == _selectedId
                              ? AppColors.aqua.withValues(alpha: 0.2)
                              : null,
                          child: RadioListTile<String>(
                            value: f.id,
                            title: Text(f.name,
                                style: theme.textTheme.titleMedium),
                            subtitle: Text(context.tr('flowPerMinute', {
                              'lpm': (f.flowRateLps * 60).toStringAsFixed(1)
                            })),
                            secondary: IconButton(
                              tooltip: context.tr('editFixture'),
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  FixturesScreen.openEditor(context, f),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => FixturesScreen.openEditor(context),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('addFixture')),
                ),
              ],
            ),
          ),
          if (selected != null) ...[
            const SizedBox(height: 8),
            NumberField(
              controller: _limit,
              label: context.tr('limitLabel'),
              helper: context.tr('limitHelp'),
              suffix: context.tr('unitLitres'),
              icon: Icons.flag_outlined,
              max: FlowTimerScreen.maxLimit,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
              onPressed: () => _start(selected),
              icon: const Icon(Icons.play_arrow, size: 30),
              label: Text(context.tr('start')),
            ),
          ],
          const SizedBox(height: 16),
          _buildHistory(app.flowHistory),
        ],
      ),
    );
  }

  Widget _buildHistory(List<FlowRecord> history) {
    return SectionCard(
      icon: Icons.history,
      title: context.tr('history'),
      child: history.isEmpty
          ? EmptyState(icon: Icons.history, text: context.tr('noHistory'))
          : Column(
              children: [
                for (final r in history.take(10))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      r.exceededLimit
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: r.exceededLimit
                          ? AppColors.danger
                          : AppColors.success,
                      size: 30,
                    ),
                    title: Text(r.fixtureName),
                    subtitle: Text(
                        '${formatDuration(context, r.seconds.toDouble())} · ${formatClock(context, r.timestamp)}'),
                    trailing: Text(
                      '${formatLitres(r.litres)} ${context.tr('unitLitres')}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: r.exceededLimit ? AppColors.danger : null),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildRunning() {
    final theme = Theme.of(context);
    final litres = _litres;
    final progress = calc.limitProgress(litres, _activeLimit);
    final over = progress > 1;
    final color = over
        ? AppColors.danger
        : progress > 0.8
            ? AppColors.warning
            : AppColors.teal;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(_active!.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  formatLitres(litres),
                  style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  context.tr('litresOfLimit',
                      {'limit': formatNumber(_activeLimit)}),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 24,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${context.tr('elapsed')}: ${formatCountdown(_elapsed)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        if (over) ...[
          const SizedBox(height: 8),
          MessageBox(
            icon: Icons.warning_amber_rounded,
            color: AppColors.danger,
            text: context.tr('limitCrossed'),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(64)),
          onPressed: _stop,
          icon: const Icon(Icons.stop, size: 30),
          label: Text(context.tr('stop')),
        ),
      ],
    );
  }
}
