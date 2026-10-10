import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/daily_record.dart';
import 'package:jalmitra/models/fixture.dart';
import 'package:jalmitra/models/flow_record.dart';
import 'package:jalmitra/models/leak.dart';
import 'package:jalmitra/models/meter_test.dart';
import 'package:jalmitra/models/motor_session.dart';
import 'package:jalmitra/models/tank_profile.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import 'helpers.dart';

void main() {
  late StorageService storage;

  setUp(() async => storage = await freshStorage());

  test('dateKey pads to yyyy-MM-dd', () {
    expect(dateKey(DateTime(2026, 3, 7)), '2026-03-07');
  });

  test('fresh install: defaults and empty data', () {
    expect(storage.isOnboarded, isFalse);
    expect(storage.loadSettings().peopleCount, 4);
    expect(storage.loadTanks(), isEmpty);
    expect(storage.loadMotorSession(), isNull);
    expect(storage.loadDailyRecords(), isEmpty);
    expect(storage.loadLeaks(), isEmpty);
  });

  test('settings round trip', () async {
    await storage.saveSettings(const UserSettings(
      languageCode: 'ta',
      peopleCount: 6,
      areaType: AreaType.village,
      litresPerPersonOverride: 80,
      tipNotifications: true,
    ));
    final s = (await StorageService.create()).loadSettings();
    expect(s.languageCode, 'ta');
    expect(s.peopleCount, 6);
    expect(s.areaType, AreaType.village);
    expect(s.litresPerPersonOverride, 80);
    expect(s.tipNotifications, isTrue);
  });

  test('tanks round trip with all fields', () async {
    await storage.saveTanks([
      TankProfile(
        id: 't1',
        name: 'Roof',
        type: TankType.overhead,
        material: TankMaterial.concrete,
        shape: TankShape.rectangular,
        capacityLitres: 3000,
        lengthM: 2,
        widthM: 1.5,
        heightM: 1,
        motorHp: 1.5,
        overflowMinutes: 7,
        fillTimeSeconds: 1800,
        fillCount: 3,
        lastCleaned: DateTime(2026, 7, 1),
        cleaningIntervalDays: 90,
        isDefault: true,
      ),
    ]);
    final t = storage.loadTanks().single;
    expect(t.material, TankMaterial.concrete);
    expect(t.shape, TankShape.rectangular);
    expect(t.widthM, 1.5);
    expect(t.fillTimeSeconds, 1800);
    expect(t.fillCount, 3);
    expect(t.lastCleaned, DateTime(2026, 7, 1));
    expect(t.isDefault, isTrue);
  });

  test('in-progress Motor Guard session is restored', () async {
    final start = DateTime(2026, 10, 10, 7);
    await storage.saveMotorSession(MotorSession(
      startTime: start,
      level: 0.25,
      endTime: start.add(const Duration(minutes: 18)),
      tankId: 't1',
    ));
    final s = (await StorageService.create()).loadMotorSession()!;
    expect(s.level, 0.25);
    expect(s.tankId, 't1');
    expect(s.endTime.difference(s.startTime).inMinutes, 18);
  });

  test('daily records accumulate per day', () async {
    final day = DateTime(2026, 10, 10);
    await storage.addToRecord(const DailyRecord(used: 500, saved: 208), day: day);
    await storage.addToRecord(const DailyRecord(used: 30, wasted: 12), day: day);
    final r = storage.loadDailyRecords()['2026-10-10']!;
    expect(r.used, 530);
    expect(r.wasted, 12);
    expect(r.saved, 208);
  });

  test('fixtures, flow history, leaks, meter test', () async {
    await storage.saveFixtures(
        const [Fixture(id: 'a', name: 'Kitchen tap', flowRateLps: 0.1)]);
    await storage.addFlowRecord(FlowRecord(
        fixtureName: 'Kitchen tap',
        litres: 12,
        seconds: 120,
        limitLitres: 40,
        timestamp: DateTime(2026, 10, 10)));
    await storage.saveLeaks([
      Leak(
          id: 'l',
          name: 'Bathroom tap',
          dripsPer10s: 3,
          litresPerDay: 6.48,
          createdAt: DateTime(2026, 10, 9)),
    ]);
    await storage.saveMeterTest(MeterTest(
        nightReading: 1.2,
        nightTime: DateTime(2026, 10, 9, 22),
        unit: MeterUnit.cubicMetres));
    expect(storage.loadFixtures().single.name, 'Kitchen tap');
    expect(storage.loadFlowHistory().single.litres, 12);
    expect(storage.loadLeaks().single.isActive, isTrue);
    expect(storage.loadMeterTest()!.unit, MeterUnit.cubicMetres);
  });

  test('migrates the single-tank version into a first tank', () async {
    final backend = InMemorySharedPreferencesAsync.withData({
      'onboardingDone': true,
      'settings': jsonEncode({
        'tankCapacityLitres': 2000,
        'motorHp': 1.5,
        'overflowMinutes': 8,
        'electricityRate': 7,
      }),
      'fillTime': 1500.0,
      'fillCount': 4,
      'dailySavings': jsonEncode({
        '2026-10-09': {'litres': 208, 'kwh': 0.06, 'rupees': 0.37}
      }),
    });
    SharedPreferencesAsyncPlatform.instance = backend;
    final migrated = await StorageService.create();
    final tank = migrated.loadTanks().single;
    expect(tank.capacityLitres, 2000);
    expect(tank.motorHp, 1.5);
    expect(tank.overflowMinutes, 8);
    expect(tank.fillTimeSeconds, 1500);
    expect(tank.fillCount, 4);
    expect(tank.isDefault, isTrue);
    expect(migrated.loadDailyRecords()['2026-10-09']!.saved, 208);
    expect(migrated.loadSettings().electricityRate, 7);
    // Old keys are cleaned up.
    expect(
        await backend.getDouble('fillTime', const SharedPreferencesOptions()),
        isNull);
  });

  test('corrupt JSON never crashes', () async {
    final backend = InMemorySharedPreferencesAsync.withData({
      'tanks': 'not json',
      'dailyRecords': '{oops',
    });
    SharedPreferencesAsyncPlatform.instance = backend;
    final s = await StorageService.create();
    expect(s.loadTanks(), isEmpty);
    expect(s.loadDailyRecords(), isEmpty);
  });

  test('resetAll wipes everything', () async {
    await storage.setOnboarded(true);
    await storage.resetAll();
    expect(storage.isOnboarded, isFalse);
  });
}
