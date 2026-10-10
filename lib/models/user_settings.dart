/// Where the home is; sets the default litres per person per day.
enum AreaType { city, town, village }

/// Household setup entered during onboarding and editable in Settings.
/// (Tank size, motor HP and overflow minutes live on each TankProfile;
/// the values here are the defaults for new tanks.)
class UserSettings {
  const UserSettings({
    this.languageCode = 'en',
    this.peopleCount = defaultPeople,
    this.areaType = AreaType.city,
    this.litresPerPersonOverride,
    this.electricityRate = defaultElectricityRate,
    this.defaultMotorHp = defaultHp,
    this.defaultOverflowMinutes = defaultOverflow,
    this.demoMode = false,
    this.tipNotifications = false,
  });

  static const int defaultPeople = 4;
  static const double defaultElectricityRate = 6;
  static const double defaultHp = 1;
  static const double defaultOverflow = 5;
  static const double defaultTankCapacity = 1000;

  /// 'en' or 'ta'.
  final String languageCode;
  final int peopleCount;
  final AreaType areaType;

  /// User's own litres per person per day (null = use the area default).
  final double? litresPerPersonOverride;

  /// Electricity tariff in ₹ per unit (kWh).
  final double electricityRate;

  /// Defaults for new tanks.
  final double defaultMotorHp;
  final double defaultOverflowMinutes;

  /// When true, 1 minute = 1 second for Motor Guard timings.
  final bool demoMode;

  /// Morning "Tip of the Day" notification (off by default).
  final bool tipNotifications;

  UserSettings copyWith({
    String? languageCode,
    int? peopleCount,
    AreaType? areaType,
    double? litresPerPersonOverride,
    bool clearLitresOverride = false,
    double? electricityRate,
    double? defaultMotorHp,
    double? defaultOverflowMinutes,
    bool? demoMode,
    bool? tipNotifications,
  }) {
    return UserSettings(
      languageCode: languageCode ?? this.languageCode,
      peopleCount: peopleCount ?? this.peopleCount,
      areaType: areaType ?? this.areaType,
      litresPerPersonOverride: clearLitresOverride
          ? null
          : litresPerPersonOverride ?? this.litresPerPersonOverride,
      electricityRate: electricityRate ?? this.electricityRate,
      defaultMotorHp: defaultMotorHp ?? this.defaultMotorHp,
      defaultOverflowMinutes:
          defaultOverflowMinutes ?? this.defaultOverflowMinutes,
      demoMode: demoMode ?? this.demoMode,
      tipNotifications: tipNotifications ?? this.tipNotifications,
    );
  }

  Map<String, dynamic> toJson() => {
        'languageCode': languageCode,
        'peopleCount': peopleCount,
        'areaType': areaType.name,
        'litresPerPersonOverride': litresPerPersonOverride,
        'electricityRate': electricityRate,
        'defaultMotorHp': defaultMotorHp,
        'defaultOverflowMinutes': defaultOverflowMinutes,
        'demoMode': demoMode,
        'tipNotifications': tipNotifications,
      };

  /// Falls back to defaults for any missing or invalid (zero/negative) value,
  /// so corrupted storage can never crash the app. Also reads the keys used
  /// by older versions ('motorHp', 'overflowMinutes').
  factory UserSettings.fromJson(Map<String, dynamic> json) {
    double? positiveOrNull(Object? v) {
      final d = (v is num) ? v.toDouble() : null;
      return (d != null && d > 0 && d.isFinite) ? d : null;
    }

    double positive(Object? v, double fallback) =>
        positiveOrNull(v) ?? fallback;

    final people = json['peopleCount'];
    final area = AreaType.values
        .where((a) => a.name == json['areaType'])
        .firstOrNull;
    return UserSettings(
      languageCode: json['languageCode'] == 'ta' ? 'ta' : 'en',
      peopleCount: (people is num && people >= 1) ? people.toInt() : defaultPeople,
      areaType: area ?? AreaType.city,
      litresPerPersonOverride: positiveOrNull(json['litresPerPersonOverride']),
      electricityRate: positive(json['electricityRate'], defaultElectricityRate),
      defaultMotorHp:
          positive(json['defaultMotorHp'] ?? json['motorHp'], defaultHp),
      defaultOverflowMinutes: positive(
          json['defaultOverflowMinutes'] ?? json['overflowMinutes'],
          defaultOverflow),
      demoMode: json['demoMode'] == true,
      tipNotifications: json['tipNotifications'] == true,
    );
  }
}
