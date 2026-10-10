import 'dart:convert';

class DailySavings {
  final String date; // yyyy-MM-dd
  final double litres;
  final double kwh;
  final double rupees;

  DailySavings({
    required this.date,
    required this.litres,
    required this.kwh,
    required this.rupees,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'litres': litres,
      'kwh': kwh,
      'rupees': rupees,
    };
  }

  factory DailySavings.fromMap(Map<String, dynamic> map) {
    return DailySavings(
      date: map['date'] as String,
      litres: (map['litres'] as num).toDouble(),
      kwh: (map['kwh'] as num).toDouble(),
      rupees: (map['rupees'] as num).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory DailySavings.fromJson(String source) => DailySavings.fromMap(json.decode(source));
}
