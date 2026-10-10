/// Unit of a water meter reading.
enum MeterUnit { litres, cubicMetres }

/// Night Meter Test: a night reading (all taps closed) and a morning reading.
class MeterTest {
  const MeterTest({
    required this.nightReading,
    required this.nightTime,
    required this.unit,
    this.morningReading,
    this.morningTime,
  });

  final double nightReading;
  final DateTime nightTime;
  final MeterUnit unit;
  final double? morningReading;
  final DateTime? morningTime;

  bool get isComplete => morningReading != null;

  MeterTest withMorning(double reading, DateTime time) => MeterTest(
        nightReading: nightReading,
        nightTime: nightTime,
        unit: unit,
        morningReading: reading,
        morningTime: time,
      );

  Map<String, dynamic> toJson() => {
        'nightReading': nightReading,
        'nightTime': nightTime.toIso8601String(),
        'unit': unit.name,
        'morningReading': morningReading,
        'morningTime': morningTime?.toIso8601String(),
      };

  factory MeterTest.fromJson(Map<String, dynamic> json) => MeterTest(
        nightReading: (json['nightReading'] as num).toDouble(),
        nightTime: DateTime.parse(json['nightTime'] as String),
        unit: json['unit'] == MeterUnit.cubicMetres.name
            ? MeterUnit.cubicMetres
            : MeterUnit.litres,
        morningReading: (json['morningReading'] as num?)?.toDouble(),
        morningTime: json['morningTime'] == null
            ? null
            : DateTime.parse(json['morningTime'] as String),
      );
}
