/// A running Motor Guard session, persisted so the countdown survives the
/// app being closed and reopened.
class MotorSession {
  const MotorSession({
    required this.startTime,
    required this.level,
    required this.endTime,
    this.demoMode = false,
    this.isCalibration = false,
  });

  /// When the motor was switched on.
  final DateTime startTime;

  /// Starting water level as a fraction: 0, 0.25, 0.5 or 0.75.
  final double level;

  /// Expected time the tank becomes full.
  final DateTime endTime;

  /// Whether the session was started in demo mode (1 min = 1 s).
  final bool demoMode;

  /// True while calibrating (empty tank, end time unknown).
  final bool isCalibration;

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'level': level,
        'endTime': endTime.toIso8601String(),
        'demoMode': demoMode,
        'isCalibration': isCalibration,
      };

  factory MotorSession.fromJson(Map<String, dynamic> json) => MotorSession(
        startTime: DateTime.parse(json['startTime'] as String),
        level: (json['level'] as num).toDouble(),
        endTime: DateTime.parse(json['endTime'] as String),
        demoMode: json['demoMode'] == true,
        isCalibration: json['isCalibration'] == true,
      );
}
