import 'package:flutter/foundation.dart';

import '../l10n/app_strings.dart';
import '../l10n/tips.dart';
import '../models/challenge.dart';
import '../models/daily_record.dart';
import '../models/fixture.dart';
import '../models/flow_record.dart';
import '../models/leak.dart';
import '../models/meter_test.dart';
import '../models/motor_session.dart';
import '../models/tank_profile.dart';
import '../models/user_settings.dart';
import 'calc_service.dart' as calc;
import 'notification_service.dart';
import 'storage_service.dart';

/// Result of tapping "Tank Full" in daily mode.
class MotorRunResult {
  const MotorRunResult({
    required this.record,
    required this.learned,
    required this.fillTimeSeconds,
    required this.minutesLate,
  });

  /// Used / wasted / saved water, energy and money from this run.
  final DailyRecord record;

  /// False if the run looked accidental and was not used for learning.
  final bool learned;

  /// Fill time (real seconds) after learning.
  final double fillTimeSeconds;

  /// Minutes past the predicted full time (0 if on time).
  final double minutesLate;
}

/// Result of tapping "Done" on today's challenge.
class ChallengeResult {
  const ChallengeResult({required this.streak, required this.newBadges});
  final int streak;
  final List<int> newBadges;
}

/// Totals for one year on the Usage screen.
class YearStats {
  const YearStats({
    required this.total,
    required this.monthly,
    required this.daysCounted,
  });

  /// Used / wasted / saved so far this year (leak waste included).
  final DailyRecord total;

  /// 12 entries, January first.
  final List<DailyRecord> monthly;

  /// Days used for the full-year projection.
  final int daysCounted;

  double get projectedUsed => calc.projectedYearTotal(total.used, daysCounted);
  double get projectedWasted =>
      calc.projectedYearTotal(total.wasted, daysCounted);
  double get projectedSaved => calc.projectedYearTotal(total.saved, daysCounted);
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
  late List<TankProfile> _tanks;
  MotorSession? _motorSession;
  late List<Fixture> _fixtures;
  late Map<String, DailyRecord> _records;
  late List<FlowRecord> _flowHistory;
  late List<Leak> _leaks;
  MeterTest? _meterTest;
  String? _selectedTankId;

  void _load() {
    _settings = storage.loadSettings();
    _onboarded = storage.isOnboarded;
    _tanks = storage.loadTanks();
    _motorSession = storage.loadMotorSession();
    _fixtures = storage.loadFixtures();
    _records = storage.loadDailyRecords();
    _flowHistory = storage.loadFlowHistory();
    _leaks = storage.loadLeaks();
    _meterTest = storage.loadMeterTest();
    _selectedTankId = _motorSession?.tankId;
  }

  DateTime now() => _clock();

  // ---------------------------------------------------------------
  // Settings & language
  // ---------------------------------------------------------------

  UserSettings get settings => _settings;
  bool get onboarded => _onboarded;
  AppStrings get strings => AppStrings(_settings.languageCode);

  Future<void> updateSettings(UserSettings settings) async {
    final tipsChanged = settings.tipNotifications != _settings.tipNotifications ||
        settings.languageCode != _settings.languageCode;
    _settings = settings;
    notifyListeners();
    await storage.saveSettings(settings);
    if (tipsChanged) await refreshTipNotifications();
  }

  Future<void> setLanguage(String code) =>
      updateSettings(_settings.copyWith(languageCode: code));

  Future<void> setDemoMode(bool on) =>
      updateSettings(_settings.copyWith(demoMode: on));

  Future<void> setTipNotifications(bool on) =>
      updateSettings(_settings.copyWith(tipNotifications: on));

