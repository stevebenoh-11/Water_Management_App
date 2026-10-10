import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/day_savings.dart';
import 'package:jalmitra/models/meter_test.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/services/app_controller.dart';
import 'package:jalmitra/services/storage_service.dart';

import 'helpers.dart';

void main() {
  late StorageService storage;
  late FakeNotifications notes;
  late FakeClock clock;
  late AppController app;

  setUp(() async {
    storage = await freshStorage();
    notes = FakeNotifications();
    clock = FakeClock(DateTime(2026, 10, 10, 6, 0));
    app = AppController(storage, notifications: notes, clock: clock.call);
  });

  group('Motor Guard calibration', () {
    test('saves fill time after a real calibration', () async {
      await app.startCalibration();
      expect(app.motorSession!.isCalibration, isTrue);
      clock.advance(const Duration(minutes: 24));
      final fill = await app.finishCalibration();
      expect(fill, 1440);
      expect(app.fillTime, 1440);
      expect(app.fillCount, 1);
      expect(app.motorSession, isNull);
    });

    test('rejects a calibration that is too short', () async {
      await app.startCalibration();
      clock.advance(const Duration(seconds: 5));
      expect(await app.finishCalibration(), isNull);
      expect(app.isCalibrated, isFalse);
      expect(app.motorSession, isNotNull, reason: 'still calibrating');
    });

    test('demo mode: 24 device seconds count as 24 minutes', () async {
      await app.setDemoMode(true);
      await app.startCalibration();
      clock.advance(const Duration(seconds: 24));
      expect(await app.finishCalibration(), 1440);
    });
  });

  group('Motor Guard daily mode', () {
    setUp(() => storage.saveCalibration(1440, 1));

    test('half tank: full in 12 min, alarm at 10 min', () async {
      await app.startMotorSession(0.5);
      final s = app.motorSession!;
      expect(s.endTime, clock.now.add(const Duration(minutes: 12)));
      expect(notes.motorAlarm, clock.now.add(const Duration(minutes: 10)));
      expect(app.alarmTimeFor(s), notes.motorAlarm);
    });

    test('demo mode: full in 12 s, alarm at 10 s', () async {
      await app.setDemoMode(true);
      await app.startMotorSession(0.5);
      expect(app.motorSession!.endTime,
          clock.now.add(const Duration(seconds: 12)));
      expect(notes.motorAlarm, clock.now.add(const Duration(seconds: 10)));
    });

    test('less than 2 min left → alarm immediately', () async {
      await storage.saveCalibration(400, 1); // 3/4 full → 100 s left
      await app.startMotorSession(0.75);
      expect(notes.motorAlarm, clock.now);
    });

    test('session survives app restart', () async {
      await app.startMotorSession(0.25);
      clock.advance(const Duration(minutes: 5));
      final reopened =
          AppController(storage, notifications: notes, clock: clock.call);
      final s = reopened.motorSession!;
      expect(s.level, 0.25);
      expect(reopened.remainingSeconds(s), 13 * 60);
    });

    test('Tank Full learns and records savings', () async {
      await app.startMotorSession(0.5);
      clock.advance(const Duration(minutes: 13)); // measured = 26 min
      final r = (await app.tankFull())!;
      expect(r.learned, isTrue);
      expect(r.fillTimeSeconds, 1500); // (1440 + 1560) / 2
      expect(app.fillCount, 2);
      expect(app.motorSession, isNull);
      expect(notes.motorAlarm, isNull);
      // 1000 L / 25 min = 40 L/min × 5 min = 200 L
      expect(r.savings.litres, closeTo(200, 1e-9));
      expect(r.savings.rupees, closeTo(0.373, 0.001));
      expect(app.savingsOn(clock.now).litres, closeTo(200, 1e-9));
    });

    test('accidental early Tank Full is not learned', () async {
      await app.startMotorSession(0);
      clock.advance(const Duration(seconds: 20));
      final r = (await app.tankFull())!;
      expect(r.learned, isFalse);
      expect(app.fillTime, 1440);
      expect(app.fillCount, 1);
    });

    test('Cancel clears session and alarm without savings', () async {
      await app.startMotorSession(0);
      await app.cancelMotorSession();
      expect(app.motorSession, isNull);
      expect(notes.motorAlarm, isNull);
      expect(app.weekSavings.litres, 0);
    });

    test('recalibrate forgets fill time', () async {
      await app.startMotorSession(0);
      await app.recalibrate();
      expect(app.isCalibrated, isFalse);
      expect(app.motorSession, isNull);
    });
  });

  group('Challenges', () {
    test('Done adds litres, grows streak, awards badges', () async {
      for (var day = 0; day < 3; day++) {
        final r = await app.completeTodaysChallenge();
        expect(r!.streak, day + 1);
        if (day == 2) expect(r.newBadges, [3]);
        expect(await app.completeTodaysChallenge(), isNull,
            reason: 'only once per day');
        clock.advance(const Duration(days: 1));
      }
      expect(app.badges, [3]);
      expect(app.weekSavings.litres, greaterThan(0));
    });

    test('missing a day resets the streak', () async {
      await app.completeTodaysChallenge();
      clock.advance(const Duration(days: 1));
      await app.completeTodaysChallenge();
      expect(app.streak, 2);
      clock.advance(const Duration(days: 2));
      expect(app.streak, 0);
      final r = await app.completeTodaysChallenge();
      expect(r!.streak, 1);
    });

    test('challenge rotates daily', () {
      final first = app.todaysChallenge.id;
      clock.advance(const Duration(days: 1));
      expect(app.todaysChallenge.id, isNot(first));
    });
  });

  group('Night meter test', () {
    test('night reading schedules a 7 AM reminder', () async {
      clock.now = DateTime(2026, 10, 10, 22, 30);
      await app.saveNightReading(1234.5, MeterUnit.cubicMetres);
      expect(notes.meterReminder, DateTime(2026, 10, 11, 7));
      await app.saveMorningReading(1234.512);
      expect(app.meterTest!.isComplete, isTrue);
      expect(notes.meterReminder, isNull);
    });

    test('next 7 AM before and after 7', () {
      expect(AppController.nextSevenAm(DateTime(2026, 10, 10, 2)),
          DateTime(2026, 10, 10, 7));
      expect(AppController.nextSevenAm(DateTime(2026, 10, 31, 7, 1)),
          DateTime(2026, 11, 1, 7));
    });
  });

  test('fixtures add / update / delete', () async {
    await app.addFixture('Kitchen tap', 0.1);
    final f = app.fixtures.single;
    await app.updateFixture(f.copyWith(name: 'Sink'));
    expect(app.fixtures.single.name, 'Sink');
    await app.deleteFixture(f.id);
    expect(app.fixtures, isEmpty);
  });

  test('week savings only counts the last 7 days', () async {
    await storage.addSavings(const DaySavings(litres: 100),
        day: DateTime(2026, 10, 1)); // 9 days ago
    await storage.addSavings(const DaySavings(litres: 50),
        day: DateTime(2026, 10, 4)); // 6 days ago
    final fresh =
        AppController(storage, notifications: notes, clock: clock.call);
    await fresh.addSavings(const DaySavings(litres: 10));
    expect(fresh.weekSavings.litres, 60);
  });

  test('reset clears everything and cancels alarms', () async {
    await app.completeOnboarding(const UserSettings(tankCapacityLitres: 500));
    await storage.saveCalibration(1440, 1);
    await app.startMotorSession(0);
    await app.resetAll();
    expect(app.onboarded, isFalse);
    expect(app.isCalibrated, isFalse);
    expect(app.settings.tankCapacityLitres, 1000);
    expect(notes.motorAlarm, isNull);
  });
}
