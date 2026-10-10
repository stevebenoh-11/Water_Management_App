import 'dart:convert';

class MeterTestRecord {
  final double? nightReading;
  final DateTime? nightTime;
  final double? morningReading;
  final DateTime? morningTime;
  final String unit; // 'litres' or 'm3'

  MeterTestRecord({
    this.nightReading,
    this.nightTime,
    this.morningReading,
    this.morningTime,
    this.unit = 'litres',
  });

  Map<String, dynamic> toMap() {
    return {
      'nightReading': nightReading,
      'nightTime': nightTime?.toIso8601String(),
      'morningReading': morningReading,
      'morningTime': morningTime?.toIso8601String(),
      'unit': unit,
    };
  }

  factory MeterTestRecord.fromMap(Map<String, dynamic> map) {
    return MeterTestRecord(
      nightReading: (map['nightReading'] as num?)?.toDouble(),
      nightTime: map['nightTime'] != null ? DateTime.parse(map['nightTime']) : null,
      morningReading: (map['morningReading'] as num?)?.toDouble(),
      morningTime: map['morningTime'] != null ? DateTime.parse(map['morningTime']) : null,
      unit: map['unit'] as String? ?? 'litres',
    );
  }

  String toJson() => json.encode(toMap());

  factory MeterTestRecord.fromJson(String source) => MeterTestRecord.fromMap(json.decode(source));
}
