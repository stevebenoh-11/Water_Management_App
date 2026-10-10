// JalMitra formulas.
//
// Every calculation the app makes lives here as a small pure function
// (no storage, no UI, no clock), so each one can be unit-tested and
// explained to the judges line by line. Tests: test/calc_service_test.dart

import 'dart:math' as math;

import '../models/daily_record.dart';
import '../models/leak.dart';
import '../models/tank_profile.dart';
import '../models/user_settings.dart';

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

/// Fill times shorter than this are not a real tank fill (seconds).
const double minPlausibleRunSeconds = 30;

// ===================================================================
// Motor Guard – timing
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

// ===================================================================
// Motor Guard – self-learning
// ===================================================================

/// Full-tank fill time measured during a daily run.
///
/// measured = actualElapsed ÷ (1 − level)
/// e.g. started half full, took 12 min → full tank would take 24 min.
double measuredFillSeconds(double actualElapsedSeconds, double level) {
  return actualElapsedSeconds / (1 - level);
}

/// Self-learning: new fill time is the running average of all runs.
///
/// fillTime = (fillTime × runs + measured) ÷ (runs + 1)
double updatedFillSeconds(
    double fillTimeSeconds, int runs, double measuredSeconds) {
  return (fillTimeSeconds * runs + measuredSeconds) / (runs + 1);
}

/// A run is used for learning only if it took at least 30 s and is within
/// 0.25× – 4× of the current fill time. This ignores accidental taps on
/// "Tank Full" a few seconds after starting, which would ruin the average.
bool isPlausibleMeasurement(double measuredSeconds, double fillTimeSeconds,
    {double elapsedSeconds = double.infinity}) {
  if (elapsedSeconds < minPlausibleRunSeconds) return false;
  return measuredSeconds >= fillTimeSeconds * 0.25 &&
      measuredSeconds <= fillTimeSeconds * 4;
}

// ===================================================================
// Motor Guard – water, energy, money
// ===================================================================

/// Motor flow rate in litres per minute.
///
/// flowRate = tankCapacity ÷ (fillTime ÷ 60)
/// e.g. 1000 L in 1440 s (24 min) → 41.67 L/min.
double motorFlowRateLpm(double tankCapacityLitres, double fillTimeSeconds) {
  return tankCapacityLitres / (fillTimeSeconds / 60);
}

/// Water that would have overflowed if nobody noticed.
///
/// waterSaved = flowRate × overflowMinutes
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

/// Water pumped into the tank on a complete run (counts as "used").
///
/// pumped = capacity × (1 − startLevel)
/// e.g. 1000 L tank started half full → 500 L.
double pumpedLitres(double capacityLitres, double startLevel) {
  return capacityLitres * (1 - startLevel);
}

/// Water pumped when the motor was stopped early (Cancel).
///
/// pumped = flowRate × elapsedMinutes, never more than a full fill.
/// e.g. 41.67 L/min × 6 min → 250 L.
double pumpedLitresStoppedEarly(double flowRateLpm, double elapsedMinutes,
    {required double maxLitres}) {
  return math.min(flowRateLpm * elapsedMinutes, maxLitres);
}

/// Minutes "Tank Full" was tapped after the predicted full time (0 if on time).
double minutesLate(double elapsedSeconds, double predictedSeconds) {
  return math.max(0, elapsedSeconds - predictedSeconds) / 60;
}

/// Water that overflowed because "Tank Full" was tapped late.
///
/// overflowWasted = flowRate × minutesPastPredictedFull
/// e.g. 41.67 L/min × 2 min late → 83.3 L.
double overflowWastedLitres(double flowRateLpm, double minutesLate) {
  return flowRateLpm * math.max(0, minutesLate);
}

/// Overflow minutes actually avoided: the usual overflow time minus any
/// minutes late. e.g. usually 5 min, 2 min late → 3 min avoided.
double overflowMinutesAvoided(double overflowMinutes, double minutesLate) {
  return math.max(0, overflowMinutes - math.max(0, minutesLate));
}

/// All results of one Motor Guard run ending with "Tank Full".
DailyRecord motorRunRecord({
  required double capacityLitres,
  required double fillTimeSeconds,
  required double startLevel,
  required double minutesLate,
  required double overflowMinutes,
  required double motorHp,
  required double electricityRate,
}) {
  final flow = motorFlowRateLpm(capacityLitres, fillTimeSeconds);
  final avoided = overflowMinutesAvoided(overflowMinutes, minutesLate);
  final kwh = energySavedKwh(motorHp, avoided);
  return DailyRecord(
    used: pumpedLitres(capacityLitres, startLevel),
    wasted: overflowWastedLitres(flow, minutesLate),
    saved: waterSavedLitres(flow, avoided),
    kwh: kwh,
    rupees: moneySavedRupees(kwh, electricityRate),
  );
}

// ===================================================================
// Tank volume
// ===================================================================

/// Cylinder capacity in litres (vertical or horizontal).
///
/// V = π × r² × h × 1000, with r = diameter ÷ 2 (metres → litres).
/// For a horizontal cylinder, h is its length.
/// e.g. diameter 1.1 m, height 1.05 m → 997.8 L.
double cylinderLitres(double diameterM, double heightM) {
  final r = diameterM / 2;
  return math.pi * r * r * heightM * litresPerCubicMetre;
}

/// Rectangular (cuboid) tank capacity in litres.
///
/// V = length × width × height × 1000
/// e.g. 2 m × 1.5 m × 1 m → 3000 L.
double cuboidLitres(double lengthM, double widthM, double heightM) {
  return lengthM * widthM * heightM * litresPerCubicMetre;
}

