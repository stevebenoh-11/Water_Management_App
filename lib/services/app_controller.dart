import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../models/challenge.dart';
import '../models/day_savings.dart';
import '../models/fixture.dart';
import '../models/flow_record.dart';
import '../models/meter_test.dart';
import '../models/motor_session.dart';
import '../models/user_settings.dart';
import 'calc_service.dart' as calc;
import 'notification_service.dart';
import 'storage_service.dart';

/// Result of tapping "Tank Full" in daily mode.
class MotorRunResult {
  const MotorRunResult({
    required this.savings,
    required this.learned,
    required this.fillTimeSeconds,
  });

  final DaySavings savings;

  /// False if the run looked accidental and was not used for learning.
  final bool learned;

  /// Fill time (real seconds) after learning.
  final double fillTimeSeconds;
}

/// Result of tapping "Done" on today's challenge.
class ChallengeResult {
  const ChallengeResult({required this.streak, required this.newBadges});
  final int streak;
  final List<int> newBadges;
}

/// App-wide state and actions. Screens listen via AppScope and rebuild when
/// anything changes, so every tab always shows fresh data.
class AppController extends ChangeNotifier {
  AppController(
    this.storage, {
    NotificationService? notifications,
    DateTime Function()? clock,
  })  : notifications = notifications ?? NotificationService(),
        _clock = clock ?? DateTime.now {
    _load();
  }

  final StorageService storage;
  final NotificationService notifications;
  final DateTime Function() _clock;

  late UserSettings _settings;
  late bool _onboarded;
  MotorSession? _motorSession;
  late List<Fixture> _fixtures;
  late Map<String, DaySavings> _dailySavings;
  late List<FlowRecord> _flowHistory;
  MeterTest? _meterTest;

  void _load() {
    _settings = storage.loadSettings();
    _onboarded = storage.isOnboarded;
    _motorSession = storage.loadMotorSession();
    _fixtures = storage.loadFixtures();
    _dailySavings = storage.loadDailySavings();
    _flowHistory = storage.loadFlowHistory();
    _meterTest = storage.loadMeterTest();
  }

  DateTime now() => _clock();

  // ---------------------------------------------------------------
  // Settings & language
  // ---------------------------------------------------------------

  UserSettings get settings => _settings;
  bool get onboarded => _onboarded;
  AppStrings get strings => AppStrings(_settings.languageCode);

  Future<void> updateSettings(UserSettings settings) async {
    _settings = settings;
    notifyListeners();
    await storage.saveSettings(settings);
  }

  Future<void> setLanguage(String code) =>
      updateSettings(_settings.copyWith(languageCode: code));

  Future<void> setDemoMode(bool on) =>
      updateSettings(_settings.copyWith(demoMode: on));

  Future<void> completeOnboarding(UserSettings settings) async {
    await storage.saveSettings(settings);
    await storage.setOnboarded(true);
    _settings = settings;
    _onboarded = true;
    notifyListeners();
  }

  bool get permissionsAsked => storage.permissionsAsked;

  Future<void> markPermissionsAsked() => storage.setPermissionsAsked(true);

