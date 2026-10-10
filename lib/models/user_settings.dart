/// Household setup entered during onboarding and editable in Settings.
class UserSettings {
  const UserSettings({
    this.tankCapacityLitres = defaultTankCapacity,
    this.motorHp = defaultMotorHp,
    this.electricityRate = defaultElectricityRate,
    this.overflowMinutes = defaultOverflowMinutes,
    this.languageCode = 'en',
    this.demoMode = false,
  });

  static const double defaultTankCapacity = 1000;
  static const double defaultMotorHp = 1;
  static const double defaultElectricityRate = 6;
  static const double defaultOverflowMinutes = 5;

  /// Overhead tank capacity in litres.
  final double tankCapacityLitres;

  /// Motor power in horsepower.
  final double motorHp;

  /// Electricity tariff in ₹ per unit (kWh).
  final double electricityRate;

  /// Typical minutes a tank overflows before anyone notices.
  final double overflowMinutes;

  /// 'en' or 'ta'.
  final String languageCode;

  /// When true, 1 minute = 1 second for Motor Guard timings.
  final bool demoMode;

  UserSettings copyWith({
    double? tankCapacityLitres,
    double? motorHp,
    double? electricityRate,
    double? overflowMinutes,
    String? languageCode,
    bool? demoMode,
  }) {
    return UserSettings(
      tankCapacityLitres: tankCapacityLitres ?? this.tankCapacityLitres,
      motorHp: motorHp ?? this.motorHp,
      electricityRate: electricityRate ?? this.electricityRate,
      overflowMinutes: overflowMinutes ?? this.overflowMinutes,
      languageCode: languageCode ?? this.languageCode,
      demoMode: demoMode ?? this.demoMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'tankCapacityLitres': tankCapacityLitres,
        'motorHp': motorHp,
        'electricityRate': electricityRate,
        'overflowMinutes': overflowMinutes,
        'languageCode': languageCode,
        'demoMode': demoMode,
      };

  /// Falls back to defaults for any missing or invalid (zero/negative) value,
  /// so corrupted storage can never crash the app.
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    double positive(Object? v, double fallback) {
      final d = (v is num) ? v.toDouble() : null;
      return (d != null && d > 0 && d.isFinite) ? d : fallback;
    }

    final lang = json['languageCode'];
    return UserSettings(
      tankCapacityLitres:
          positive(json['tankCapacityLitres'], defaultTankCapacity),
      motorHp: positive(json['motorHp'], defaultMotorHp),
      electricityRate: positive(json['electricityRate'], defaultElectricityRate),
      overflowMinutes: positive(json['overflowMinutes'], defaultOverflowMinutes),
      languageCode: (lang == 'ta') ? 'ta' : 'en',
      demoMode: json['demoMode'] == true,
    );
  }
}
