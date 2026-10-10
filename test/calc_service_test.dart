import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/daily_record.dart';
import 'package:jalmitra/models/leak.dart';
import 'package:jalmitra/models/tank_profile.dart';
import 'package:jalmitra/models/user_settings.dart';
import 'package:jalmitra/services/calc_service.dart';

void main() {
  group('Motor Guard timing', () {
    test('remaining fill time = fillTime × (1 − level)', () {
      expect(remainingFillSeconds(1440, 0), 1440);
      expect(remainingFillSeconds(1440, 0.25), 1080);
      expect(remainingFillSeconds(1440, 0.5), 720);
      expect(remainingFillSeconds(1440, 0.75), 360);
    });

    test('alarm 120 s before full, immediately if under 120 s', () {
      expect(alarmDelaySeconds(720), 600);
      expect(alarmDelaySeconds(120), 0);
      expect(alarmDelaySeconds(90), 0);
    });

    test('demo mode: 1 minute = 1 second', () {
      expect(toDeviceSeconds(1440, demoMode: true), 24);
      expect(toDeviceSeconds(1440, demoMode: false), 1440);
      expect(fromDeviceSeconds(24, demoMode: true), 1440);
      expect(toDeviceSeconds(alarmLeadSeconds, demoMode: true), 2);
    });
  });

  group('Motor Guard learning', () {
    test('measured fill = elapsed ÷ (1 − level)', () {
      expect(measuredFillSeconds(720, 0.5), 1440);
      expect(measuredFillSeconds(360, 0.75), 1440);
    });

    test('self-learning running average', () {
      expect(updatedFillSeconds(1440, 1, 1560), 1500);
      expect(updatedFillSeconds(1500, 3, 1620), 1530);
    });

    test('ignores accidental and far-off runs', () {
      expect(isPlausibleMeasurement(1500, 1440, elapsedSeconds: 750), isTrue);
      expect(isPlausibleMeasurement(1500, 1440, elapsedSeconds: 5), isFalse);
      expect(isPlausibleMeasurement(10, 1440), isFalse);
      expect(isPlausibleMeasurement(1440 * 5, 1440), isFalse);
    });
  });

  group('Motor Guard water, energy, money', () {
    test('1000 L tank, 24 min fill → ~41.7 L/min', () {
      expect(motorFlowRateLpm(1000, 24 * 60), closeTo(41.67, 0.01));
    });

    test('water saved 41.67 × 5 → ~208 L', () {
      expect(waterSavedLitres(motorFlowRateLpm(1000, 1440), 5),
          closeTo(208.33, 0.01));
    });

    test('energy and money saved: 0.0622 kWh, ₹0.37', () {
      final kwh = energySavedKwh(1, 5);
      expect(kwh, closeTo(0.06217, 0.00001));
      expect(moneySavedRupees(kwh, 6), closeTo(0.373, 0.001));
    });

    test('water pumped', () {
      expect(pumpedLitres(1000, 0.5), 500);
      expect(pumpedLitres(1000, 0), 1000);
      expect(pumpedLitresStoppedEarly(41.67, 6, maxLitres: 1000),
          closeTo(250, 0.1));
      expect(pumpedLitresStoppedEarly(41.67, 60, maxLitres: 500), 500);
    });

    test('minutes late and overflow wasted', () {
      expect(minutesLate(840, 720), 2);
      expect(minutesLate(600, 720), 0);
      expect(overflowWastedLitres(41.67, 2), closeTo(83.3, 0.1));
      expect(overflowWastedLitres(41.67, 0), 0);
      expect(overflowMinutesAvoided(5, 2), 3);
      expect(overflowMinutesAvoided(5, 7), 0);
    });

    test('run on time matches the "~208 L and ₹0.37" example', () {
      final r = motorRunRecord(
        capacityLitres: 1000,
        fillTimeSeconds: 1440,
        startLevel: 0.5,
        minutesLate: 0,
        overflowMinutes: 5,
        motorHp: 1,
        electricityRate: 6,
      );
      expect(r.used, 500);
      expect(r.wasted, 0);
      expect(r.saved.round(), 208);
      expect(r.rupees, closeTo(0.37, 0.005));
    });

    test('late run records overflow and saves less', () {
      final r = motorRunRecord(
        capacityLitres: 1000,
        fillTimeSeconds: 1440,
        startLevel: 0,
        minutesLate: 2,
        overflowMinutes: 5,
        motorHp: 1,
        electricityRate: 6,
      );
      expect(r.used, 1000);
      expect(r.wasted, closeTo(83.33, 0.01));
      expect(r.saved, closeTo(125, 0.01)); // 3 min avoided
    });
  });

  group('Tank volume', () {
    test('cylinder π r² h × 1000', () {
      expect(cylinderLitres(1.1, 1.05), closeTo(997.8, 0.1));
      expect(cylinderLitres(2, 1), closeTo(3141.6, 0.1));
    });

    test('cuboid l × w × h × 1000', () {
      expect(cuboidLitres(2, 1.5, 1), 3000);
    });

    test('cleaning interval by material', () {
      expect(defaultCleaningIntervalDays(TankMaterial.plastic), 180);
      expect(defaultCleaningIntervalDays(TankMaterial.concrete), 90);
      expect(defaultCleaningIntervalDays(TankMaterial.stainlessSteel), 365);
    });

    test('days until cleaning', () {
      final today = DateTime(2026, 10, 10);
      expect(daysUntilCleaning(null, 180, today), isNull);
      expect(daysUntilCleaning(DateTime(2026, 10, 1), 30, today), 21);
      expect(daysUntilCleaning(DateTime(2026, 1, 1), 90, today), lessThan(0));
    });
  });

  group('Flow Timer', () {
    test('flow rate = 1 ÷ seconds; litres = rate × time', () {
      expect(fixtureFlowRateLps(8), 0.125);
      expect(litresUsed(0.125, 240), 30);
      expect(limitProgress(20, 40), 0.5);
      expect(limitProgress(10, 0), 0);
    });
  });

  group('Leaks', () {
    test('3 drips → 25 920/day → 6.48 L/day → 194.4 L/month → 19.4 buckets',
        () {
      expect(dripsPerDay(3), 25920);
      expect(dripLitresPerDay(3), closeTo(6.48, 1e-9));
      expect(dripLitresPerMonth(3), closeTo(194.4, 1e-9));
      expect(litresToBuckets(194.4), closeTo(19.44, 1e-9));
    });

    test('leak waste counts from saved day until fixed day', () {
      final leaks = [
        Leak(
            id: 'a',
            name: 'Tap',
            dripsPer10s: 3,
            litresPerDay: 6.48,
            createdAt: DateTime(2026, 10, 5, 20)),
        Leak(
            id: 'b',
            name: 'Sink',
            dripsPer10s: 2,
            litresPerDay: 4.32,
            createdAt: DateTime(2026, 10, 1),
            fixedAt: DateTime(2026, 10, 7, 9)),
      ];
      expect(leakWasteOnDay(leaks, DateTime(2026, 9, 30)), 0);
      expect(leakWasteOnDay(leaks, DateTime(2026, 10, 3)), 4.32);
      expect(leakWasteOnDay(leaks, DateTime(2026, 10, 6)),
          closeTo(10.8, 1e-9));
      expect(leakWasteOnDay(leaks, DateTime(2026, 10, 7)), 6.48);
    });

    test('night meter loss', () {
      expect(overnightLossLitres(5000, 5012, cubicMetres: false), 12);
      expect(overnightLossLitres(1234.5, 1234.512, cubicMetres: true),
          closeTo(12, 1e-6));
      expect(isLeakLikely(12), isTrue);
      expect(isLeakLikely(0), isFalse);
    });
  });

  group('Used / wasted / yearly', () {
    test('wasted % and buckets', () {
      expect(wastedPercent(30, 250), 12);
      expect(wastedPercent(10, 0), isNull);
    });

    test('average per day', () {
      expect(averagePerDay([100, 200, 300]), 200);
      expect(averagePerDay([]), 0);
    });

    test('projection = average so far × 365', () {
      expect(projectedYearTotal(30000, 100), 109500);
      expect(projectedYearTotal(100, 0), 0);
    });

    test('days counted starts at first record or 1 Jan', () {
      expect(daysCountedThisYear(DateTime(2026, 10, 1), DateTime(2026, 10, 10)),
          10);
      expect(daysCountedThisYear(DateTime(2025, 6, 1), DateTime(2026, 1, 5)),
          5);
    });

    test('total records sums every field', () {
      final t = totalRecords(const [
        DailyRecord(used: 500, wasted: 10, saved: 200, kwh: 0.06, rupees: 0.37),
        DailyRecord(used: 30, saved: 194.4),
      ]);
      expect(t.used, 530);
      expect(t.wasted, 10);
      expect(t.saved, closeTo(394.4, 1e-9));
    });
  });

  group('Required water per day', () {
    test('Indian norms by area', () {
      expect(defaultLitresPerPerson(AreaType.city), 135);
      expect(defaultLitresPerPerson(AreaType.town), 70);
      expect(defaultLitresPerPerson(AreaType.village), 55);
    });

    test('4 people × 135 L = 540 L/day', () {
      expect(requiredLitresPerDay(4, 135), 540);
    });

    test('under / near / over', () {
      expect(usageLevel(400, 540), UsageLevel.under);
      expect(usageLevel(540, 540), UsageLevel.near);
      expect(usageLevel(590, 540), UsageLevel.near);
      expect(usageLevel(600, 540), UsageLevel.over);
    });
  });

  group('Tips & challenges', () {
    test('tip is the same all day', () {
      expect(tipIndexForDate(DateTime(2026, 10, 10, 6), 61),
          tipIndexForDate(DateTime(2026, 10, 10, 23), 61));
    });

    test('no tip repeats until all are shown', () {
      for (final count in [60, 61, 74]) {
        final start = DateTime(2026, 3, 1);
        final seen = {
          for (var i = 0; i < count; i++)
            tipIndexForDate(DateTime(start.year, start.month, start.day + i),
                count)
        };
        expect(seen.length, count, reason: 'count $count');
      }
    });

    test('challenge rotates by day of year', () {
      expect(challengeIndexForDate(DateTime(2026, 1, 1), 30), 0);
      expect(challengeIndexForDate(DateTime(2026, 1, 31), 30), 0);
    });

    test('streaks and badges', () {
      final today = DateTime(2026, 10, 10);
      expect(streakAfterDone(0, null, today), 1);
      expect(streakAfterDone(4, DateTime(2026, 10, 9), today), 5);
      expect(streakAfterDone(4, DateTime(2026, 10, 10), today), 4);
      expect(streakAfterDone(4, DateTime(2026, 10, 7), today), 1);
      expect(currentStreak(5, DateTime(2026, 10, 8), today), 0);
      expect(badgesForStreak(7), [3, 7]);
    });

    test('last seven days ends today', () {
      final days = lastSevenDays(DateTime(2026, 10, 3, 15));
      expect(days.first, DateTime(2026, 9, 27));
      expect(days.last, DateTime(2026, 10, 3));
    });
  });
}