  /// Wipes everything and returns to onboarding.
  Future<void> resetAll() async {
    await notifications.cancelAll();
    await storage.resetAll();
    _load();
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Savings
  // ---------------------------------------------------------------

  Map<String, DaySavings> get dailySavings => Map.unmodifiable(_dailySavings);

  DaySavings savingsOn(DateTime day) =>
      _dailySavings[dateKey(day)] ?? const DaySavings();

  /// Savings over the 7 days ending today.
  DaySavings get weekSavings =>
      calc.totalSavings(calc.lastSevenDays(now()).map(savingsOn));

  Future<void> addSavings(DaySavings amount) async {
    await storage.addSavings(amount, day: now());
    _dailySavings = storage.loadDailySavings();
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Motor Guard
  // ---------------------------------------------------------------

  /// Real-world seconds to fill the tank from empty (null = not calibrated).
  double? get fillTime => storage.fillTime;
  int get fillCount => storage.fillCount;
  bool get isCalibrated => fillTime != null;
  MotorSession? get motorSession => _motorSession;

  /// Demo mode compresses time: 1 minute is 1 second on the device.
  bool get demoMode => _settings.demoMode;

  Future<void> _setSession(MotorSession? session) async {
    _motorSession = session;
    notifyListeners();
    if (session == null) {
      await storage.clearMotorSession();
    } else {
      await storage.saveMotorSession(session);
    }
  }

  /// Calibration: tank empty + motor just switched on.
  Future<void> startCalibration() {
    final t = now();
    return _setSession(MotorSession(
      startTime: t,
      level: 0,
      endTime: t,
      demoMode: demoMode,
      isCalibration: true,
    ));
  }

  /// Minimum believable calibration (real-world seconds).
  static const minCalibrationSeconds = 30.0;

  /// Calibration: tank is full. Returns the saved fill time in real
  /// seconds, or null if the run was too short to be real.
  Future<double?> finishCalibration() async {
    final session = _motorSession;
    if (session == null) return null;
    final elapsed = elapsedSeconds(session);
    final fill = calc.fromDeviceSeconds(elapsed, demoMode: session.demoMode);
    if (fill < minCalibrationSeconds) return null;
    await storage.saveCalibration(fill, 1);
    await _setSession(null);
    return fill;
  }

  /// Daily mode: start guarding from the chosen [level] and schedule the
  /// exact alarm 120 s (2 s in demo) before the tank is full.
  Future<void> startMotorSession(double level) async {
    final fill = fillTime;
    if (fill == null) return;
    final demo = demoMode;
    final remaining = calc.remainingFillSeconds(fill, level);
    final alarmDelay = calc.alarmDelaySeconds(remaining);

    final start = now();
    final end = start.add(_seconds(calc.toDeviceSeconds(remaining, demoMode: demo)));
    final alarmAt =
        start.add(_seconds(calc.toDeviceSeconds(alarmDelay, demoMode: demo)));

    await _setSession(MotorSession(
      startTime: start,
      level: level,
      endTime: end,
      demoMode: demo,
    ));
    await notifications.scheduleMotorAlarm(alarmAt, strings);
  }

  /// When the alarm rings for [session] (2 min / 2 s before full).
  DateTime alarmTimeFor(MotorSession session) {
    final total = session.endTime.difference(session.startTime).inMilliseconds;
    final leadMs = calc.toDeviceSeconds(calc.alarmLeadSeconds,
            demoMode: session.demoMode) *
        1000;
    final delayMs = total < leadMs ? 0 : total - leadMs;
    return session.startTime.add(Duration(milliseconds: delayMs.round()));
  }

  /// Device seconds since the session started.
  double elapsedSeconds(MotorSession session) =>
      now().difference(session.startTime).inMilliseconds / 1000;

  /// Device seconds until the tank is expected full (never negative).
  double remainingSeconds(MotorSession session) {
    final ms = session.endTime.difference(now()).inMilliseconds;
    return ms <= 0 ? 0 : ms / 1000;
  }

  /// Daily mode: the user switched off the motor at full. Learns the new
  /// fill time and records the water, energy and money saved today.
  Future<MotorRunResult?> tankFull() async {
    final session = _motorSession;
    final fill = fillTime;
    if (session == null || session.isCalibration || fill == null) return null;

    final elapsed = calc.fromDeviceSeconds(elapsedSeconds(session),
        demoMode: session.demoMode);
    final measured = calc.measuredFillSeconds(elapsed, session.level);
    final learned = calc.isPlausibleMeasurement(measured, fill);
    var newFill = fill;
    if (learned) {
      newFill = calc.updatedFillSeconds(fill, fillCount, measured);
      await storage.saveCalibration(newFill, fillCount + 1);
    }

    final savings = calc.motorGuardSavings(
      tankCapacityLitres: _settings.tankCapacityLitres,
      fillTimeSeconds: newFill,
      overflowMinutes: _settings.overflowMinutes,
      motorHp: _settings.motorHp,
      electricityRate: _settings.electricityRate,
    );
    await notifications.cancelMotorAlarm();
    await _setSession(null);
    await addSavings(savings);
    return MotorRunResult(
        savings: savings, learned: learned, fillTimeSeconds: newFill);
  }

  /// Cancel button: stops the session and its alarm. Nothing is saved.
  Future<void> cancelMotorSession() async {
    await notifications.cancelMotorAlarm();
    await _setSession(null);
  }

  /// Settings → Recalibrate: forget the learned fill time.
  Future<void> recalibrate() async {
    await notifications.cancelMotorAlarm();
    await storage.clearCalibration();
    await _setSession(null);
  }

  static Duration _seconds(double s) =>
      Duration(milliseconds: (s * 1000).round());

  // ---------------------------------------------------------------
  // Fixtures & flow history
  // ---------------------------------------------------------------

  List<Fixture> get fixtures => List.unmodifiable(_fixtures);
  List<FlowRecord> get flowHistory => List.unmodifiable(_flowHistory);

  Future<void> _saveFixtures(List<Fixture> list) async {
    _fixtures = list;
    notifyListeners();
    await storage.saveFixtures(list);
  }

  Future<void> addFixture(String name, double flowRateLps) => _saveFixtures([
        ..._fixtures,
        Fixture(
          id: now().microsecondsSinceEpoch.toString(),
          name: name,
          flowRateLps: flowRateLps,
        ),
      ]);

  Future<void> updateFixture(Fixture fixture) => _saveFixtures([
        for (final f in _fixtures) f.id == fixture.id ? fixture : f,
      ]);

  Future<void> deleteFixture(String id) =>
      _saveFixtures(_fixtures.where((f) => f.id != id).toList());

  Future<void> addFlowRecord(FlowRecord record) async {
    await storage.addFlowRecord(record);
    _flowHistory = storage.loadFlowHistory();
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // Night meter test
  // ---------------------------------------------------------------

  MeterTest? get meterTest => _meterTest;

  /// Next 7:00 AM after [from].
  static DateTime nextSevenAm(DateTime from) {
    final today7 = DateTime(from.year, from.month, from.day, 7);
    return from.isBefore(today7)
        ? today7
        : DateTime(from.year, from.month, from.day + 1, 7);
  }

  Future<void> saveNightReading(double reading, MeterUnit unit) async {
    final t = now();
    _meterTest = MeterTest(nightReading: reading, nightTime: t, unit: unit);
    notifyListeners();
    await storage.saveMeterTest(_meterTest!);
    await notifications.scheduleMeterReminder(nextSevenAm(t), strings);
  }

  Future<void> saveMorningReading(double reading) async {
    final test = _meterTest;
    if (test == null) return;
    _meterTest = test.withMorning(reading, now());
    notifyListeners();
    await storage.saveMeterTest(_meterTest!);
    await notifications.cancelMeterReminder();
  }

  Future<void> clearMeterTest() async {
    _meterTest = null;
    notifyListeners();
    await storage.clearMeterTest();
    await notifications.cancelMeterReminder();
  }

  // ---------------------------------------------------------------
  // Challenges
  // ---------------------------------------------------------------

  Challenge get todaysChallenge => allChallenges[
      calc.challengeIndexForDate(now(), allChallenges.length)];

  DateTime? get _lastChallengeDate {
    final s = storage.lastChallengeDate;
    return s == null ? null : DateTime.tryParse(s);
  }

  /// Streak shown today (0 if a day was missed).
  int get streak =>
      calc.currentStreak(storage.challengeStreak, _lastChallengeDate, now());

  bool get challengeDoneToday {
    final last = _lastChallengeDate;
    return last != null && calc.calendarDaysBetween(last, now()) == 0;
  }

  List<int> get badges => storage.loadBadges();

  /// "Done" on today's challenge: adds its litres and grows the streak.
  Future<ChallengeResult?> completeTodaysChallenge() async {
    if (challengeDoneToday) return null;
    final today = now();
    final newStreak = calc.streakAfterDone(
        storage.challengeStreak, _lastChallengeDate, today);
    await storage.saveChallengeProgress(newStreak, dateKey(today));

    final had = badges.toSet();
    final earned = calc.badgesForStreak(newStreak);
    final newBadges = earned.where((b) => !had.contains(b)).toList();
    if (newBadges.isNotEmpty) {
      await storage.saveBadges({...had, ...earned}.toList()..sort());
    }
    await addSavings(DaySavings(litres: todaysChallenge.litres));
    return ChallengeResult(streak: newStreak, newBadges: newBadges);
  }
}
