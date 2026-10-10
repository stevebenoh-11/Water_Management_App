import 'package:flutter_test/flutter_test.dart';
import 'package:jalmitra/services/calc_service.dart';

void main() {
  group('CalcService Unit Tests', () {
    test('calculateRemainingTimeSeconds correctly computes remaining time', () {
      // 1000s fill time, starting at 50% (0.5) => 500s remaining
      final remaining = CalcService.calculateRemainingTimeSeconds(
        fillTimeSeconds: 1000.0,
        initialLevel: 0.5,
        isDemoMode: false,
      );
      expect(remaining, 500.0);
    });

    test('calculateRemainingTimeSeconds handles demo mode scaling (1m = 1s)', () {
      // 1200s fill time, starting at 0% => 1200s / 60 = 20s in demo mode
      final remaining = CalcService.calculateRemainingTimeSeconds(
        fillTimeSeconds: 1200.0,
        initialLevel: 0.0,
        isDemoMode: true,
      );
      expect(remaining, 20.0);
    });

    test('updateSelfLearnedFillTime accurately updates fill time running average', () {
      // Initial fillTime = 1200s, fillCount = 1
      // User ran motor from 0.5 (half full), took 500s actual
      // Measured full time = 500 / (1 - 0.5) = 1000s
      // New average = (1200 * 1 + 1000) / 2 = 1100s
      final result = CalcService.updateSelfLearnedFillTime(
        currentFillTime: 1200.0,
        currentFillCount: 1,
        actualElapsedSeconds: 500.0,
        initialLevel: 0.5,
      );
      expect(result['fillTime'], 1100.0);
      expect(result['fillCount'], 2.0);
    });

    test('calculateWaterSavedLitres computes saved overflow litres', () {
      // 1000L tank filled in 10 minutes (600s) => flow rate = 100 L/min
      // Overflow minutes = 5 => water saved = 500L
      final waterSaved = CalcService.calculateWaterSavedLitres(
        tankCapacityLitres: 1000.0,
        fillTimeSeconds: 600.0,
        typicalOverflowMinutes: 5.0,
      );
      expect(waterSaved, 500.0);
    });

    test('calculateEnergySavedKwh computes energy saved in kWh', () {
      // 1 HP motor, 60 minutes overflow => 1 * 0.746 * 1 = 0.746 kWh
      final energySaved = CalcService.calculateEnergySavedKwh(
        motorHp: 1.0,
        typicalOverflowMinutes: 60.0,
      );
      expect(energySaved, 0.746);
    });

    test('calculateMoneySavedRupees computes monetary savings', () {
      // 2 kWh * ₹6/unit = ₹12
      final moneySaved = CalcService.calculateMoneySavedRupees(
        energySavedKwh: 2.0,
        electricityRate: 6.0,
      );
      expect(moneySaved, 12.0);
    });

    test('calculateFixtureFlowRateLps & calculateLitresUsed', () {
      // Calibration bottle filled in 10s => flow rate = 0.1 L/s
      final flowRate = CalcService.calculateFixtureFlowRateLps(10.0);
      expect(flowRate, 0.1);

      // Used shower for 300 seconds (5 mins) => 30 Litres used
      final used = CalcService.calculateLitresUsed(flowRate, 300.0);
      expect(used, 30.0);
    });

    test('calculateDripWaste computes monthly wasted water and buckets', () {
      // 5 drips in 10s
      // drips/day = 5 * 8640 = 43200
      // litres/day = 43200 / 4000 = 10.8 L/day
      // litres/month = 10.8 * 30 = 324 L/month
      // buckets/month = 324 / 10 = 32.4 buckets
      final waste = CalcService.calculateDripWaste(5);
      expect(waste['litresPerMonth'], 324.0);
      expect(waste['bucketsPerMonth'], 32.4);
    });

    test('calculateNightMeterLeak calculates overnight leaks in litres and m3', () {
      final litresLeak = CalcService.calculateNightMeterLeak(
        nightReading: 1200.0,
        morningReading: 1245.0,
        unit: 'litres',
      );
      expect(litresLeak, 45.0);

      final m3Leak = CalcService.calculateNightMeterLeak(
        nightReading: 10.5,
        morningReading: 10.7,
        unit: 'm3',
      );
      expect(m3Leak, closeTo(200.0, 0.001));
    });
  });
}
