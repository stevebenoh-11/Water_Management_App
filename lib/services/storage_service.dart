import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_record.dart';
import '../models/fixture.dart';
import '../models/flow_record.dart';
import '../models/leak.dart';
import '../models/meter_test.dart';
import '../models/motor_session.dart';
import '../models/tank_profile.dart';
import '../models/user_settings.dart';

/// Formats a date as yyyy-MM-dd (local time), used as the daily record key.
String dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// All app data lives here, stored locally as JSON in shared_preferences.
/// Nothing ever leaves the phone.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static const kOnboardingDone = 'onboardingDone';
  static const kPermissionsAsked = 'permissionsAsked';
  static const kSettings = 'settings';
  static const kTanks = 'tanks';
  static const kActiveMotorSession = 'activeMotorSession';
  static const kFixtures = 'fixtures';
  static const kDailyRecords = 'dailyRecords';
  static const kFlowHistory = 'flowHistory';
  static const kLeaks = 'leaks';
  static const kChallengeStreak = 'challengeStreak';
  static const kLastChallengeDate = 'lastChallengeDate';
  static const kBadges = 'badges';
  static const kMeterTest = 'meterTest';

  // Keys from the first version, read once for migration.
  static const kLegacyFillTime = 'fillTime';
  static const kLegacyFillCount = 'fillCount';
  static const kLegacyDailySavings = 'dailySavings';

  static const allKeys = <String>{
    kOnboardingDone,
    kPermissionsAsked,
    kSettings,
    kTanks,
    kActiveMotorSession,
    kFixtures,
    kDailyRecords,
    kFlowHistory,
    kLeaks,
    kChallengeStreak,
    kLastChallengeDate,
    kBadges,
    kMeterTest,
    kLegacyFillTime,
    kLegacyFillCount,
    kLegacyDailySavings,
  };

  /// Keep at most this many flow history entries.
  static const maxFlowHistory = 100;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: allKeys),
    );
    final storage = StorageService(prefs);
    await storage._migrate();
    return storage;
  }

  // ---------- JSON helpers (never throw on corrupt data) ----------

  Object? _readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> _writeJson(String key, Object? value) =>
      _prefs.setString(key, jsonEncode(value));

  List<T> _readList<T>(String key, T Function(Map<String, dynamic>) parse) {
    final json = _readJson(key);
    if (json is! List) return [];
    final result = <T>[];
    for (final item in json) {
      try {
        result.add(parse(item as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    return result;
  }

  // ---------- Migration from the single-tank version ----------

  Future<void> _migrate() async {
    // Old single fill time → first tank.
    final legacyFill = _prefs.getDouble(kLegacyFillTime);
    if (_readJson(kTanks) == null && (isOnboarded || legacyFill != null)) {
      final raw = _readJson(kSettings);
      final settings = loadSettings();
      final capacity = raw is Map && raw['tankCapacityLitres'] is num
          ? (raw['tankCapacityLitres'] as num).toDouble()
          : UserSettings.defaultTankCapacity;
      await saveTanks([
        TankProfile(
          id: 'tank1',
          name: '', // shown as the translated default tank name
          capacityLitres: capacity,
          motorHp: settings.defaultMotorHp,
          overflowMinutes: settings.defaultOverflowMinutes,
          fillTimeSeconds: legacyFill,
          fillCount: _prefs.getInt(kLegacyFillCount) ?? (legacyFill == null ? 0 : 1),
          isDefault: true,
        ),
      ]);
    }
    await _prefs.remove(kLegacyFillTime);
    await _prefs.remove(kLegacyFillCount);

    // Old savings-only records → daily records.
    final legacySavings = _readJson(kLegacyDailySavings);
    if (legacySavings is Map<String, dynamic> &&
        _readJson(kDailyRecords) == null) {
      await _writeJson(kDailyRecords, legacySavings);
    }
    await _prefs.remove(kLegacyDailySavings);
  }

  // ---------- Onboarding & permissions ----------

  bool get isOnboarded => _prefs.getBool(kOnboardingDone) ?? false;

  Future<void> setOnboarded(bool value) =>
      _prefs.setBool(kOnboardingDone, value);

  /// Whether the polite permission explanation has been shown once.
  bool get permissionsAsked => _prefs.getBool(kPermissionsAsked) ?? false;

  Future<void> setPermissionsAsked(bool value) =>
      _prefs.setBool(kPermissionsAsked, value);

  // ---------- Settings ----------

  UserSettings loadSettings() {
    final json = _readJson(kSettings);
    if (json is Map<String, dynamic>) return UserSettings.fromJson(json);
    return const UserSettings();
  }

  Future<void> saveSettings(UserSettings settings) =>
      _writeJson(kSettings, settings.toJson());

  // ---------- Tanks ----------

  List<TankProfile> loadTanks() => _readList(kTanks, TankProfile.fromJson);

  Future<void> saveTanks(List<TankProfile> tanks) =>
      _writeJson(kTanks, tanks.map((t) => t.toJson()).toList());

  // ---------- Active motor session ----------

  MotorSession? loadMotorSession() {
    final json = _readJson(kActiveMotorSession);
    if (json is! Map<String, dynamic>) return null;
    try {
      return MotorSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMotorSession(MotorSession session) =>
      _writeJson(kActiveMotorSession, session.toJson());

  Future<void> clearMotorSession() => _prefs.remove(kActiveMotorSession);

  // ---------- Fixtures (taps) ----------

  List<Fixture> loadFixtures() => _readList(kFixtures, Fixture.fromJson);

  Future<void> saveFixtures(List<Fixture> fixtures) =>
      _writeJson(kFixtures, fixtures.map((f) => f.toJson()).toList());

  // ---------- Daily records ----------

  Map<String, DailyRecord> loadDailyRecords() {
    final json = _readJson(kDailyRecords);
    if (json is! Map<String, dynamic>) return {};
    final result = <String, DailyRecord>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = DailyRecord.fromJson(value);
      }
    });
    return result;
  }

  /// Adds [amount] to the record for [day].
  Future<void> addToRecord(DailyRecord amount, {required DateTime day}) async {
    final all = loadDailyRecords();
    final key = dateKey(day);
    all[key] = (all[key] ?? const DailyRecord()) + amount;
    await _writeJson(kDailyRecords, all.map((k, v) => MapEntry(k, v.toJson())));
  }

  // ---------- Flow history ----------

  List<FlowRecord> loadFlowHistory() =>
      _readList(kFlowHistory, FlowRecord.fromJson);

  /// Newest first; trimmed to [maxFlowHistory].
  Future<void> addFlowRecord(FlowRecord record) async {
    final list = [record, ...loadFlowHistory()];
    final trimmed = list.take(maxFlowHistory).map((r) => r.toJson()).toList();
    await _writeJson(kFlowHistory, trimmed);
  }

  // ---------- Leaks ----------

  List<Leak> loadLeaks() => _readList(kLeaks, Leak.fromJson);

  Future<void> saveLeaks(List<Leak> leaks) =>
      _writeJson(kLeaks, leaks.map((l) => l.toJson()).toList());

  // ---------- Challenges ----------

  int get challengeStreak => _prefs.getInt(kChallengeStreak) ?? 0;

  String? get lastChallengeDate => _prefs.getString(kLastChallengeDate);

  Future<void> saveChallengeProgress(int streak, String lastDate) async {
    await _prefs.setInt(kChallengeStreak, streak);
    await _prefs.setString(kLastChallengeDate, lastDate);
  }

  /// Earned badge milestones in days, e.g. [3, 7].
  List<int> loadBadges() {
    final json = _readJson(kBadges);
    if (json is! List) return [];
    return json.whereType<num>().map((n) => n.toInt()).toList();
  }

  Future<void> saveBadges(List<int> badges) => _writeJson(kBadges, badges);

  // ---------- Night meter test ----------

  MeterTest? loadMeterTest() {
    final json = _readJson(kMeterTest);
    if (json is! Map<String, dynamic>) return null;
    try {
      return MeterTest.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveMeterTest(MeterTest test) =>
      _writeJson(kMeterTest, test.toJson());

  Future<void> clearMeterTest() => _prefs.remove(kMeterTest);

  // ---------- Reset ----------

  /// Deletes every stored value (Settings → Reset all data).
  Future<void> resetAll() => _prefs.clear();
}
