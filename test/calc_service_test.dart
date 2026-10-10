import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/models/day_savings.dart';
import 'package:jalmitra/services/calc_service.dart';

void main() {
  group('Motor Guard', () {
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
      expect(alarmDelaySeconds(0), 0);
    });

    test('demo mode: 1 minute = 1 second', () {
      expect(toDeviceSeconds(1440, demoMode: true), 24);
      expect(toDeviceSeconds(1440, demoMode: false), 1440);
      expect(fromDeviceSeconds(24, demoMode: true), 1440);
      expect(fromDeviceSeconds(24, demoMode: false), 24);
      // Alarm lead of 120 s becomes 2 s on the device.
      expect(toDeviceSeconds(alarmLeadSeconds, demoMode: true), 2);
    });

    test('measured fill = elapsed ÷ (1 − level)', () {
      expect(measuredFillSeconds(720, 0.5), 1440);
      expect(measuredFillSeconds(1440, 0), 1440);
      expect(measuredFillSeconds(360, 0.75), 1440);
    });

    test('self-learning running average', () {
      // Calibrated at 24 min, next run measured 26 min → 25 min.
      expect(updatedFillSeconds(1440, 1, 1560), 1500);
      // After 3 runs averaging 1500, a 1620 run → 1530.
      expect(updatedFillSeconds(1500, 3, 1620), 1530);
    });

    test('ignores implausible measurements', () {
      expect(isPlausibleMeasurement(1500, 1440), isTrue);
      expect(isPlausibleMeasurement(10, 1440), isFalse);
      expect(isPlausibleMeasurement(1440 * 5, 1440), isFalse);
    });

    test('1000 L tank, 24 min fill → ~41.7 L/min', () {
      expect(motorFlowRateLpm(1000, 24 * 60), closeTo(41.67, 0.01));
    });

    test('water saved: 41.67 L/min × 5 min → ~208 L', () {
      final flow = motorFlowRateLpm(1000, 1440);
      expect(waterSavedLitres(flow, 5), closeTo(208.33, 0.01));
    });

    test('energy saved: 1 HP × 0.746 × 5/60 → 0.0622 kWh', () {
      expect(energySavedKwh(1, 5), closeTo(0.06217, 0.00001));
      expect(energySavedKwh(1.5, 10), closeTo(0.1865, 0.0001));
    });

    test('money saved: 0.0622 kWh × ₹6 → ₹0.37', () {
      expect(moneySavedRupees(energySavedKwh(1, 5), 6), closeTo(0.373, 0.001));
    });

    test('motorGuardSavings matches the CLAUDE.md popup example', () {
      final s = motorGuardSavings(
        tankCapacityLitres: 1000,
        fillTimeSeconds: 1440,
        overflowMinutes: 5,
        motorHp: 1,
        electricityRate: 6,
      );
      expect(s.litres.round(), 208);
      expect(s.kwh, closeTo(0.0622, 0.0001));
      expect(s.rupees, closeTo(0.37, 0.005));
    });
  });

  group('Flow Timer', () {
    test('flow rate = 1 ÷ seconds for 1 L', () {
      expect(fixtureFlowRateLps(8), 0.125);
      expect(fixtureFlowRateLps(10), 0.1);
    });

    test('litres = flowRate × elapsed', () {
      expect(litresUsed(0.125, 240), 30);
      expect(litresUsed(0.1, 0), 0);
    });

    test('limit progress', () {
      expect(limitProgress(20, 40), 0.5);
      expect(limitProgress(50, 40), 1.25);
      expect(limitProgress(10, 0), 0);
    });
  });

  group('Drip Calculator', () {
    test('3 drips / 10 s → 25 920 drips/day', () {
      expect(dripsPerDay(3), 25920);
    });

    test('3 drips / 10 s → 6.48 L/day', () {
      expect(dripLitresPerDay(3), closeTo(6.48, 1e-9));
    });

    test('3 drips / 10 s → ~194 L/month', () {
      expect(dripLitresPerMonth(3), closeTo(194.4, 1e-9));
    });

    test('buckets = litres ÷ 10', () {
      expect(litresToBuckets(194.4), closeTo(19.44, 1e-9));
    });

    test('zero drips → zero waste', () {
      expect(dripLitresPerMonth(0), 0);
    });
  });

  group('Night Meter Test', () {
    test('litres meter difference', () {
      expect(overnightLossLitres(5000, 5012, cubicMetres: false), 12);
    });

    test('m³ meter difference × 1000', () {
      expect(overnightLossLitres(1234.5, 1234.512, cubicMetres: true),
          closeTo(12, 1e-6));
    });

    test('leak likely only when difference > 0', () {
      expect(isLeakLikely(12), isTrue);
      expect(isLeakLikely(0), isFalse);
    });
  });

  group('Challenges', () {
    test('day of year', () {
      expect(dayOfYear(DateTime(2026, 1, 1)), 1);
      expect(dayOfYear(DateTime(2026, 2, 1)), 32);
      expect(dayOfYear(DateTime(2026, 12, 31)), 365);
      expect(dayOfYear(DateTime(2028, 12, 31)), 366);
    });

    test('challenge rotates by day of year', () {
      expect(challengeIndexForDate(DateTime(2026, 1, 1), 30), 0);
      expect(challengeIndexForDate(DateTime(2026, 1, 30), 30), 29);
      expect(challengeIndexForDate(DateTime(2026, 1, 31), 30), 0);
    });

    test('streak after Done', () {
      final today = DateTime(2026, 10, 10, 9);
      expect(streakAfterDone(0, null, today), 1);
      expect(streakAfterDone(4, DateTime(2026, 10, 9, 22), today), 5);
      expect(streakAfterDone(4, DateTime(2026, 10, 10, 7), today), 4);
      expect(streakAfterDone(4, DateTime(2026, 10, 7), today), 1);
    });

    test('streak works across month and year boundaries', () {
      expect(streakAfterDone(2, DateTime(2026, 9, 30), DateTime(2026, 10, 1)),
          3);
      expect(streakAfterDone(9, DateTime(2026, 12, 31), DateTime(2027, 1, 1)),
          10);
    });

    test('missed day resets displayed streak', () {
      final today = DateTime(2026, 10, 10);
      expect(currentStreak(5, DateTime(2026, 10, 10), today), 5);
      expect(currentStreak(5, DateTime(2026, 10, 9), today), 5);
      expect(currentStreak(5, DateTime(2026, 10, 8), today), 0);
      expect(currentStreak(5, null, today), 0);
    });

    test('badges at 3, 7, 30 days', () {
      expect(badgesForStreak(2), isEmpty);
      expect(badgesForStreak(3), [3]);
      expect(badgesForStreak(7), [3, 7]);
      expect(badgesForStreak(45), [3, 7, 30]);
    });
  });

  group('Dashboard', () {
    test('last seven days ends today, oldest first', () {
      final days = lastSevenDays(DateTime(2026, 10, 3, 15));
      expect(days.length, 7);
      expect(days.first, DateTime(2026, 9, 27));
      expect(days.last, DateTime(2026, 10, 3));
    });

    test('total savings sums each field', () {
      final t = totalSavings(const [
        DaySavings(litres: 200, kwh: 0.06, rupees: 0.37),
        DaySavings(litres: 194.4),
      ]);
      expect(t.litres, closeTo(394.4, 1e-9));
      expect(t.kwh, 0.06);
      expect(t.rupees, 0.37);
    });
  });
}
