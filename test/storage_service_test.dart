import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/day_savings.dart';
import 'package:jalmitra/models/fixture.dart';
import 'package:jalmitra/models/flow_record.dart';
import 'package:jalmitra/models/meter_test.dart';
import 'package:jalmitra/models/motor_session.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    storage = await StorageService.create();
  });

  test('dateKey pads to yyyy-MM-dd', () {
    expect(dateKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(dateKey(DateTime(2026, 12, 25, 23, 59)), '2026-12-25');
  });

  test('fresh install: not onboarded, default settings, empty data', () {
    expect(storage.isOnboarded, isFalse);
    expect(storage.loadSettings().tankCapacityLitres, 1000);
    expect(storage.fillTime, isNull);
    expect(storage.fillCount, 0);
    expect(storage.loadMotorSession(), isNull);
    expect(storage.loadFixtures(), isEmpty);
    expect(storage.loadDailySavings(), isEmpty);
    expect(storage.loadFlowHistory(), isEmpty);
    expect(storage.challengeStreak, 0);
    expect(storage.loadBadges(), isEmpty);
    expect(storage.loadMeterTest(), isNull);
  });

  test('settings and onboarding persist', () async {
    await storage.saveSettings(
        const UserSettings(tankCapacityLitres: 500, languageCode: 'ta'));
    await storage.setOnboarded(true);
    final reopened = await StorageService.create();
    expect(reopened.isOnboarded, isTrue);
    expect(reopened.loadSettings().tankCapacityLitres, 500);
    expect(reopened.loadSettings().languageCode, 'ta');
  });

  test('calibration save and clear', () async {
    await storage.saveCalibration(1440, 1);
    expect(storage.fillTime, 1440);
    expect(storage.fillCount, 1);
    await storage.clearCalibration();
    expect(storage.fillTime, isNull);
  });

  test('motor session round trip', () async {
    final start = DateTime(2026, 10, 10, 7, 0);
    await storage.saveMotorSession(MotorSession(
      startTime: start,
      level: 0.25,
      endTime: start.add(const Duration(minutes: 18)),
    ));
    final s = storage.loadMotorSession()!;
    expect(s.level, 0.25);
    expect(s.endTime.difference(s.startTime).inMinutes, 18);
    await storage.clearMotorSession();
    expect(storage.loadMotorSession(), isNull);
  });

  test('fixtures round trip', () async {
    await storage.saveFixtures(const [
      Fixture(id: 'a', name: 'Kitchen tap', flowRateLps: 0.1),
      Fixture(id: 'b', name: 'Bathroom shower', flowRateLps: 0.15),
    ]);
    final list = storage.loadFixtures();
    expect(list.map((f) => f.name), ['Kitchen tap', 'Bathroom shower']);
  });

  test('addSavings accumulates per day', () async {
    final day = DateTime(2026, 10, 10);
    await storage.addSavings(
        const DaySavings(litres: 200, kwh: 0.06, rupees: 0.37),
        day: day);
    await storage.addSavings(const DaySavings(litres: 10), day: day);
    await storage.addSavings(const DaySavings(litres: 5),
        day: DateTime(2026, 10, 11));
    final all = storage.loadDailySavings();
    expect(all['2026-10-10']!.litres, 210);
    expect(all['2026-10-10']!.rupees, closeTo(0.37, 1e-9));
    expect(all['2026-10-11']!.litres, 5);
  });

  test('flow history is newest first and trimmed', () async {
    for (var i = 0; i < StorageService.maxFlowHistory + 5; i++) {
      await storage.addFlowRecord(FlowRecord(
        fixtureName: 'Tap $i',
        litres: i.toDouble(),
        seconds: i,
        limitLitres: 40,
        timestamp: DateTime(2026, 10, 10),
      ));
    }
    final list = storage.loadFlowHistory();
    expect(list.length, StorageService.maxFlowHistory);
    expect(list.first.fixtureName, 'Tap ${StorageService.maxFlowHistory + 4}');
  });

  test('challenge progress and badges', () async {
    await storage.saveChallengeProgress(3, '2026-10-10');
    await storage.saveBadges([3]);
    expect(storage.challengeStreak, 3);
    expect(storage.lastChallengeDate, '2026-10-10');
    expect(storage.loadBadges(), [3]);
  });

  test('meter test round trip with morning reading', () async {
    final night = MeterTest(
      nightReading: 1.234,
      nightTime: DateTime(2026, 10, 10, 22),
      unit: MeterUnit.cubicMetres,
    );
    await storage.saveMeterTest(night);
    expect(storage.loadMeterTest()!.isComplete, isFalse);
    await storage
        .saveMeterTest(night.withMorning(1.240, DateTime(2026, 10, 11, 7)));
    final t = storage.loadMeterTest()!;
    expect(t.isComplete, isTrue);
    expect(t.unit, MeterUnit.cubicMetres);
    expect(t.morningReading, 1.240);
  });

  test('resetAll wipes everything', () async {
    await storage.setOnboarded(true);
    await storage.saveCalibration(100, 2);
    await storage.resetAll();
    expect(storage.isOnboarded, isFalse);
    expect(storage.fillTime, isNull);
  });
}
