import 'dart:convert';

class MotorSession {
  final DateTime startTime;
  final double initialLevel;
  final double durationSeconds;
  final bool isCalibrating;

  MotorSession({
    required this.startTime,
    required this.initialLevel,
    required this.durationSeconds,
    this.isCalibrating = false,
  });

  DateTime get expectedEndTime => startTime.add(Duration(seconds: durationSeconds.round()));

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.toIso8601String(),
      'initialLevel': initialLevel,
      'durationSeconds': durationSeconds,
      'isCalibrating': isCalibrating,
    };
  }

  factory MotorSession.fromMap(Map<String, dynamic> map) {
    return MotorSession(
      startTime: DateTime.parse(map['startTime']),
      initialLevel: (map['initialLevel'] as num).toDouble(),
      durationSeconds: (map['durationSeconds'] as num).toDouble(),
      isCalibrating: map['isCalibrating'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory MotorSession.fromJson(String source) => MotorSession.fromMap(json.decode(source));
}
