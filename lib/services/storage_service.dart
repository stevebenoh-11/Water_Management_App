import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../models/motor_session.dart';
import '../models/fixture.dart';
import '../models/daily_savings.dart';
import '../models/meter_test.dart';

class StorageService {
  static const String _keySettings = 'user_settings';
  static const String _keyFillTime = 'fill_time';
  static const String _keyFillCount = 'fill_count';
  static const String _keyMotorSession = 'active_motor_session';
  static const String _keyFixtures = 'fixtures';
  static const String _keyDailySavings = 'daily_savings';
  static const String _keyChallengeStreak = 'challenge_streak';
  static const String _keyLastChallengeDate = 'last_challenge_date';
  static const String _keyBadges = 'badges';
  static const String _keyMeterTest = 'meter_test';

  final SharedPreferences prefs;

  StorageService(this.prefs);

  static Future<StorageService> getInstance() async {
    final SharedPreferences sp = await SharedPreferences.getInstance();
    return StorageService(sp);
  }

  // User Settings
  UserSettings getUserSettings() {
    final String? raw = prefs.getString(_keySettings);
    if (raw == null) return UserSettings();
    try {
      return UserSettings.fromJson(raw);
    } catch (_) {
      return UserSettings();
    }
  }

  Future<bool> saveUserSettings(UserSettings settings) async {
    return await prefs.setString(_keySettings, settings.toJson());
  }

  // Motor Calibration
  double? getFillTime() => prefs.getDouble(_keyFillTime);
  int getFillCount() => prefs.getInt(_keyFillCount) ?? 0;

  Future<void> saveMotorCalibration(double fillTime, int fillCount) async {
    await prefs.setDouble(_keyFillTime, fillTime);
    await prefs.setInt(_keyFillCount, fillCount);
  }

  // Active Motor Session
  MotorSession? getActiveMotorSession() {
    final String? raw = prefs.getString(_keyMotorSession);
    if (raw == null) return null;
    try {
      return MotorSession.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveActiveMotorSession(MotorSession? session) async {
    if (session == null) {
      return await prefs.remove(_keyMotorSession);
    }
    return await prefs.setString(_keyMotorSession, session.toJson());
  }

  // Fixtures
  List<Fixture> getFixtures() {
    final List<String>? rawList = prefs.getStringList(_keyFixtures);
    if (rawList == null || rawList.isEmpty) {
      return [
        Fixture(id: 'shower', name: 'Bathroom Shower', flowRateLps: 0.15),
        Fixture(id: 'kitchen_tap', name: 'Kitchen Tap', flowRateLps: 0.10),
      ];
    }
    return rawList.map((e) => Fixture.fromJson(e)).toList();
  }

  Future<bool> saveFixtures(List<Fixture> fixtures) async {
    final List<String> rawList = fixtures.map((e) => e.toJson()).toList();
    return await prefs.setStringList(_keyFixtures, rawList);
  }

  // Daily Savings
  Map<String, DailySavings> getDailySavingsMap() {
    final String? raw = prefs.getString(_keyDailySavings);
    if (raw == null) return {};
    try {
      final Map<String, dynamic> map = json.decode(raw);
      return map.map((key, value) => MapEntry(key, DailySavings.fromMap(value)));
    } catch (_) {
      return {};
    }
  }

  Future<void> addSavings({
    required double litres,
    required double kwh,
    required double rupees,
    String? dateStr,
  }) async {
    final String dateKey = dateStr ?? DateTime.now().toIso8601String().substring(0, 10);
    final Map<String, DailySavings> currentMap = getDailySavingsMap();
    final DailySavings existing = currentMap[dateKey] ??
        DailySavings(date: dateKey, litres: 0.0, kwh: 0.0, rupees: 0.0);

    final DailySavings updated = DailySavings(
      date: dateKey,
      litres: existing.litres + litres,
      kwh: existing.kwh + kwh,
      rupees: existing.rupees + rupees,
    );
    currentMap[dateKey] = updated;

    final Map<String, dynamic> rawMap =
        currentMap.map((key, value) => MapEntry(key, value.toMap()));
    await prefs.setString(_keyDailySavings, json.encode(rawMap));
  }

  // Challenges & Streaks
  int getChallengeStreak() => prefs.getInt(_keyChallengeStreak) ?? 0;
  String? getLastChallengeDate() => prefs.getString(_keyLastChallengeDate);
  List<String> getBadges() => prefs.getStringList(_keyBadges) ?? [];

  Future<void> saveChallengeCompletion({
    required int streak,
    required String dateStr,
    required List<String> badges,
  }) async {
    await prefs.setInt(_keyChallengeStreak, streak);
    await prefs.setString(_keyLastChallengeDate, dateStr);
    await prefs.setStringList(_keyBadges, badges);
  }

  // Meter Test Record
  MeterTestRecord? getMeterTestRecord() {
    final String? raw = prefs.getString(_keyMeterTest);
    if (raw == null) return null;
    try {
      return MeterTestRecord.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveMeterTestRecord(MeterTestRecord? record) async {
    if (record == null) return await prefs.remove(_keyMeterTest);
    return await prefs.setString(_keyMeterTest, record.toJson());
  }

  // Clear all data
  Future<bool> clearAll() async {
    return await prefs.clear();
  }
}
