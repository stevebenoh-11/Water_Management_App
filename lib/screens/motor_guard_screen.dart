import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/calc_service.dart';
import '../services/notification_service.dart';
import '../models/user_settings.dart';
import '../models/motor_session.dart';
import '../l10n/app_strings.dart';

class MotorGuardScreen extends StatefulWidget {
  final StorageService storageService;

  const MotorGuardScreen({super.key, required this.storageService});

  @override
  State<MotorGuardScreen> createState() => _MotorGuardScreenState();
}

class _MotorGuardScreenState extends State<MotorGuardScreen> {
  late UserSettings _settings;
  double? _fillTime;
  int _fillCount = 0;
  MotorSession? _activeSession;

  double _selectedLevel = 0.0; // 0.0, 0.25, 0.5, 0.75
  Timer? _timer;
  int _secondsRemaining = 0;

  DateTime? _calibrationStartTime;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshState() {
    _settings = widget.storageService.getUserSettings();
    _fillTime = widget.storageService.getFillTime();
    _fillCount = widget.storageService.getFillCount();
    _activeSession = widget.storageService.getActiveMotorSession();

    if (_activeSession != null && !_activeSession!.isCalibrating) {
      _startCountdownTimer();
    }
  }

  void _startCountdownTimer() {
    _timer?.cancel();
    _updateRemainingSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingSeconds();
    });
  }

  void _updateRemainingSeconds() {
    if (_activeSession == null) return;
    final now = DateTime.now();
    final difference = _activeSession!.expectedEndTime.difference(now).inSeconds;
    setState(() {
      _secondsRemaining = difference > 0 ? difference : 0;
    });
  }

  void _startCalibration() async {
    final now = DateTime.now();
    setState(() {
      _calibrationStartTime = now;
    });
    final session = MotorSession(
      startTime: now,
      initialLevel: 0.0,
      durationSeconds: 99999, // dynamic calibration
      isCalibrating: true,
    );
    await widget.storageService.saveActiveMotorSession(session);
    _refreshState();
  }

  void _finishCalibration() async {
    if (_activeSession == null || _activeSession!.startTime == null) return;
    final now = DateTime.now();
    final double elapsedSeconds = now.difference(_activeSession!.startTime).inSeconds.toDouble();

    if (elapsedSeconds <= 0) return;

    await widget.storageService.saveMotorCalibration(elapsedSeconds, 1);
    await widget.storageService.saveActiveMotorSession(null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calibration saved! Full tank time: ${(elapsedSeconds / 60).toStringAsFixed(1)} minutes.'),
        backgroundColor: Colors.green,
      ),
    );
    _refreshState();
  }

  void _startMotorSession() async {
    if (_fillTime == null || _fillTime! <= 0) return;

    final double remainingSeconds = CalcService.calculateRemainingTimeSeconds(
      fillTimeSeconds: _fillTime!,
      initialLevel: _selectedLevel,
      isDemoMode: _settings.isDemoMode,
    );

    final now = DateTime.now();
    final session = MotorSession(
      startTime: now,
      initialLevel: _selectedLevel,
      durationSeconds: remainingSeconds,
      isCalibrating: false,
    );

    await widget.storageService.saveActiveMotorSession(session);

    // Schedule notification (offset by 120s if normal mode, or immediate if shorter)
    double alarmOffsetSeconds = _settings.isDemoMode ? 2.0 : 120.0;
    if (remainingSeconds < alarmOffsetSeconds) {
      alarmOffsetSeconds = 0;
    }
    final DateTime alarmTime = now.add(
      Duration(seconds: (remainingSeconds - alarmOffsetSeconds).round().clamp(1, 999999)),
    );

    await NotificationService().scheduleAlarmNotification(
      id: 101,
      title: 'JalMitra Motor Alert',
      body: 'Your tank is almost full! Switch off the motor now to prevent overflow.',
      scheduledTime: alarmTime,
    );

    _refreshState();
  }

  void _stopAndRecordSuccess() async {
    if (_activeSession == null || _fillTime == null) return;

    final now = DateTime.now();
    final double actualElapsedSeconds =
        now.difference(_activeSession!.startTime).inSeconds.toDouble();

    // Update self-learning model
    final updated = CalcService.updateSelfLearnedFillTime(
      currentFillTime: _fillTime!,
      currentFillCount: _fillCount,
      actualElapsedSeconds: _settings.isDemoMode ? actualElapsedSeconds * 60 : actualElapsedSeconds,
      initialLevel: _activeSession!.initialLevel,
    );

    await widget.storageService.saveMotorCalibration(
      updated['fillTime']!,
      updated['fillCount']!.toInt(),
    );

    // Calculate savings
    final waterSaved = CalcService.calculateWaterSavedLitres(
      tankCapacityLitres: _settings.tankCapacityLitres,
      fillTimeSeconds: _fillTime!,
      typicalOverflowMinutes: _settings.typicalOverflowMinutes,
    );

    final energySaved = CalcService.calculateEnergySavedKwh(
      motorHp: _settings.motorHp,
      typicalOverflowMinutes: _settings.typicalOverflowMinutes,
    );

    final moneySaved = CalcService.calculateMoneySavedRupees(
      energySavedKwh: energySaved,
      electricityRate: _settings.electricityRate,
    );

    await widget.storageService.addSavings(
      litres: waterSaved,
      kwh: energySaved,
      rupees: moneySaved,
    );

    await NotificationService().cancelNotification(101);
    await widget.storageService.saveActiveMotorSession(null);

    _timer?.cancel();

    if (!mounted) return;
    _showSuccessDialog(waterSaved, moneySaved);
    _refreshState();
  }

  void _cancelSession() async {
    await NotificationService().cancelNotification(101);
    await widget.storageService.saveActiveMotorSession(null);
    _timer?.cancel();
    _refreshState();
  }

  void _showSuccessDialog(double waterSaved, double moneySaved) {
    final lang = _settings.language;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('saved_popup_title', lang)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('saved_popup_body', lang)
                  .replaceAll('{litres}', waterSaved.toStringAsFixed(0))
                  .replaceAll('{rupees}', moneySaved.toStringAsFixed(2)),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Awesome!'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = _settings.language;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('motor_guard', lang)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_settings.isDemoMode)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  border: Border.all(color: Colors.amber.shade800, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.get('demo_mode_badge', lang),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Mode 1: No Calibration yet
            if (_fillTime == null && _activeSession == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.build_outlined, size: 60, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('calibration_needed', lang),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.get('calib_instruction', lang),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.black70),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _startCalibration,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(AppStrings.get('start_calibration', lang)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Mode 2: Calibration in progress
            if (_activeSession != null && _activeSession!.isCalibrating) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      const Text(
                        'Calibrating Overhead Tank Motor...',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tap "Tank Full" as soon as water reaches the overflow pipe.'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _finishCalibration,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(AppStrings.get('tank_full', lang)),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Mode 3: Active Motor Guard Countdown
            if (_activeSession != null && !_activeSession!.isCalibrating) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        AppStrings.get('motor_running', lang),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _activeSession!.durationSeconds > 0
                                  ? _secondsRemaining / _activeSession!.durationSeconds
                                  : 0.0,
                              strokeWidth: 14,
                              backgroundColor: Colors.blue.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text('Remaining', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            onPressed: _stopAndRecordSuccess,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(AppStrings.get('tank_full', lang)),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            onPressed: _cancelSession,
                            icon: const Icon(Icons.close_rounded),
                            label: Text(AppStrings.get('stop_cancel', lang)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Mode 4: Calibrated & Ready to start daily session
            if (_fillTime != null && _activeSession == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get('select_level', lang),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          _buildLevelRadio(0.0, AppStrings.get('level_empty', lang)),
                          _buildLevelRadio(0.25, AppStrings.get('level_quarter', lang)),
                          _buildLevelRadio(0.5, AppStrings.get('level_half', lang)),
                          _buildLevelRadio(0.75, AppStrings.get('level_three_quarter', lang)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startMotorSession,
                          icon: const Icon(Icons.alarm_on_rounded),
                          label: Text(AppStrings.get('start_motor_timer', lang)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelRadio(double value, String label) {
    return RadioListTile<double>(
      title: Text(label),
      value: value,
      groupValue: _selectedLevel,
      onChanged: (val) {
        if (val != null) setState(() => _selectedLevel = val);
      },
    );
  }
}
