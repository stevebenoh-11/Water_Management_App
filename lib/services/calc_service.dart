// JalMitra formulas.
//
// Every calculation the app makes lives here as a small pure function
// (no storage, no UI, no clock), so each one can be unit-tested and
// explained to the judges line by line. Tests: test/calc_service_test.dart

import 'dart:math' as math;

import '../models/day_savings.dart';

// ===================================================================
// Constants
// ===================================================================

/// 1 horsepower = 0.746 kilowatts.
const double kwPerHp = 0.746;

/// Motor Guard alarm rings this many seconds before the tank is full.
const double alarmLeadSeconds = 120;

/// Seconds in a day ÷ 10-second drip count window = 86400 ÷ 10.
const double dripWindowsPerDay = 8640;

/// Approximate number of drips that make one litre.
const double dripsPerLitre = 4000;

/// Days used for a "month" of leak waste.
const double daysPerMonth = 30;

/// One standard household bucket holds 10 litres.
const double litresPerBucket = 10;

/// 1 cubic metre (m³) = 1000 litres.
const double litresPerCubicMetre = 1000;

/// Demo mode: 1 real minute is shown as 1 second (60× faster).
const double demoSpeedFactor = 60;

/// Streak milestones that earn a badge.
const List<int> badgeMilestones = [3, 7, 30];

// ===================================================================
// Motor Guard
// ===================================================================

/// Seconds still needed to fill the tank from the starting [level].
///
/// remainingTime = fillTime × (1 − level)
/// e.g. fillTime 1440 s (24 min), level 0.5 (half) → 720 s (12 min).
double remainingFillSeconds(double fillTimeSeconds, double level) {
  return fillTimeSeconds * (1 - level);
}

/// Seconds from now until the alarm should ring.
///
/// alarmTime = now + remainingTime − 120 s.
/// If less than 120 s remain, the alarm rings immediately (0).
double alarmDelaySeconds(double remainingSeconds,
    {double leadSeconds = alarmLeadSeconds}) {
  if (remainingSeconds < leadSeconds) return 0;
  return remainingSeconds - leadSeconds;
}

/// Converts a "real-world" duration into the duration the phone actually
/// waits. In demo mode 1 minute becomes 1 second (÷ 60).
double toDeviceSeconds(double seconds, {required bool demoMode}) {
  return demoMode ? seconds / demoSpeedFactor : seconds;
}

/// Converts what the phone actually measured back into "real-world"
/// seconds. In demo mode 1 second counts as 1 minute (× 60).
double fromDeviceSeconds(double seconds, {required bool demoMode}) {
  return demoMode ? seconds * demoSpeedFactor : seconds;
}

/// Full-tank fill time measured during a daily run.
///
/// measured = actualElapsed ÷ (1 − level)
/// e.g. started half full, took 12 min → full tank would take 24 min.
double measuredFillSeconds(double actualElapsedSeconds, double level) {
  return actualElapsedSeconds / (1 - level);
}

/// Self-learning: new fill time is the running average of all runs.
///
/// fillTime = (fillTime × fillCount + measured) ÷ (fillCount + 1)
double updatedFillSeconds(
    double fillTimeSeconds, int fillCount, double measuredSeconds) {
  return (fillTimeSeconds * fillCount + measuredSeconds) / (fillCount + 1);
}

/// A run is used for learning only if it is within 0.25× – 4× of the
/// current fill time. This ignores accidental taps on "Tank Full"
/// a few seconds after starting, which would ruin the average.
bool isPlausibleMeasurement(double measuredSeconds, double fillTimeSeconds) {
  return measuredSeconds >= fillTimeSeconds * 0.25 &&
      measuredSeconds <= fillTimeSeconds * 4;
}

/// Motor flow rate in litres per minute.
///
/// flowRate = tankCapacity ÷ (fillTime ÷ 60)
/// e.g. 1000 L in 1440 s (24 min) → 41.67 L/min.
double motorFlowRateLpm(double tankCapacityLitres, double fillTimeSeconds) {
  return tankCapacityLitres / (fillTimeSeconds / 60);
}

/// Water that would have overflowed if nobody noticed.
///
/// waterSaved = flowRate × typicalOverflowMinutes
/// e.g. 41.67 L/min × 5 min → 208.3 L.
double waterSavedLitres(double flowRateLpm, double overflowMinutes) {
  return flowRateLpm * overflowMinutes;
}

/// Electricity the motor would have wasted while overflowing.
///
/// energySaved (kWh) = HP × 0.746 × (overflowMinutes ÷ 60)
/// e.g. 1 HP, 5 min → 0.0622 kWh.
double energySavedKwh(double motorHp, double overflowMinutes) {
  return motorHp * kwPerHp * (overflowMinutes / 60);
}

/// Money saved on the electricity bill.
///
/// moneySaved = energySaved × electricityRate
/// e.g. 0.0622 kWh × ₹6 → ₹0.37.
double moneySavedRupees(double energyKwh, double ratePerUnit) {
  return energyKwh * ratePerUnit;
}

