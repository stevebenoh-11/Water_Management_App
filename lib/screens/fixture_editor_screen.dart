import 'dart:async';

import 'package:flutter/material.dart';

import '../models/fixture.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/number_field.dart';

/// Add or edit a tap / shower. Calibrate by timing how long a 1-litre bottle
/// takes to fill: flowRate (L/s) = 1 ÷ seconds.
class FixtureEditorScreen extends StatefulWidget {
  const FixtureEditorScreen({super.key, this.fixture});

  /// Null = add a new fixture.
  final Fixture? fixture;

  @override
  State<FixtureEditorScreen> createState() => _FixtureEditorScreenState();
}

class _FixtureEditorScreenState extends State<FixtureEditorScreen> {
  static const maxNameLength = 30;
  static const minSeconds = 1.0;
  static const maxSeconds = 600.0;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _seconds;
  final _stopwatch = Stopwatch();
  Timer? _ticker;

  bool get _editing => widget.fixture != null;

  @override
  void initState() {
    super.initState();
    final f = widget.fixture;
    _name = TextEditingController(text: f?.name ?? '');
    _seconds = TextEditingController(
        text: f == null ? '' : (1 / f.flowRateLps).toStringAsFixed(1));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _name.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _toggleStopwatch() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
      _seconds.text = (_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);
      _formKey.currentState?.validate();
    } else {
      _stopwatch
        ..reset()
        ..start();
      _ticker = Timer.periodic(const Duration(milliseconds: 100),
          (_) => setState(() {}));
    }
    setState(() {});
  }

  double? get _parsedSeconds {
    final s = double.tryParse(_seconds.text.trim());
    return (s == null || s < minSeconds || s > maxSeconds) ? null : s;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_stopwatch.isRunning) _toggleStopwatch();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final app = context.app;
    final name = _name.text.trim();
    final rate = calc.fixtureFlowRateLps(_parsedSeconds!);
    if (_editing) {
      await app.updateFixture(
          widget.fixture!.copyWith(name: name, flowRateLps: rate));
    } else {
      await app.addFixture(name, rate);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      title: context.tr('deleteFixtureTitle'),
      message: context.tr('deleteFixtureMsg', {'name': widget.fixture!.name}),
      confirmLabel: context.tr('delete'),
      danger: true,
    );
    if (!ok || !mounted) return;
    await context.app.deleteFixture(widget.fixture!.id);
    if (mounted) Navigator.pop(context);
  }

  String? _validateSeconds(String? value) {
    final key = positiveNumberError(value, max: maxSeconds);
    if (key != null) {
      return context.tr(key, {'max': formatNumber(maxSeconds)});
    }
    if (double.parse(value!.trim()) < minSeconds) {
      return context.tr('errTooFast');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = _stopwatch.isRunning;
    final secs = _parsedSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(_editing ? 'editFixture' : 'addFixture')),
        actions: [
          if (_editing)
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
              maxLength: maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.tr('fixtureName'),
                hintText: context.tr('fixtureNameHint'),
                prefixIcon: const Icon(Icons.label_outline, size: 28),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? context.tr('errName') : null,
            ),
            const SizedBox(height: 12),
            SectionCard(
              icon: Icons.local_drink_outlined,
              title: context.tr('bottleTestTitle'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.tr('bottleTestSteps'),
                      style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${(_stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1)} ${context.tr('unitSeconds')}',
                      style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBlue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                      backgroundColor:
                          running ? AppColors.danger : AppColors.teal,
                    ),
                    onPressed: _toggleStopwatch,
                    icon: Icon(running ? Icons.stop : Icons.play_arrow,
                        size: 30),
                    label: Text(context.tr(running ? 'stop' : 'start')),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _seconds,
                    style: theme.textTheme.titleMedium,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: context.tr('secondsToFill'),
                      helperText: context.tr('secondsToFillHelp'),
                      suffixText: context.tr('unitSeconds'),
                      prefixIcon: const Icon(Icons.timer_outlined, size: 28),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (_) => setState(() {}),
                    validator: _validateSeconds,
                  ),
                  if (secs != null) ...[
                    const SizedBox(height: 12),
                    MessageBox(
                      icon: Icons.water_drop,
                      color: AppColors.teal,
                      text: context.tr('flowResult', {
                        'lps': calc.fixtureFlowRateLps(secs).toStringAsFixed(3),
                        'lpm': (calc.fixtureFlowRateLps(secs) * 60)
                            .toStringAsFixed(1),
                      }),
                    ),
                  ],
                ],
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
