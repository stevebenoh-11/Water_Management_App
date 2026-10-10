/// One completed Flow Timer usage, saved to history on Stop.
class FlowRecord {
  const FlowRecord({
    required this.fixtureName,
    required this.litres,
    required this.seconds,
    required this.limitLitres,
    required this.timestamp,
  });

  final String fixtureName;
  final double litres;
  final int seconds;
  final double limitLitres;
  final DateTime timestamp;

  bool get exceededLimit => litres > limitLitres;

  Map<String, dynamic> toJson() => {
        'fixtureName': fixtureName,
        'litres': litres,
        'seconds': seconds,
        'limitLitres': limitLitres,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FlowRecord.fromJson(Map<String, dynamic> json) => FlowRecord(
        fixtureName: json['fixtureName'] as String,
        litres: (json['litres'] as num).toDouble(),
        seconds: (json['seconds'] as num).toInt(),
        limitLitres: (json['limitLitres'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
