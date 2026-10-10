import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/daily_record.dart';
import 'package:jalmitra/models/flow_record.dart';
import 'package:jalmitra/models/meter_test.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/services/app_controller.dart';
import 'package:jalmitra/services/calc_service.dart' as calc;
import 'package:jalmitra/services/storage_service.dart';

import 'helpers.dart';

void main() {
  late StorageService storage;
  late FakeNotifications notes;
  late FakeClock clock;
  late AppController app;

  AppController reopen() =>
      AppController(storage, notifications: notes, clock: clock.call);

  setUp(() async {
    storage = await freshStorage();
    notes = FakeNotifications();
    clock = FakeClock(DateTime(2026, 10, 10, 6, 0));
    await storage.saveTanks([testTank()]);
    app = reopen();
  });

  group('Onboarding', () {
    test('saves settings and the first tank as default', () async {
      await app.completeOnboarding(
        const UserSettings(peopleCount: 5, areaType: AreaType.town),
        testTank(id: 'x', name: 'Roof', isDefault: false),
      );
      expect(app.onboarded, isTrue);
      expect(app.tanks.single.name, 'Roof');
      expect(app.tanks.single.isDefault, isTrue);
      expect(app.requiredPerDay, 350); // 5 × 70
    });
  });

  group('Tanks', () {
    test('add, set default, delete; at least one remains', () async {
      await app.saveTank(testTank(id: 't2', name: 'Sump', isDefault: false));
      expect(app.tanks.length, 2);
      await app.setDefaultTank('t2');
      expect(app.defaultTank!.id, 't2');
      expect(app.tanks.where((t) => t.isDefault).length, 1);
      expect(await app.deleteTank('t2'), isTrue);
      expect(app.defaultTank!.id, 't1', reason: 'remaining tank becomes default');
      expect(await app.deleteTank('t1'), isFalse);
      expect(app.tanks.length, 1);
    });

    test('mark cleaned and cleaning due', () async {
      await app.saveTank(app.tanks.single.copyWith(
          lastCleaned: DateTime(2026, 1, 1), cleaningIntervalDays: 90));
      expect(app.tanksDueForCleaning.length, 1);
      await app.markTankCleaned('t1');
      expect(app.tanksDueForCleaning, isEmpty);
    });

    test('unnamed tank shows the translated default name', () {
      expect(app.tankDisplayName(testTank(name: '')), 'Overhead tank');
    });
  });

  group('Motor Guard calibration', () {
    test('saves fill time on the tank and records a full tank used', () async {
      await app.startCalibration('t1');
      clock.advance(const Duration(minutes: 24));
      expect(await app.finishCalibration(), 1440);
      expect(app.tankById('t1')!.fillTimeSeconds, 1440);
      expect(app.tankById('t1')!.fillCount, 1);
      expect(app.today.used, 1000);
    });

    test('rejects a calibration that is too short', () async {
      await app.startCalibration('t1');
      clock.advance(const Duration(seconds: 5));
      expect(await app.finishCalibration(), isNull);
      expect(app.tankById('t1')!.isCalibrated, isFalse);
    });

    test('demo mode: 24 device seconds count as 24 minutes', () async {
      await app.setDemoMode(true);
      await app.startCalibration('t1');
      clock.advance(const Duration(seconds: 24));
      expect(await app.finishCalibration(), 1440);
    });
  });

  group('Motor Guard daily mode', () {
    setUp(() async {
      await storage.saveTanks([testTank(fillTime: 1440)]);
      app = reopen();
    });

    test('half tank: full in 12 min, alarm at 10 min with tank name', () async {
      await app.startMotorSession('t1', 0.5);
      expect(app.motorSession!.endTime,
          clock.now.add(const Duration(minutes: 12)));
      expect(notes.motorAlarm, clock.now.add(const Duration(minutes: 10)));
      expect(notes.motorAlarmTitle, 'Overhead tank: almost full!');
    });

    test('demo mode: full in 12 s, alarm at 10 s', () async {
      await app.setDemoMode(true);
      await app.startMotorSession('t1', 0.5);
      expect(notes.motorAlarm, clock.now.add(const Duration(seconds: 10)));
    });

    test('less than 2 min left → alarm immediately', () async {
      await storage.saveTanks([testTank(fillTime: 400)]);
      app = reopen();
      await app.startMotorSession('t1', 0.75); // 100 s left
      expect(notes.motorAlarm, clock.now);
    });

    test('session survives app restart', () async {
      await app.startMotorSession('t1', 0.25);
      clock.advance(const Duration(minutes: 5));
      final reopened = reopen();
      expect(reopened.selectedTank!.id, 't1');
      expect(reopened.remainingSeconds(reopened.motorSession!), 13 * 60);
    });

    test('Tank Full on time: learns, records used and saved', () async {
      await app.startMotorSession('t1', 0.5);
      clock.advance(const Duration(minutes: 12));
      final r = (await app.tankFull())!;
      expect(r.learned, isTrue);
      expect(r.minutesLate, 0);
      expect(r.record.used, 500);
      expect(r.record.wasted, 0);
      expect(r.record.saved, closeTo(208.33, 0.01));
      expect(app.today.used, 500);
      expect(app.tankById('t1')!.fillCount, 2);
      expect(notes.motorAlarm, isNull);
    });

    test('Tank Full 2 min late: overflow wasted, less saved', () async {
      await app.startMotorSession('t1', 0);
      clock.advance(const Duration(minutes: 26));
      final r = (await app.tankFull())!;
      expect(r.minutesLate, closeTo(2, 1e-9));
      // Learned 25 min → 40 L/min: 80 L wasted, 3 min × 40 = 120 L saved.
      expect(r.fillTimeSeconds, 1500);
      expect(r.record.wasted, closeTo(80, 1e-6));
      expect(r.record.saved, closeTo(120, 1e-6));
      expect(app.today.wasted, closeTo(80, 1e-6));
    });

    test('accidental early Tank Full is not learned', () async {
      await app.startMotorSession('t1', 0);
      clock.advance(const Duration(seconds: 20));
      final r = (await app.tankFull())!;
      expect(r.learned, isFalse);
      expect(app.tankById('t1')!.fillTimeSeconds, 1440);
    });

    test('Cancel records water pumped so far, no savings', () async {
      await app.startMotorSession('t1', 0);
      clock.advance(const Duration(minutes: 6));
      await app.cancelMotorSession();
      expect(app.motorSession, isNull);
      expect(notes.motorAlarm, isNull);
      expect(app.today.used, closeTo(250, 0.01)); // 41.67 L/min × 6
      expect(app.today.saved, 0);
    });

    test('recalibrate forgets the fill time', () async {
      await app.recalibrate('t1');
      expect(app.tankById('t1')!.isCalibrated, isFalse);
    });
  });

  group('Usage', () {
    test('Flow Timer litres count as used', () async {
      await app.addFlowRecord(FlowRecord(
          fixtureName: 'Tap',
          litres: 30,
          seconds: 300,
          limitLitres: 40,
          timestamp: clock.now));
      expect(app.today.used, 30);
    });

    test('active leak adds daily waste until fixed, then saving', () async {
      await app.addLeak('Bathroom tap', 3);
      expect(app.today.wasted, closeTo(6.48, 1e-9));
      clock.advance(const Duration(days: 1));
      expect(app.today.wasted, closeTo(6.48, 1e-9));
      final monthly = await app.fixLeak(app.activeLeaks.single.id);
      expect(monthly, closeTo(194.4, 1e-9));
      expect(app.today.wasted, 0);
      expect(app.today.saved, closeTo(194.4, 1e-9));
      expect(app.activeLeaks, isEmpty);
    });

    test('overnight meter loss is recorded as wasted', () async {
      clock.now = DateTime(2026, 10, 10, 22);
      await app.saveNightReading(1234.5, MeterUnit.cubicMetres);
      expect(notes.meterReminder, DateTime(2026, 10, 11, 7));
      clock.now = DateTime(2026, 10, 11, 7, 5);
      await app.saveMorningReading(1234.512);
      expect(app.today.wasted, closeTo(12, 1e-6));
      expect(notes.meterReminder, isNull);
    });

    test('requirement and usage level', () async {
      expect(app.requiredPerDay, 540); // 4 × 135 (city)
      await app.updateSettings(app.settings.copyWith(litresPerPersonOverride: 100));
      expect(app.requiredPerDay, 400);
      expect(app.todayUsageLevel, calc.UsageLevel.under);
      await storage.addToRecord(const DailyRecord(used: 500), day: clock.now);
      app = reopen();
      expect(app.todayUsageLevel, calc.UsageLevel.over);
    });

    test('7-day average ignores empty days', () async {
      await storage.addToRecord(const DailyRecord(used: 400),
          day: DateTime(2026, 10, 8));
      await storage.addToRecord(const DailyRecord(used: 600),
          day: DateTime(2026, 10, 10));
      app = reopen();
      expect(app.averageUsed(7), 500);
    });

    test('year totals, monthly bars and projection', () async {
      await storage.addToRecord(const DailyRecord(used: 300, wasted: 30),
          day: DateTime(2026, 9, 1));
      await storage.addToRecord(const DailyRecord(used: 500, saved: 200),
          day: DateTime(2026, 10, 10));
      await storage.addToRecord(const DailyRecord(used: 999),
          day: DateTime(2025, 12, 31)); // last year: ignored
      app = reopen();
      final y = app.yearStats();
      expect(y.total.used, 800);
      expect(y.total.wasted, 30);
      expect(y.monthly[8].used, 300); // September
      expect(y.monthly[9].used, 500); // October
      expect(y.daysCounted, 40); // 1 Sep – 10 Oct
      expect(y.projectedUsed, closeTo(800 / 40 * 365, 1e-9));
    });

    test('week totals only count the last 7 days', () async {
      await storage.addToRecord(const DailyRecord(saved: 100),
          day: DateTime(2026, 10, 1));
      await storage.addToRecord(const DailyRecord(saved: 50),
          day: DateTime(2026, 10, 4));
      app = reopen();
      expect(app.weekTotals.saved, 50);
    });
  });

  group('Tips', () {
    test('same tip all day, different tomorrow', () {
      final morning = app.todaysTip;
      clock.now = DateTime(2026, 10, 10, 22);
      expect(app.todaysTip, same(morning));
      clock.advance(const Duration(days: 1));
      expect(app.todaysTip, isNot(same(morning)));
    });

    test('tip notifications: off by default, 14 days when on', () async {
      await app.refreshTipNotifications();
      expect(notes.tips, isEmpty);
      await app.setTipNotifications(true);
      expect(notes.tips.length, 14);
      expect(notes.tips.first.when, DateTime(2026, 10, 10, 8));
      expect(notes.tips.first.body, app.todaysTip.en);
      await app.setTipNotifications(false);
      expect(notes.tips, isEmpty);
    });
  });

  group('Challenges', () {
    test('Done adds litres to saved, grows streak, awards badge', () async {
      for (var day = 0; day < 3; day++) {
        final r = await app.completeTodaysChallenge();
        expect(r!.streak, day + 1);
        if (day == 2) expect(r.newBadges, [3]);
        expect(await app.completeTodaysChallenge(), isNull);
        clock.advance(const Duration(days: 1));
      }
      expect(app.badges, [3]);
    });

    test('missing a day resets the streak', () async {
      await app.completeTodaysChallenge();
      clock.advance(const Duration(days: 3));
      expect(app.streak, 0);
    });
  });

  test('reset clears everything and cancels alarms', () async {
    await storage.saveTanks([testTank(fillTime: 1440)]);
    app = reopen();
    await app.startMotorSession('t1', 0);
    await app.resetAll();
    expect(app.onboarded, isFalse);
    expect(app.tanks, isEmpty);
    expect(notes.motorAlarm, isNull);
  });
}
