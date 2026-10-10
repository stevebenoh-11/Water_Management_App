/// Water and savings recorded for one calendar day (key yyyy-MM-dd).
///
/// - [used]: water pumped by Motor Guard + water measured by Flow Timer.
/// - [wasted]: tank overflow + overnight meter loss. (Daily loss from unfixed
///   leaks is added on top when shown – see calc_service.leakWasteOnDay.)
/// - [saved]: overflow avoided, leaks fixed, challenges done.
class DailyRecord {
  const DailyRecord({
    this.used = 0,
    this.wasted = 0,
    this.saved = 0,
    this.kwh = 0,
    this.rupees = 0,
  });

  final double used;
  final double wasted;
  final double saved;

  /// Electricity saved (kWh).
  final double kwh;

  /// Money saved (₹).
  final double rupees;

  bool get isEmpty =>
      used == 0 && wasted == 0 && saved == 0 && kwh == 0 && rupees == 0;

  DailyRecord operator +(DailyRecord other) => DailyRecord(
        used: used + other.used,
        wasted: wasted + other.wasted,
        saved: saved + other.saved,
        kwh: kwh + other.kwh,
        rupees: rupees + other.rupees,
      );

  DailyRecord copyWith({double? used, double? wasted, double? saved}) =>
      DailyRecord(
        used: used ?? this.used,
        wasted: wasted ?? this.wasted,
        saved: saved ?? this.saved,
        kwh: kwh,
        rupees: rupees,
      );

  Map<String, dynamic> toJson() => {
        'used': used,
        'wasted': wasted,
        'saved': saved,
        'kwh': kwh,
        'rupees': rupees,
      };

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    double n(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return DailyRecord(
      used: n('used'),
      wasted: n('wasted'),
      // Older versions stored only savings, under 'litres'.
      saved: json.containsKey('saved') ? n('saved') : n('litres'),
      kwh: n('kwh'),
      rupees: n('rupees'),
    );
  }
}