  /// Saves the onboarding answers and the first tank.
  Future<void> completeOnboarding(
      UserSettings settings, TankProfile firstTank) async {
    await storage.saveSettings(settings);
    await storage.saveTanks([firstTank.copyWith(isDefault: true)]);
    await storage.setOnboarded(true);
    _settings = settings;
    _tanks = storage.loadTanks();
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

  /// New unique id.
  String _newId() => now().microsecondsSinceEpoch.toString();

  // ---------------------------------------------------------------
  // Tanks
  // ---------------------------------------------------------------

  List<TankProfile> get tanks => List.unmodifiable(_tanks);

  TankProfile? tankById(String id) =>
      _tanks.where((t) => t.id == id).firstOrNull;

  TankProfile? get defaultTank =>
      _tanks.where((t) => t.isDefault).firstOrNull ?? _tanks.firstOrNull;

  /// Tank chosen at the top of Motor Guard (running session wins).
  TankProfile? get selectedTank {
    final sessionTank =
        _motorSession == null ? null : tankById(_motorSession!.tankId);
    return sessionTank ??
        (_selectedTankId == null ? null : tankById(_selectedTankId!)) ??
        defaultTank;
  }

  void selectTank(String id) {
    if (_motorSession != null) return; // can't switch while guarding
    _selectedTankId = id;
    notifyListeners();
  }

  Future<void> _saveTanks(List<TankProfile> list) async {
    // Exactly one default.
    if (list.isNotEmpty && !list.any((t) => t.isDefault)) {
      list = [list.first.copyWith(isDefault: true), ...list.skip(1)];
    }
    _tanks = list;
    notifyListeners();
    await storage.saveTanks(list);
  }

  /// Blank tank pre-filled with the default motor settings.
  TankProfile newTankTemplate() => TankProfile(
        id: _newId(),
        name: '',
        capacityLitres: UserSettings.defaultTankCapacity,
        motorHp: _settings.defaultMotorHp,
        overflowMinutes: _settings.defaultOverflowMinutes,
        cleaningIntervalDays:
            calc.defaultCleaningIntervalDays(TankMaterial.plastic),
      );

  Future<void> saveTank(TankProfile tank) async {
    final exists = _tanks.any((t) => t.id == tank.id);
    var list = exists
        ? [for (final t in _tanks) t.id == tank.id ? tank : t]
        : [..._tanks, tank];
    if (tank.isDefault) {
      list = [
        for (final t in list) t.id == tank.id ? t : t.copyWith(isDefault: false)
      ];
    }
    await _saveTanks(list);
  }

  /// At least one tank must always exist. Returns false if not deleted.
  Future<bool> deleteTank(String id) async {
    if (_tanks.length <= 1) return false;
    if (_motorSession?.tankId == id) await cancelMotorSession();
    if (_selectedTankId == id) _selectedTankId = null;
    await _saveTanks(_tanks.where((t) => t.id != id).toList());
    return true;
  }

  Future<void> setDefaultTank(String id) async {
    await _saveTanks([
      for (final t in _tanks) t.copyWith(isDefault: t.id == id),
    ]);
  }

  /// Forget the learned fill time of a tank.
  Future<void> recalibrate(String tankId) async {
    if (_motorSession?.tankId == tankId) {
      await notifications.cancelMotorAlarm();
      await _setSession(null);
    }
    final tank = tankById(tankId);
    if (tank != null) await saveTank(tank.copyWith(clearFillTime: true));
  }

  Future<void> markTankCleaned(String tankId) async {
    final tank = tankById(tankId);
    if (tank != null) await saveTank(tank.copyWith(lastCleaned: now()));
  }

  /// Tanks whose cleaning is due (today or overdue).
  List<TankProfile> get tanksDueForCleaning => _tanks.where((t) {
        final days =
            calc.daysUntilCleaning(t.lastCleaned, t.cleaningIntervalDays, now());
        return days != null && days <= 0;
      }).toList();

  // ---------------------------------------------------------------
  // Daily records: used / wasted / saved
  // ---------------------------------------------------------------

  /// Stored record plus that day's waste from unfixed leaks.
  DailyRecord recordOn(DateTime day) {
    final stored = _records[dateKey(day)] ?? const DailyRecord();
    final leakWaste = calc.leakWasteOnDay(_leaks, day);
    return leakWaste == 0
        ? stored
        : stored.copyWith(wasted: stored.wasted + leakWaste);
  }

  DailyRecord get today => recordOn(now());

  /// Totals over the 7 days ending today.
  DailyRecord get weekTotals =>
      calc.totalRecords(calc.lastSevenDays(now()).map(recordOn));

  Future<void> _addToToday(DailyRecord amount) async {
    await storage.addToRecord(amount, day: now());
    _records = storage.loadDailyRecords();
    notifyListeners();
  }

  /// Average litres used per day over the last [days] days, counting only
  /// days that have any record (so a new install is not dragged to zero).
  double averageUsed(int days) {
    final values = calc
        .lastNDays(now(), days)
        .map(recordOn)
        .where((r) => r.used > 0)
        .map((r) => r.used)
        .toList();
    return calc.averagePerDay(values);
  }

  /// Yearly totals, monthly bars and the data for the projection.
  YearStats yearStats() {
    final t = now();
    final jan1 = DateTime(t.year, 1, 1);
    final monthly = List<DailyRecord>.filled(12, const DailyRecord());
    var total = const DailyRecord();
    DateTime? first;
    final days = calc.calendarDaysBetween(jan1, t) + 1;
    for (var i = 0; i < days; i++) {
      final day = DateTime(t.year, 1, 1 + i);
      final r = recordOn(day);
      if (r.isEmpty) continue;
      first ??= day;
      total = total + r;
      monthly[day.month - 1] = monthly[day.month - 1] + r;
    }
    return YearStats(
      total: total,
      monthly: monthly,
      daysCounted: first == null ? 0 : calc.daysCountedThisYear(first, t),
    );
  }

  // ---------------------------------------------------------------
  // Average water required per day
  // ---------------------------------------------------------------

  double get litresPerPerson =>
      _settings.litresPerPersonOverride ??
      calc.defaultLitresPerPerson(_settings.areaType);

  double get requiredPerDay =>
      calc.requiredLitresPerDay(_settings.peopleCount, litresPerPerson);

  calc.UsageLevel get todayUsageLevel =>
      calc.usageLevel(today.used, requiredPerDay);

  // ---------------------------------------------------------------
  // Motor Guard
  // ---------------------------------------------------------------

  MotorSession? get motorSession => _motorSession;

  /// Demo mode compresses time: 1 minute is 1 second on the device.
  bool get demoMode => _settings.demoMode;

  Future<void> _setSession(MotorSession? session) async {
    _motorSession = session;
    if (session != null) _selectedTankId = session.tankId;
    notifyListeners();
    if (session == null) {
      await storage.clearMotorSession();
    } else {
      await storage.saveMotorSession(session);
    }
  }

  /// Calibration: tank empty + motor just switched on.
  Future<void> startCalibration(String tankId) {
    final t = now();
    return _setSession(MotorSession(
      startTime: t,
      level: 0,
      endTime: t,
      demoMode: demoMode,
      isCalibration: true,
      tankId: tankId,
    ));
  }

  /// Calibration: tank is full. Returns the saved fill time in real
  /// seconds, or null if the run was too short to be real.
  Future<double?> finishCalibration() async {
    final session = _motorSession;
    if (session == null) return null;
    final tank = tankById(session.tankId);
    if (tank == null) {
      await _setSession(null);
      return null;
    }
    final fill = calc.fromDeviceSeconds(elapsedSeconds(session),
        demoMode: session.demoMode);
    if (fill < calc.minPlausibleRunSeconds) return null;
    await saveTank(tank.copyWith(fillTimeSeconds: fill, fillCount: 1));
    await _setSession(null);
    // A full tank was pumped during calibration.
    await _addToToday(DailyRecord(used: tank.capacityLitres));
    return fill;
  }

  /// Daily mode: start guarding [tankId] from [level] and schedule the exact
  /// alarm 120 s (2 s in demo) before the tank is full.
  Future<void> startMotorSession(String tankId, double level) async {
    final tank = tankById(tankId);
    final fill = tank?.fillTimeSeconds;
    if (tank == null || fill == null) return;
    final demo = demoMode;
    final remaining = calc.remainingFillSeconds(fill, level);
    final alarmDelay = calc.alarmDelaySeconds(remaining);

    final start = now();
    final end =
        start.add(_seconds(calc.toDeviceSeconds(remaining, demoMode: demo)));
    final alarmAt =
        start.add(_seconds(calc.toDeviceSeconds(alarmDelay, demoMode: demo)));

    await _setSession(MotorSession(
      startTime: start,
      level: level,
      endTime: end,
      demoMode: demo,
      tankId: tankId,
    ));
    await notifications.scheduleMotorAlarm(
        alarmAt, strings, tankDisplayName(tank));
  }

  /// Name to show for a tank (unnamed tanks get the translated default).
  String tankDisplayName(TankProfile tank) =>
      tank.name.trim().isEmpty ? strings.get('defaultTankName') : tank.name;

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
  /// fill time and records water used, wasted (if late) and saved.
  Future<MotorRunResult?> tankFull() async {
    final session = _motorSession;
    if (session == null || session.isCalibration) return null;
    final tank = tankById(session.tankId);
    final fill = tank?.fillTimeSeconds;
    if (tank == null || fill == null) return null;

    final elapsed = calc.fromDeviceSeconds(elapsedSeconds(session),
        demoMode: session.demoMode);
    final predicted = calc.remainingFillSeconds(fill, session.level);
    final late = calc.minutesLate(elapsed, predicted);
    final measured = calc.measuredFillSeconds(elapsed, session.level);
    final learned = calc.isPlausibleMeasurement(measured, fill,
        elapsedSeconds: elapsed);
    var newFill = fill;
    if (learned) {
      newFill = calc.updatedFillSeconds(fill, tank.fillCount, measured);
      await saveTank(tank.copyWith(
          fillTimeSeconds: newFill, fillCount: tank.fillCount + 1));
    }

    final record = calc.motorRunRecord(
      capacityLitres: tank.capacityLitres,
      fillTimeSeconds: newFill,
      startLevel: session.level,
      minutesLate: late,
      overflowMinutes: tank.overflowMinutes,
      motorHp: tank.motorHp,
      electricityRate: _settings.electricityRate,
    );
    await notifications.cancelMotorAlarm();
    await _setSession(null);
    await _addToToday(record);
    return MotorRunResult(
      record: record,
      learned: learned,
      fillTimeSeconds: newFill,
      minutesLate: late,
    );
  }

  /// Cancel: the motor was stopped early. Records the water pumped so far
  /// (flowRate × elapsed); nothing counts as saved.
  Future<void> cancelMotorSession() async {
    final session = _motorSession;
    await notifications.cancelMotorAlarm();
    await _setSession(null);
    if (session == null || session.isCalibration) return;
    final tank = tankById(session.tankId);
    final fill = tank?.fillTimeSeconds;
    if (tank == null || fill == null) return;
    final elapsedMin = calc.fromDeviceSeconds(elapsedSeconds(session),
            demoMode: session.demoMode) /
        60;
    final pumped = calc.pumpedLitresStoppedEarly(
      calc.motorFlowRateLpm(tank.capacityLitres, fill),
      elapsedMin,
      maxLitres: calc.pumpedLitres(tank.capacityLitres, session.level),
    );
    if (pumped > 0) await _addToToday(DailyRecord(used: pumped));
  }

  static Duration _seconds(double s) =>
      Duration(milliseconds: (s * 1000).round());

  // ---------------------------------------------------------------
  // Fixtures (taps) & flow history
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
        Fixture(id: _newId(), name: name, flowRateLps: flowRateLps),
      ]);

  Future<void> updateFixture(Fixture fixture) => _saveFixtures([
        for (final f in _fixtures) f.id == fixture.id ? fixture : f,
      ]);

  Future<void> deleteFixture(String id) =>
      _saveFixtures(_fixtures.where((f) => f.id != id).toList());

  /// Saves a Flow Timer run and adds its litres to today's usage.
  Future<void> addFlowRecord(FlowRecord record) async {
    await storage.addFlowRecord(record);
    _flowHistory = storage.loadFlowHistory();
    await _addToToday(DailyRecord(used: record.litres));
  }

  // ---------------------------------------------------------------
  // Leaks
  // ---------------------------------------------------------------

  List<Leak> get leaks => List.unmodifiable(_leaks);
  List<Leak> get activeLeaks => _leaks.where((l) => l.isActive).toList();

  Future<void> _saveLeaks(List<Leak> list) async {
    _leaks = list;
    notifyListeners();
    await storage.saveLeaks(list);
  }

  /// Saves a dripping tap; its daily loss counts as waste until fixed.
  Future<void> addLeak(String name, int dripsPer10s) => _saveLeaks([
        ..._leaks,
        Leak(
          id: _newId(),
          name: name,
          dripsPer10s: dripsPer10s,
          litresPerDay: calc.dripLitresPerDay(dripsPer10s),
          createdAt: now(),
        ),
      ]);

  /// "Fixed it!": stops counting waste from today and adds a month of
  /// avoided waste to today's savings. Returns litres saved per month.
  Future<double> fixLeak(String id) async {
    final leak = _leaks.where((l) => l.id == id).firstOrNull;
    if (leak == null || !leak.isActive) return 0;
    await _saveLeaks([
      for (final l in _leaks) l.id == id ? l.fixed(now()) : l,
    ]);
    final monthly = leak.litresPerDay * calc.daysPerMonth;
    await _addToToday(DailyRecord(saved: monthly));
    return monthly;
  }

  /// Fix a leak counted once (not saved as active): adds the monthly saving.
  Future<void> addFixedDripSaving(int dripsPer10s) =>
      _addToToday(DailyRecord(saved: calc.dripLitresPerMonth(dripsPer10s)));

  /// Removes a leak saved by mistake (no saving added).
  Future<void> deleteLeak(String id) =>
      _saveLeaks(_leaks.where((l) => l.id != id).toList());

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

  /// Completes the test. Any overnight loss is recorded as wasted today.
  Future<void> saveMorningReading(double reading) async {
    final test = _meterTest;
    if (test == null) return;
    _meterTest = test.withMorning(reading, now());
    notifyListeners();
    await storage.saveMeterTest(_meterTest!);
    await notifications.cancelMeterReminder();
    final loss = calc.overnightLossLitres(test.nightReading, reading,
        cubicMetres: test.unit == MeterUnit.cubicMetres);
    if (calc.isLeakLikely(loss)) await _addToToday(DailyRecord(wasted: loss));
  }

  Future<void> clearMeterTest() async {
    _meterTest = null;
    notifyListeners();
    await storage.clearMeterTest();
    await notifications.cancelMeterReminder();
  }

  // ---------------------------------------------------------------
  // Tips
  // ---------------------------------------------------------------

  Tip tipFor(DateTime day) =>
      allTips[calc.tipIndexForDate(day, allTips.length)];

  Tip get todaysTip => tipFor(now());

  /// Schedules the next two weeks of 8 AM tips (if turned on).
  Future<void> refreshTipNotifications() async {
    if (!_settings.tipNotifications) {
      await notifications.cancelTips();
      return;
    }
    final t = now();
    final tips = [
      for (var i = 0; i < NotificationService.tipDaysAhead; i++)
        (
          when: DateTime(t.year, t.month, t.day + i, 8),
          body: tipFor(DateTime(t.year, t.month, t.day + i))
              .text(_settings.languageCode),
        ),
    ];
    await notifications.scheduleTips(tips, strings);
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
    await _addToToday(DailyRecord(saved: todaysChallenge.litres));
    return ChallengeResult(streak: newStreak, newBadges: newBadges);
  }
}
