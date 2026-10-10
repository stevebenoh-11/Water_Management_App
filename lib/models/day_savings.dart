/// Savings recorded for one calendar day (key yyyy-MM-dd in storage).
class DaySavings {
  const DaySavings({this.litres = 0, this.kwh = 0, this.rupees = 0});

  final double litres;
  final double kwh;
  final double rupees;

  DaySavings operator +(DaySavings other) => DaySavings(
        litres: litres + other.litres,
        kwh: kwh + other.kwh,
        rupees: rupees + other.rupees,
      );

  Map<String, dynamic> toJson() => {
        'litres': litres,
        'kwh': kwh,
        'rupees': rupees,
      };

  factory DaySavings.fromJson(Map<String, dynamic> json) => DaySavings(
        litres: (json['litres'] as num?)?.toDouble() ?? 0,
        kwh: (json['kwh'] as num?)?.toDouble() ?? 0,
        rupees: (json['rupees'] as num?)?.toDouble() ?? 0,
      );
}
