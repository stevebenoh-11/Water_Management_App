import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/day_savings.dart';
import '../models/fixture.dart';
import '../models/flow_record.dart';
import '../models/meter_test.dart';
import '../models/motor_session.dart';
import '../models/user_settings.dart';

/// Formats a date as yyyy-MM-dd (local time), used as the dailySavings key.
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

  // Storage keys (see CLAUDE.md "Data").
  static const kOnboardingDone = 'onboardingDone';
  static const kPermissionsAsked = 'permissionsAsked';
  static const kSettings = 'settings';
  static const kFillTime = 'fillTime';
  static const kFillCount = 'fillCount';
  static const kActiveMotorSession = 'activeMotorSession';
  static const kFixtures = 'fixtures';
  static const kDailySavings = 'dailySavings';
  static const kFlowHistory = 'flowHistory';
  static const kChallengeStreak = 'challengeStreak';
  static const kLastChallengeDate = 'lastChallengeDate';
  static const kBadges = 'badges';
  static const kMeterTest = 'meterTest';

  static const allKeys = <String>{
    kOnboardingDone,
    kPermissionsAsked,
    kSettings,
    kFillTime,
    kFillCount,
    kActiveMotorSession,
    kFixtures,
    kDailySavings,
    kFlowHistory,
    kChallengeStreak,
    kLastChallengeDate,
    kBadges,
    kMeterTest,
  };

  /// Keep at most this many flow history entries.
  static const maxFlowHistory = 100;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(allowList: allKeys),
    );
    return StorageService(prefs);
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

  // ---------- Onboarding ----------

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

  // ---------- Motor calibration ----------

  /// Seconds to fill the tank from empty, or null if not calibrated yet.
  double? get fillTime => _prefs.getDouble(kFillTime);

  int get fillCount => _prefs.getInt(kFillCount) ?? 0;

  Future<void> saveCalibration(double fillTimeSeconds, int count) async {
    await _prefs.setDouble(kFillTime, fillTimeSeconds);
    await _prefs.setInt(kFillCount, count);
  }

  Future<void> clearCalibration() async {
    await _prefs.remove(kFillTime);
    await _prefs.remove(kFillCount);
  }

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

  // ---------- Fixtures ----------

  List<Fixture> loadFixtures() {
    final json = _readJson(kFixtures);
    if (json is! List) return [];
    final result = <Fixture>[];
    for (final item in json) {
      try {
        result.add(Fixture.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    return result;
  }

  Future<void> saveFixtures(List<Fixture> fixtures) =>
      _writeJson(kFixtures, fixtures.map((f) => f.toJson()).toList());

  // ---------- Daily savings ----------

  Map<String, DaySavings> loadDailySavings() {
    final json = _readJson(kDailySavings);
    if (json is! Map<String, dynamic>) return {};
    final result = <String, DaySavings>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = DaySavings.fromJson(value);
      }
    });
    return result;
  }

  /// Adds [amount] to the record for [day] (defaults to today).
  Future<void> addSavings(DaySavings amount, {DateTime? day}) async {
    final all = loadDailySavings();
    final key = dateKey(day ?? DateTime.now());
    all[key] = (all[key] ?? const DaySavings()) + amount;
    await _writeJson(
      kDailySavings,
      all.map((k, v) => MapEntry(k, v.toJson())),
    );
  }

  // ---------- Flow history ----------

  List<FlowRecord> loadFlowHistory() {
    final json = _readJson(kFlowHistory);
    if (json is! List) return [];
    final result = <FlowRecord>[];
    for (final item in json) {
      try {
        result.add(FlowRecord.fromJson(item as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries.
      }
    }
    return result;
  }

  /// Newest first; trimmed to [maxFlowHistory].
  Future<void> addFlowRecord(FlowRecord record) async {
    final list = [record, ...loadFlowHistory()];
    final trimmed = list.take(maxFlowHistory).map((r) => r.toJson()).toList();
    await _writeJson(kFlowHistory, trimmed);
  }

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