/// Suggested cleaning interval by tank material (days).
/// Plastic ~6 months; concrete/brick ~3 months (rougher walls hold sludge);
/// stainless steel ~12 months.
int defaultCleaningIntervalDays(TankMaterial material) => switch (material) {
      TankMaterial.plastic => 180,
      TankMaterial.concrete => 90,
      TankMaterial.stainlessSteel => 365,
      TankMaterial.galvanisedIron => 180,
      TankMaterial.ferroCement => 120,
      TankMaterial.brick => 90,
      TankMaterial.other => 180,
    };

/// Days until the next cleaning (negative = overdue), or null if the last
/// cleaning date is unknown.
int? daysUntilCleaning(DateTime? lastCleaned, int intervalDays, DateTime today) {
  if (lastCleaned == null) return null;
  return intervalDays - calendarDaysBetween(lastCleaned, today);
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

/// Daily waste from leaks that were not fixed on [day].
///
/// A leak counts from the day it was saved, up to (not including) the day
/// it was fixed. e.g. two active leaks of 6.48 L and 3.24 L → 9.72 L/day.
double leakWasteOnDay(List<Leak> leaks, DateTime day) {
  var total = 0.0;
  for (final leak in leaks) {
    final started = calendarDaysBetween(leak.createdAt, day) >= 0;
    final fixed = leak.fixedAt;
    final notYetFixed = fixed == null || calendarDaysBetween(fixed, day) < 0;
    if (started && notYetFixed) total += leak.litresPerDay;
  }
  return total;
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
// Water used / wasted
// ===================================================================

/// Wasted water as a percentage of water used, or null if nothing used.
///
/// wasted% = wasted ÷ used × 100
/// e.g. 30 L wasted of 250 L used → 12%.
double? wastedPercent(double wasted, double used) {
  if (used <= 0) return null;
  return wasted / used * 100;
}

/// Average of daily values. e.g. [100, 200, 300] → 200.
double averagePerDay(List<double> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Projected total for the whole year (an estimate).
///
/// projected = (totalSoFar ÷ daysCounted) × 365
/// e.g. 30 000 L over 100 days → 109 500 L/year.
double projectedYearTotal(double totalSoFar, int daysCounted) {
  if (daysCounted <= 0) return 0;
  return totalSoFar / daysCounted * 365;
}

/// Days counted this year for the projection: from the first day with a
/// record (or 1 Jan, whichever is later) up to and including today.
int daysCountedThisYear(DateTime firstRecordDay, DateTime today) {
  final jan1 = DateTime(today.year, 1, 1);
  final start = firstRecordDay.isBefore(jan1) ? jan1 : firstRecordDay;
  return calendarDaysBetween(start, today) + 1;
}

// ===================================================================
// Average water required per day
// ===================================================================

/// Litres per person per day by area type (Indian norms):
/// - City: 135 L – CPHEEO Manual on Water Supply and Treatment (1999),
///   towns/cities with sewerage.
/// - Town: 70 L – CPHEEO, towns without sewerage.
/// - Village: 55 L – Jal Jeevan Mission rural service level.
double defaultLitresPerPerson(AreaType area) => switch (area) {
      AreaType.city => 135,
      AreaType.town => 70,
      AreaType.village => 55,
    };

/// Water the household needs per day.
///
/// required = people × litresPerPersonPerDay
/// e.g. 4 people × 135 L → 540 L/day.
double requiredLitresPerDay(int people, double litresPerPerson) {
  return people * litresPerPerson;
}

enum UsageLevel { under, near, over }

/// Compares today's use with the daily requirement:
/// under 90% → under, 90–110% → near, above 110% → over.
UsageLevel usageLevel(double usedLitres, double requiredLitres) {
  if (requiredLitres <= 0) return UsageLevel.near;
  final ratio = usedLitres / requiredLitres;
  if (ratio < 0.9) return UsageLevel.under;
  if (ratio <= 1.1) return UsageLevel.near;
  return UsageLevel.over;
}

// ===================================================================
// Tips & Challenges
// ===================================================================

/// Day of the year: 1 Jan = 1, 31 Dec = 365/366.
int dayOfYear(DateTime date) {
  final d = DateTime.utc(date.year, date.month, date.day);
  return d.difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
}

/// Whole calendar days from [from] to [to] (ignores time of day).
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// Tip of the day, without repeats until all tips have been shown.
///
/// index = (dayNumber × step + 11) mod count, where dayNumber counts days
/// since 1 Jan 2024 and step is the first number ≥ 37 that shares no factor
/// with count. Because step and count are coprime, any `count` days in a row
/// give `count` different tips (a fixed shuffle that never repeats early).
int tipIndexForDate(DateTime date, int count) {
  var step = 37;
  while (_gcd(step, count) != 1) {
    step++;
  }
  final dayNumber = calendarDaysBetween(DateTime(2024, 1, 1), date);
  return ((dayNumber * step + 11) % count + count) % count;
}

/// Index of today's challenge: rotates by day of year.
///
/// index = (dayOfYear − 1) mod challengeCount
int challengeIndexForDate(DateTime date, int challengeCount) {
  return (dayOfYear(date) - 1) % challengeCount;
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
List<DateTime> lastSevenDays(DateTime today) => lastNDays(today, 7);

/// The [n] calendar days ending today, oldest first.
List<DateTime> lastNDays(DateTime today, int n) {
  final d = DateTime(today.year, today.month, today.day);
  return List.generate(n, (i) => DateTime(d.year, d.month, d.day - (n - 1 - i)));
}

/// Sum of a list of daily records.
DailyRecord totalRecords(Iterable<DailyRecord> days) {
  return days.fold(const DailyRecord(), (sum, d) => sum + d);
}
