import 'package:flutter/widgets.dart';

import 'app_scope.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Countdown / stopwatch style: 12:05 or 1:02:03.
String formatCountdown(double seconds) {
  final s = seconds.isFinite && seconds > 0 ? seconds.ceil() : 0;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(sec)}' : '$m:${_two(sec)}';
}

/// Time of day: 7:42 AM.
String formatClock(BuildContext context, DateTime t) {
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final suffix = context.tr(t.hour < 12 ? 'am' : 'pm');
  return '$h12:${_two(t.minute)} $suffix';
}

/// Human duration: "45 s", "3 min 20 s", "24 min", "1 h 5 min".
String formatDuration(BuildContext context, double seconds) {
  final total = seconds.isFinite && seconds > 0 ? seconds.round() : 0;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final hu = context.tr('unitHours');
  final mu = context.tr('unitMinutes');
  final su = context.tr('unitSeconds');
  if (h > 0) return m > 0 ? '$h $hu $m $mu' : '$h $hu';
  if (m == 0) return '$s $su';
  if (m < 10 && s > 0) return '$m $mu $s $su';
  return '$m $mu';
}

/// Litres: 1 decimal below 100 L, whole numbers above ("12.5", "208").
String formatLitres(double litres) =>
    litres >= 100 ? litres.round().toString() : litres.toStringAsFixed(1);

/// Fixed decimals for kWh / rupees.
String formatFixed(double v, int decimals) => v.toStringAsFixed(decimals);