/// All three savings for one successful Motor Guard use.
DaySavings motorGuardSavings({
  required double tankCapacityLitres,
  required double fillTimeSeconds,
  required double overflowMinutes,
  required double motorHp,
  required double electricityRate,
}) {
  final flow = motorFlowRateLpm(tankCapacityLitres, fillTimeSeconds);
  final kwh = energySavedKwh(motorHp, overflowMinutes);
  return DaySavings(
    litres: waterSavedLitres(flow, overflowMinutes),
    kwh: kwh,
    rupees: moneySavedRupees(kwh, electricityRate),
  );
}

// ===================================================================
// Flow Timer
// ===================================================================

/// Fixture flow rate from the 1-litre bottle test.
///
/// flowRate (L/s) = 1 ÷ secondsToFillOneLitre
/// e.g. bottle filled in 8 s → 0.125 L/s.
double fixtureFlowRateLps(double secondsForOneLitre) {
  return 1 / secondsForOneLitre;
}

/// Live litres used so far.
///
/// litres = flowRate × elapsedSeconds
/// e.g. 0.125 L/s × 240 s → 30 L.
double litresUsed(double flowRateLps, double elapsedSeconds) {
  return flowRateLps * elapsedSeconds;
}

/// Fraction of the limit used (0.0 – 1.0+), for the progress bar.
double limitProgress(double litres, double limitLitres) {
  if (limitLitres <= 0) return 0;
  return litres / limitLitres;
}

// ===================================================================
// Leak Check – Drip Calculator
// ===================================================================

/// Drips per day from a 10-second count.
///
/// dripsPerDay = drips × 8640   (8640 ten-second windows in a day)
/// e.g. 3 drips → 25 920 drips/day.
double dripsPerDay(int dripsIn10Seconds) {
  return dripsIn10Seconds * dripWindowsPerDay;
}

/// litresPerDay = dripsPerDay ÷ 4000   (about 4000 drips = 1 litre)
/// e.g. 25 920 → 6.48 L/day.
double dripLitresPerDay(int dripsIn10Seconds) {
  return dripsPerDay(dripsIn10Seconds) / dripsPerLitre;
}

/// litresPerMonth = litresPerDay × 30
/// e.g. 6.48 → 194.4 L/month.
double dripLitresPerMonth(int dripsIn10Seconds) {
  return dripLitresPerDay(dripsIn10Seconds) * daysPerMonth;
}

/// Buckets = litres ÷ 10 (1 bucket = 10 L).
/// e.g. 194.4 L → 19.4 buckets.
double litresToBuckets(double litres) {
  return litres / litresPerBucket;
}

// ===================================================================
// Leak Check – Night Meter Test
// ===================================================================

/// Water lost overnight with all taps closed, in litres.
///
/// difference = (morning − night), × 1000 if the meter reads in m³.
/// e.g. 1234.500 m³ → 1234.512 m³ = 12 L lost.
double overnightLossLitres(
  double nightReading,
  double morningReading, {
  required bool cubicMetres,
}) {
  final diff = morningReading - nightReading;
  return cubicMetres ? diff * litresPerCubicMetre : diff;
}

/// A hidden leak is likely if any water passed the meter overnight.
bool isLeakLikely(double lossLitres) => lossLitres > 0;

// ===================================================================
// Challenges
// ===================================================================

/// Day of the year: 1 Jan = 1, 31 Dec = 365/366.
int dayOfYear(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  return d.difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
}

/// Index of today's challenge: rotates by day of year.
///
/// index = (dayOfYear − 1) mod challengeCount
int challengeIndexForDate(DateTime date, int challengeCount) {
  return (dayOfYear(date) - 1) % challengeCount;
}

/// Whole calendar days from [from] to [to] (ignores time of day).
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Streak after tapping "Done" [today].
///
/// - already done today → unchanged
/// - last done yesterday → streak + 1
/// - first time, or a day was missed → 1
int streakAfterDone(int currentStreak, DateTime? lastDone, DateTime today) {
  if (lastDone == null) return 1;
  final gap = calendarDaysBetween(lastDone, today);
  if (gap == 0) return math.max(currentStreak, 1);
  if (gap == 1) return currentStreak + 1;
  return 1;
}

/// Streak to display today: a missed day (gap of 2+ days) resets it to 0.
int currentStreak(int savedStreak, DateTime? lastDone, DateTime today) {
  if (lastDone == null) return 0;
  final gap = calendarDaysBetween(lastDone, today);
  return (gap <= 1) ? savedStreak : 0;
}

/// Badge milestones (3, 7, 30 days) reached by [streak].
List<int> badgesForStreak(int streak) {
  return badgeMilestones.where((m) => streak >= m).toList();
}

// ===================================================================
// Dashboard
// ===================================================================

/// The 7 calendar days ending today, oldest first.
List<DateTime> lastSevenDays(DateTime today) {
  final d = DateTime(today.year, today.month, today.day);
  return List.generate(7, (i) => DateTime(d.year, d.month, d.day - (6 - i)));
}

/// Sum of a list of daily savings.
DaySavings totalSavings(Iterable<DaySavings> days) {
  return days.fold(const DaySavings(), (sum, d) => sum + d);
}
