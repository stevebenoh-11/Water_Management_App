import 'dart:async';

import 'package:flutter/material.dart';

import '../models/motor_session.dart';
import '../services/app_controller.dart';
import '../services/calc_service.dart' as calc;
import '../theme/app_theme.dart';
import '../widgets/app_scope.dart';
import '../widgets/common.dart';
import '../widgets/countdown_ring.dart';
import '../widgets/formatters.dart';

/// HERO FEATURE: predicts when the overhead tank will be full and rings an
/// exact alarm 2 minutes before, even if the app is closed.
class MotorGuardScreen extends StatefulWidget {
  const MotorGuardScreen({super.key});

  @override
  State<MotorGuardScreen> createState() => _MotorGuardScreenState();
}

class _MotorGuardScreenState extends State<MotorGuardScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  bool? _notificationsOk;
  bool _busy = false;
  double _level = 0;

  static const _levels = [
    (value: 0.0, key: 'levelEmpty'),
    (value: 0.25, key: 'levelQuarter'),
    (value: 0.5, key: 'levelHalf'),
    (value: 0.75, key: 'levelThreeQuarters'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Recompute the countdown every second from the saved start/end times,
    // so it is always correct, even after the app was closed.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && context.app.motorSession != null) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermission());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
      setState(() {});
    }
  }

  Future<void> _checkPermission() async {
    if (!mounted) return;
    final ok = await context.app.notifications.notificationsEnabled();
    if (mounted) setState(() => _notificationsOk = ok);
  }

  Future<void> _requestPermission() async {
    await context.app.notifications.requestPermissions();
    await _checkPermission();
  }

  Future<void> _run(Future<void> Function(AppController app) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(context.app);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------ actions

  Future<void> _finishCalibration() => _run((app) async {
        final fill = await app.finishCalibration();
        if (!mounted) return;
        if (fill == null) {
          showSnack(context, context.tr('calibrationTooShort'));
        } else {
          showSnack(context,
              context.tr('calibrationSaved', {'time': formatDuration(context, fill)}));
        }
      });

  Future<void> _tankFull() => _run((app) async {
        final result = await app.tankFull();
        if (result == null || !mounted) return;
        await _showSuccess(result);
      });

  Future<void> _cancel() async {
    final ok = await confirmDialog(
      context,
      title: context.tr('cancelGuardTitle'),
      message: context.tr('cancelGuardMsg'),
      confirmLabel: context.tr('cancelGuardConfirm'),
      danger: true,
    );
    if (ok) await _run((app) => app.cancelMotorSession());
  }

  Future<void> _showSuccess(MotorRunResult r) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.celebration, size: 56, color: AppColors.success),
        title: Text(ctx.tr('successTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ctx.tr('successMsg', {
                'litres': formatLitres(r.savings.litres),
                'rupees': formatFixed(r.savings.rupees, 2),
              }),
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              r.learned
                  ? ctx.tr('learnedMsg',
                      {'time': formatDuration(ctx, r.fillTimeSeconds)})
                  : ctx.tr('notLearnedMsg'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('ok')),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final session = app.motorSession;

    final Widget body;
    if (session != null && session.isCalibration) {
      body = _buildCalibrating(app, session);
    } else if (session != null) {
      body = _buildRunning(app, session);
    } else if (!app.isCalibrated) {
      body = _buildCalibrationIntro();
    } else {
      body = _buildIdle(app);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('navMotor')),
        actions: const [DemoBadge()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_notificationsOk == false) ...[
            MessageBox(
              icon: Icons.notifications_off_outlined,
              color: AppColors.warning,
              text: context.tr('permOffWarning'),
              action: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _requestPermission,
                  icon: const Icon(Icons.alarm_on),
                  label: Text(context.tr('allowAlarms')),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (app.demoMode && session == null) ...[
            MessageBox(
              icon: Icons.fast_forward,
              color: AppColors.warning,
              text: context.tr('demoExplain'),
            ),
            const SizedBox(height: 12),
          ],
          body,
        ],
      ),
    );
  }

  Widget _buildCalibrationIntro() {
    final theme = Theme.of(context);
    return SectionCard(
      icon: Icons.tune,
      title: context.tr('calibrateTitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('calibrateIntro'), style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          for (final (i, key) in ['calibrateStep1', 'calibrateStep2', 'calibrateStep3'].indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.blue,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(context.tr(key),
                          style: theme.textTheme.bodyLarge)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : () => _run((app) => app.startCalibration()),
            icon: const Icon(Icons.play_arrow),
            label: Text(context.tr('startCalibration')),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrating(AppController app, MotorSession session) {
    final theme = Theme.of(context);
    final elapsed = app.elapsedSeconds(session);
    final shown =
        calc.fromDeviceSeconds(elapsed, demoMode: session.demoMode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: CountdownRing(
            progress: (elapsed % 60) / 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 36, color: AppColors.blue),
                Text(formatCountdown(shown),
                    style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue)),
                Text(context.tr('calibrating'),
                    style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(context.tr('calibratingHint'),
            textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(64)),
          onPressed: _busy ? null : _finishCalibration,
          icon: const Icon(Icons.check_circle, size: 28),
          label: Text(context.tr('tankFull')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: _busy ? null : _cancel,
          icon: const Icon(Icons.close),
          label: Text(context.tr('cancel')),
        ),
      ],
    );
  }

  Widget _buildIdle(AppController app) {
    final theme = Theme.of(context);
    final fill = app.fillTime!;
    final remaining = calc.remainingFillSeconds(fill, _level);
    final deviceRemaining =
        calc.toDeviceSeconds(remaining, demoMode: app.demoMode);
    final fullAt =
        app.now().add(Duration(milliseconds: (deviceRemaining * 1000).round()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.speed, color: AppColors.teal, size: 32),
            title: Text(context.tr('fillTimeLearned',
                {'time': formatDuration(context, fill)})),
            subtitle: Text(context.tr('fillRuns', {'n': '${app.fillCount}'})),
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          icon: Icons.water,
          title: context.tr('levelQuestion'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // Fixed height so longer Tamil labels never overflow.
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 124,
                ),
                children: [
                  for (final l in _levels)
                    _LevelTile(
                      level: l.value,
                      label: context.tr(l.key),
                      selected: _level == l.value,
                      onTap: () => setState(() => _level = l.value),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('expectedFullIn', {
                  'time': formatDuration(context, deviceRemaining),
                  'clock': formatClock(context, fullAt),
                }),
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(72)),
          onPressed:
              _busy ? null : () => _run((app) => app.startMotorSession(_level)),
          icon: const Icon(Icons.power_settings_new, size: 32),
          label: Text(context.tr('startGuard')),
        ),
      ],
    );
  }

  Widget _buildRunning(AppController app, MotorSession session) {
    final theme = Theme.of(context);
    final total =
        session.endTime.difference(session.startTime).inMilliseconds / 1000;
    final remaining = app.remainingSeconds(session);
    final progress = total <= 0 ? 1.0 : 1 - remaining / total;
    final done = remaining <= 0;
    final alarmAt = app.alarmTimeFor(session);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: CountdownRing(
            progress: progress,
            color: done ? AppColors.danger : AppColors.blue,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(done ? Icons.warning_amber_rounded : Icons.water_drop,
                      size: 36,
                      color: done ? AppColors.danger : AppColors.blue),
                  Text(
                    formatCountdown(remaining),
                    style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: done ? AppColors.danger : AppColors.deepBlue),
                  ),
                  Text(
                    context.tr(done ? 'tankShouldBeFull' : 'timeLeft'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.flag, color: AppColors.teal, size: 30),
                title: Text(context.tr('expectedFullAt')),
                trailing: Text(formatClock(context, session.endTime),
                    style: theme.textTheme.titleMedium),
              ),
              ListTile(
                leading:
                    const Icon(Icons.alarm, color: AppColors.warning, size: 30),
                title: Text(context.tr('alarmAt')),
                trailing: Text(formatClock(context, alarmAt),
                    style: theme.textTheme.titleMedium),
              ),
            ],
          ),
        ),
        if (done) ...[
          const SizedBox(height: 8),
          MessageBox(
            icon: Icons.power_off,
            color: AppColors.danger,
            text: context.tr('alarmBody'),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(64)),
          onPressed: _busy ? null : _tankFull,
          icon: const Icon(Icons.check_circle, size: 28),
          label: Text(context.tr('tankFull')),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
          onPressed: _busy ? null : _cancel,
          icon: const Icon(Icons.close),
          label: Text(context.tr('cancel')),
        ),
      ],
    );
  }
}

/// One choice in the level picker, with a mini tank drawing.
class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double level;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.blue : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.blue, width: selected ? 3 : 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selected ? Colors.white : AppColors.deepBlue,
                        width: 2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: level == 0 ? 0.05 : level,
                    widthFactor: 1,
                    child: Container(
                        color: selected ? AppColors.aqua : AppColors.blue),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.deepBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
