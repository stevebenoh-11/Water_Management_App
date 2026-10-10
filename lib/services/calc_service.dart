/// JalMitra Pure Calculation Formulas
/// All water, power, and financial calculation functions live here as pure functions for auditability and testing.
class CalcService {
  /// Calculate remaining time in seconds to fill tank from [initialLevel] (0.0 to 1.0).
  /// If [isDemoMode] is true, 1 minute is compressed into 1 second (divided by 60).
  static double calculateRemainingTimeSeconds({
    required double fillTimeSeconds,
    required double initialLevel,
    bool isDemoMode = false,
  }) {
    if (fillTimeSeconds <= 0) return 0.0;
    final double level = initialLevel.clamp(0.0, 1.0);
    final double remaining = fillTimeSeconds * (1.0 - level);
    return isDemoMode ? remaining / 60.0 : remaining;
  }

  /// Self-learning algorithm to update average full fill time.
  /// Given [actualElapsedSeconds] to reach full from [initialLevel],
  /// computes [measuredFullTime] and updates running average [fillTimeSeconds].
  static Map<String, double> updateSelfLearnedFillTime({
    required double currentFillTime,
    required int currentFillCount,
    required double actualElapsedSeconds,
    required double initialLevel,
  }) {
    if (initialLevel >= 1.0 || actualElapsedSeconds <= 0) {
      return {'fillTime': currentFillTime, 'fillCount': currentFillCount.toDouble()};
    }
    final double measuredFullTime = actualElapsedSeconds / (1.0 - initialLevel);
    final double newFillTime =
        ((currentFillTime * currentFillCount) + measuredFullTime) / (currentFillCount + 1);
    return {
      'fillTime': newFillTime,
      'fillCount': (currentFillCount + 1).toDouble(),
    };
  }

  /// Calculates flow rate of overhead motor in Litres per minute (L/min).
  static double calculateMotorFlowRateLpm({
    required double tankCapacityLitres,
    required double fillTimeSeconds,
  }) {
    if (fillTimeSeconds <= 0) return 0.0;
    return tankCapacityLitres / (fillTimeSeconds / 60.0);
  }

  /// Calculates water saved per motor run by preventing typical overflow.
  static double calculateWaterSavedLitres({
    required double tankCapacityLitres,
    required double fillTimeSeconds,
    required double typicalOverflowMinutes,
  }) {
    final double flowRate = calculateMotorFlowRateLpm(
      tankCapacityLitres: tankCapacityLitres,
      fillTimeSeconds: fillTimeSeconds,
    );
    return flowRate * typicalOverflowMinutes;
  }

  /// Calculates energy saved in kWh by preventing overflow running.
  static double calculateEnergySavedKwh({
    required double motorHp,
    required double typicalOverflowMinutes,
  }) {
    if (typicalOverflowMinutes <= 0 || motorHp <= 0) return 0.0;
    return motorHp * 0.746 * (typicalOverflowMinutes / 60.0);
  }

  /// Calculates money saved in Rupees (₹).
  static double calculateMoneySavedRupees({
    required double energySavedKwh,
    required double electricityRate,
  }) {
    if (energySavedKwh <= 0 || electricityRate <= 0) return 0.0;
    return energySavedKwh * electricityRate;
  }

  /// Calculate fixture flow rate in Litres per second (L/s) from 1-Litre bottle calibration time.
  static double calculateFixtureFlowRateLps(double calibrationSeconds) {
    if (calibrationSeconds <= 0) return 0.0;
    return 1.0 / calibrationSeconds;
  }

  /// Calculates litres used given flow rate (L/s) and elapsed time in seconds.
  static double calculateLitresUsed(double flowRateLps, double elapsedSeconds) {
    if (flowRateLps <= 0 || elapsedSeconds <= 0) return 0.0;
    return flowRateLps * elapsedSeconds;
  }

  /// Calculates monthly water waste from 10-second drip count.
  /// 10s drips -> drips/day = count * 8640. 4000 drips per Litre.
  static Map<String, double> calculateDripWaste(int dripCountIn10s) {
    if (dripCountIn10s <= 0) {
      return {'litresPerMonth': 0.0, 'bucketsPerMonth': 0.0};
    }
    final double dripsPerDay = dripCountIn10s * 8640.0;
    final double litresPerDay = dripsPerDay / 4000.0;
    final double litresPerMonth = litresPerDay * 30.0;
    final double bucketsPerMonth = litresPerMonth / 10.0; // 1 bucket = 10L
    return {
      'litresPerMonth': litresPerMonth,
      'bucketsPerMonth': bucketsPerMonth,
    };
  }

  /// Calculates night meter leak in Litres.
  static double calculateNightMeterLeak({
    required double nightReading,
    required double morningReading,
    required String unit, // 'litres' or 'm3'
  }) {
    final double diff = morningReading - nightReading;
    if (diff <= 0) return 0.0;
    return unit == 'm3' ? diff * 1000.0 : diff;
  }
}
